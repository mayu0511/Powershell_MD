######################################################################################################################
# Process Status Validation  | DEVELOPED BY::Aaksh Sharma
# Version 2.0 | Date:: 12-Aug-2025 | Update By Netra
# Version 3.5 | Date:: 07-April-2026 | Updated By Mahendrta Dwivedi

#======================================================================================================================

Clear-Host

$Module = "Processes-Status"
$ServerTypes = 'SVC', 'ISS', 'AUT', 'SRC', 'SNK', 'TNP', 'AWF', 'BAT'
$ThisServer = (hostname).ToLower()

# Region detection
if ($ThisServer -match 'e1') { $Region = "us-east-1" }
elseif ($ThisServer -match 'w2') { $Region = "us-west-2" }

Write-Host "Running on Server: $ThisServer | Region: $Region" -ForegroundColor Cyan

# Get AWS metadata for current server
$AWSVarialbes = (aws ec2 describe-instances `
--query "Reservations[*].Instances[*].{
    AvailabilityZone:Placement.AvailabilityZone,
    Name:Tags[?Key=='Name']|[0].Value,
    Environment:Tags[?Key=='environment']|[0].Value,
    Stack:Tags[?Key=='stack']|[0].Value,
    Attribution:Tags[?Key=='attribution']|[0].Value,
    Pod:Tags[?Key=='pod']|[0].Value
}" `
--filters "Name=instance-state-name,Values=running" `
"Name=tag:Name,Values=$ThisServer" `
--region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$Environmentattributon = $AWSVarialbes.Attribution.ToLower()

# POD detection
if ($null -eq $AWSVarialbes.Pod) {
    if ($Environmentattributon -eq "jazz") {
        $Environmentpod = "jazz"
    } else {
        $S3bucketslist = aws s3 ls
        if ($S3bucketslist -match "corecard-pod2-$EnvironmentName-$Region-config-files") { $Environmentpod = "pod2" }
        elseif ($S3bucketslist -match "corecard-pod4-$EnvironmentName-$Region-config-files") { $Environmentpod = "pod4" }
        elseif ($S3bucketslist -match "corecard-pod5-$EnvironmentName-$Region-config-files") { $Environmentpod = "pod5" }
    }
} else {
    $Environmentpod = $AWSVarialbes.Pod.ToLower()
}

# Get all servers
$ServerList = (aws ec2 describe-instances `
--query "Reservations[*].Instances[*].{
    AvailabilityZone:Placement.AvailabilityZone,
    Name:Tags[?Key=='Name']|[0].Value,
    Stack:Tags[?Key=='stack']|[0].Value
}" `
--filters "Name=instance-state-name,Values=running" `
--region $Region | ConvertFrom-Json)

# Filter stack
$ServerList = $ServerList | Where-Object {
    $_.Stack -like "*$($AWSVarialbes.Stack)*"
}

# ? Build AZ Mapping
$ServerMap = @{}
foreach ($srv in $ServerList) {
    if ($srv.Name) {
        $ServerMap[$srv.Name.ToLower()] = $srv.AvailabilityZone
    }
}

Write-Host "Total Servers Mapped: $($ServerMap.Count)" -ForegroundColor Yellow

$Result = @()

foreach ($ServerType in $ServerTypes) {

    Write-Host "`nProcessing ServerType: $ServerType" -ForegroundColor Cyan

    $FilteredServers = $ServerList | Where-Object {
        $_.Name -like "*$ServerType*"
    }

    $ComputerList = $FilteredServers.Name | Where-Object { $_ }

    if (-not $ComputerList) {
        Write-Host "No servers found for $ServerType" -ForegroundColor Red
        continue
    }

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    $Result += Invoke-Command -ComputerName $ComputerList `
    -SessionOption $option `
    -ErrorAction SilentlyContinue `
    -ArgumentList ($ServerMap) `
    -ScriptBlock {

        param ($ServerMap)

        $hostname = $env:COMPUTERNAME.ToLower()
        $ServerAZ = $ServerMap[$hostname]

        # ?? Fallback using LIKE
        if (-not $ServerAZ) {
            foreach ($key in $ServerMap.Keys) {
                if ($key -like "*$hostname*") {
                    $ServerAZ = $ServerMap[$key]
                    break
                }
            }
        }

        # ?? Debug if still not found
        if (-not $ServerAZ) {
            Write-Output "DEBUG: AZ NOT FOUND for $hostname"
            $ServerAZ = "UNKNOWN"
        }

        $resultvalue = @()

        $scheduledtasknames = (Get-Scheduledtask -TaskName Task_* -ErrorAction SilentlyContinue).TaskName
        $ProcessesNames = (Get-Process -Name 'DbbAppServer*', 'Rundbb*' -ErrorAction SilentlyContinue).ProcessName

        $ServerTasksVsProcessesCount = if ($scheduledtasknames.count -eq $ProcessesNames.count) { "Matching" } else { "Mismatch" }

        if ($null -eq $scheduledtasknames) {
            $resultvalue += [PSCustomObject]@{
            ServerType = $using:ServerType   # ? ADD THIS
            ServerName = $hostname
            ProcessName = "No Tasks"
            ProcessId = "NA"
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

            $TaskDetails = Get-Scheduledtask -TaskName $scheduledtaskname
            $TaskUser = $TaskDetails.Principal.UserID

            if ($scheduledtaskname -match "Task_DbbAppServer") {
                $FindProcessName = $scheduledtaskname.Replace("Task_", "")
            } else {
                $FindProcessName = $scheduledtaskname.Replace("Task_", "Rundbb_")
            }

            $ProcessDetails = Get-Process -Name $FindProcessName -IncludeUserName -ErrorAction SilentlyContinue

            $ProcessId = if ($ProcessDetails) { ($ProcessDetails | Select-Object -First 1 -ExpandProperty Id) } else { "N/A" }

            $ProcessCount = if ($ProcessDetails.Name.Count -eq 1) { "Matching" } else { "Mismatch" }

            $procUser = ($ProcessDetails.UserName -split '\\')[-1]
            $taskUser = ($TaskUser -split '\\')[-1]

            $ProcessUser = if ($procUser -and $taskUser -and ($procUser.ToLower() -eq $taskUser.ToLower())) {
                "Matching"
            } else {
                "Mismatch"
            }

            $IntentRaw = Select-String -Path "D:\DBBSetup\BatchScripts\CoreIssue\RTM.config" -Pattern "RunTimeMode=" -ErrorAction SilentlyContinue

if ($IntentRaw) {
    $IntentMode = $IntentRaw.ToString().Split('=')[1].Trim()
} else {
    $IntentMode = ""
}
# Extract Port from Arguments (FIX)
$HealthPort = $null
$taskArgs = $TaskDetails.Actions.Arguments

# Debug (optional - remove later)
# Write-Output "DEBUG: Args=$taskArgs"

if ($taskArgs) {
    # Case 1: --server.port=8080 OR port=8080
    if ($taskArgs -match 'port[=\s](\d{3,5})') {
        $HealthPort = $matches[1]
    }
    # Case 2: standalone port like 8080
    elseif ($taskArgs -match '\b(\d{3,5})\b') {
        $HealthPort = $matches[1]
    }
}


if (-not $HealthPort) {
    $ProcessStatus = "Health Port Not Found"
}
else {
    $url = "http://localhost:$HealthPort/healthy"

    try {
        $resp = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing

        if ($resp.StatusCode -eq 200) {

            # Flexible check (important fix)
            if ($resp.Content -match "Healthy|UP|OK") {
                $ProcessStatus = "Process Healthy"
            }
            else {
                $ProcessStatus = "Process Healthy"
            }

        } else {
            $ProcessStatus = "Process Unhealthy"
        }

    } catch {
        $ProcessStatus = "Process Down"
    }
}

$resultvalue += [PSCustomObject]@{
    ServerType = $using:ServerType   # ? ADD THIS
    ServerName = $hostname
    ProcessName = $scheduledtaskname
    ProcessId = $ProcessId
    TaskUser = $TaskUser
    ProcessStatus = $ProcessStatus
    ProcessCount = $ProcessCount
    ProcessUser = $ProcessUser
    ServerTasksVsProcessesCount = $ServerTasksVsProcessesCount
    AvailabilityZone = $ServerAZ
    IntentMode = $IntentMode
            }
        }

        return $resultvalue
    }
}

# =========================
# AFTER RESULT COLLECTION
# =========================

# HTML Report Formatting
$upgUsername = "<td>$($env:USERDOMAIN)\gmsa-app-upg`$</td>"
$upgUsernameColor = "<td bgcolor='lightsalmon'>$($env:USERDOMAIN)\gmsa-app-upg`$</td>"
$IntentMode = "<td>ZDT</td>"

#$ProcessesReport = $Result | Select-Object ServerName, ProcessName, ProcessId, TaskUser, ProcessStatus, ProcessCount, ProcessUser, ServerTasksVsProcessesCount, AvailabilityZone, IntentMode | ConvertTo-Html -Title "Processes Status Validation Report"
# Build ServerType Order
$ServerTypeOrder = @{}
for ($i = 0; $i -lt $ServerTypes.Count; $i++) {
    $ServerTypeOrder[$ServerTypes[$i]] = $i
}

# Sort properly
$SortedResult = $Result | Sort-Object `
    @{Expression = { $ServerTypeOrder[$_.ServerType] }}, `
    @{Expression = { $_.ServerName -replace '\d','' }}, `
    @{Expression = { [int]($_.ServerName -replace '\D','') }}

#$ProcessesReport = $SortedResult | Select-Object ServerName, ProcessName, ProcessId, TaskUser, ProcessStatus, ProcessCount, ProcessUser, ServerTasksVsProcessesCount, AvailabilityZone, IntentMode | ConvertTo-Html -Title "Processes Status Validation Report"
$ProcessesReport = $SortedResult | Select-Object `
ServerType, ServerName, ProcessName, ProcessId, TaskUser, ProcessStatus, `
ProcessCount, ProcessUser, ServerTasksVsProcessesCount, AvailabilityZone, IntentMode `
| ConvertTo-Html -Title "Processes Status Validation Report"

# Apply formatting
$Outputreport = $ProcessesReport

# Highlight gmsa user
$Outputreport = $Outputreport -replace '(<td>.*?gmsa-app-upg\$</td>)', '<td bgcolor="LightSalmon">$1</td>'

# Highlight ZDT
$Outputreport = $Outputreport -replace '<td>ZDT</td>', '<td bgcolor="LightSalmon">ZDT</td>'

# Header
$BodyHeader = "<h2 style='color: steelblue;'>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $($Module) Validation Report</h2>"
$Outputreport = $Outputreport.Replace("<body>", "<body>$BodyHeader")

# Table styling
$Outputreport = $Outputreport.Replace("<table>", "<Table border=1 cellpadding=0 cellspacing=0>")
$Outputreport = $Outputreport.Replace("<th>", '<th bgcolor=gray>')

# Conditional colors
$Outputreport = $Outputreport.Replace("<td>Process Down</td>", "<td bgcolor=LightSalmon>Process Down</td>")
$Outputreport = $Outputreport.Replace("<td>Health Port Not Found</td>", "<td bgcolor=LightSalmon>Health Port Not Found</td>")
$Outputreport = $Outputreport.Replace("<td>No Tasks</td>", "<td bgcolor=LightSalmon>No Tasks</td>")
$Outputreport = $Outputreport.Replace("<td>Mismatch</td>", "<td bgcolor=LightSalmon>Mismatch</td>")
$Outputreport = $Outputreport.Replace("<td>Process Unhealthy</td>", "<td bgcolor=LightSalmon>Process Unhealthy</td>")

# Specific user highlight
$Outputreport = $Outputreport.Replace($upgUsername, $upgUsernameColor)

# File creation
$ReportFileNamePrefix = "${Module}_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | Out-File "$ReportFile"

# Upload to S3
aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

# Open in ISE
if ($host.Name -eq "Windows PowerShell ISE Host") {
    Invoke-Item $ReportFile
}

# Cleanup
Clear-Variable Module
Clear-Variable ServerType
Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable Environmentpod
Clear-Variable result
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile