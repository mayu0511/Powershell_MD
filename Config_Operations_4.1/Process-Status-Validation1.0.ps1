Clear-Host
$Module = "Processes-Status"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = (hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value,Pod:Tags[?Key=='pod']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]

if (($AWSVarialbes.Pod) -eq $NULL) {
    if ($Environmentattributon -eq "jazz") {
        $Environmentpod = $Environmentattributon
    } else {
        $S3bucketslist = aws s3 ls
        if ($S3bucketslist -match "corecard-pod2-$EnvironmentName-$Region-config-files") { $Environmentpod = "pod2" }
        elseif ($S3bucketslist -match "corecard-pod4-$EnvironmentName-$Region-config-files") { $Environmentpod = "pod4" }
        elseif ($S3bucketslist -match "corecard-pod5-$EnvironmentName-$Region-config-files") { $Environmentpod = "pod5" }
        elseif (($S3bucketslist -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($Environmentattributon -eq "jazz")) { $Environmentpod = "jazz" }
    }
} else {
    $Environmentpod = $AWSVarialbes.Pod.ToLower()
}

$Result = @()
foreach ($ServerType in $ServerTypes) {
    $ResultServerType = @()

    $ServerList = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    $ResultServerType += Invoke-Command -ComputerName $($ServerList.name) -SessionOption $option -ErrorAction SilentlyContinue -ScriptBlock {
        param ($ServerList)

        $ServerAZ = ($ServerList | Where-Object { ($_.Name).ToLower() -eq "$env:computername".ToLower() }).AvailabilityZone
        $resultvalue = @()
        $scheduledtasknames = (Get-Scheduledtask -TaskName Task_* -ErrorAction SilentlyContinue).TaskName
        $ProcessesNames = (Get-Process -Name 'DbbAppServer*', 'Rundbb*' -ErrorAction SilentlyContinue).ProcessName

        if ($scheduledtasknames.count -eq $ProcessesNames.count) {
            $ServerTasksVsProcessesCount = "Matching"
        } else {
            $ServerTasksVsProcessesCount = "Mismatch"
        }

        if ($scheduledtasknames -eq $NULL) {
            $resultvalue += [PSCustomObject]@{
                ServerName = "$($env:computername)"
                ProcessName = "No Tasks"
                TaskUser = "No Tasks"
                ProcessStatus = "No Tasks"
                ProcessCount = "Mismatch"
                ProcessUser = "Mismatch"
                ServerTasksVsProcessesCount = $ServerTasksVsProcessesCount
                AvailabilityZone = $ServerAZ
                IntentMode = ""
            }
        }

        foreach ($scheduledtaskname in $scheduledtasknames) {
            $HealthPort = $NULL
            $ProcessStatus = $NULL
            $HealthWebcall = $NULL
            $HealthyContent = $NULL
            $TaskDetails = Get-Scheduledtask -TaskName $scheduledtaskname
            $TaskUser = $TaskDetails.Principal.UserID

            if ($scheduledtaskname -match "Task_DbbAppServer") {
                $FindProcessName = $scheduledtaskname.Replace("Task_", "")
            } else {
                $FindProcessName = $scheduledtaskname.Replace("Task_", "Rundbb_")
            }

            $ProcessDetails = Get-Process -Name $FindProcessName -IncludeUserName -ErrorAction SilentlyContinue
            $ProcessCount = if ($ProcessDetails.Name.Count -eq 1) { "Matching" } else { "Mismatch" }
            $ProcessUser = if ($ProcessDetails.UserName -eq $TaskUser) { "Matching" } else { "Mismatch" }

            $IntentMode = (Select-String -Path D:\DBBSetup\BatchScripts\CoreIssue\RTM.config -Pattern "RunTimeMode=" -ErrorAction SilentlyContinue).ToString().Split('=')[1].Trim()

            try {
                $HealthPort = $TaskDetails.Actions.Arguments.Split(' ')[1]
                if ([string]::IsNullOrWhiteSpace($HealthPort)) {
                    $ProcessStatus = "HEALTH PORT NOT FOUND"
                }
            } catch {
                $ProcessStatus = "HEALTH PORT NOT FOUND"
            }

            if ($ProcessStatus -ne "HEALTH PORT NOT FOUND") {
                try {
                    $hostname = $env:COMPUTERNAME
                    $url = "http://$($hostname):$HealthPort/healthy"

                    $testConn = Test-NetConnection -ComputerName $hostname -Port $HealthPort -WarningAction SilentlyContinue
                    if (-not $testConn.TcpTestSucceeded) {
                        $ProcessStatus = "PROCESS DOWN"
                    } else {
                        $HealthWebcall = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                        if ($HealthWebcall.StatusCode -eq 200 -and ($HealthWebcall.RawContent -match "Healthy")) {
                            $ProcessStatus = "Process Healthy"
                        } else {
                            $ProcessStatus = "Process Unhealthy"
                        }
                    }
                } catch {
                    $ProcessStatus = "PROCESS DOWN"
                }
            }

            $resultvalue += [PSCustomObject]@{
                ServerName = "$($env:computername)"
                ProcessName = "$scheduledtaskname"
                TaskUser = "$TaskUser"
                ProcessStatus = "$ProcessStatus"
                ProcessCount = "$ProcessCount"
                ProcessUser = "$ProcessUser"
                ServerTasksVsProcessesCount = "$ServerTasksVsProcessesCount"
                AvailabilityZone = "$ServerAZ"
                IntentMode = "$IntentMode"
            }
        }

        return $resultvalue
    } -ArgumentList $ServerList

    $Result += $ResultServerType | Sort-Object -Property @{Expression = {($_.ServerName -replace '\d', '') }}, {[int]($_.ServerName -replace '\D+', '')}
}

# HTML Report Formatting
$upgUsername = "<td>$env:USERDOMAIN\gmsa-app-upg$</td>"
$upgUsernameColor = "<td bgcolor='lightsalmon'>$env:USERDOMAIN\gmsa-app-upg$</td>"
$IntentMode = "<td>ZDT</td>"
$IntentModeColor = "<td bgcolor='lightsalmon'>ZDT</td>"

$ProcessesReport = $Result | Select-Object ServerName, ProcessName, TaskUser, ProcessStatus, ProcessCount, ProcessUser, ServerTasksVsProcessesCount, AvailabilityZone, IntentMode | ConvertTo-Html -Title "Processes Status Validation Report"

$BodyHeader = "<h2 style='color: steelblue;'>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</h2>"
$Outputreport = $ProcessesReport.Replace("<body>", "<body>$BodyHeader").Replace("<table>", "<Table border=1 cellpadding=0 cellspacing=0>").Replace("<td>PROCESS DOWN</td>", "<td bgcolor=LightSalmon>PROCESS DOWN</td>").Replace("<td>PROCESS DOWN</td>", "<td bgcolor=LightSalmon>PROCESS DOWN</td>").Replace("<td>HEALTH PORT NOT FOUND</td>", "<td bgcolor=LightSalmon>HEALTH PORT NOT FOUND</td>").Replace("<td>No Tasks</td>", "<td bgcolor=LightSalmon>No Tasks</td>").Replace("<th>", '<th bgcolor=gray>').Replace($upgUsername, $upgUsernameColor).Replace("<td>Mismatch</td>", "<td bgcolor=LightSalmon>Mismatch</td>").Replace($IntentMode, $IntentModeColor).Replace("<td>Process Unhealthy</td>", "<td bgcolor=LightSalmon>Process Unhealthy</td>")

$ReportFileNamePrefix = "${Module}_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | Out-File "$ReportFile"

# Upload to S3
aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

# Open report in ISE
if ($host.Name -eq "Windows PowerShell ISE Host") {
    Invoke-Item $ReportFile
}

# Cleanup
Clear-Variable Module
Clear-Variable ServerType
Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable Environmentpod
Clear-Variable result
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
