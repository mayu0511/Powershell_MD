Clear-Host
$Module = "Processes-Status"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = (Hostname).ToLower()
$OutputFile = "C:\ODBCTest.txt"

"--- Process Status Results ---" | Out-File -FilePath $OutputFile

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value,Pod:Tags[?Key=='pod']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()
$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]

if ($AWSVariables.Pod -eq $null) {
    if ($EnvironmentAttribution -eq "jazz") {
        $EnvironmentPod = $EnvironmentAttribution
    } else {
        $S3BucketsList = aws s3 ls
        if ($S3BucketsList -match "corecard-pod2-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod2"
        } elseif ($S3BucketsList -match "corecard-pod4-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod4"
        } elseif ($S3BucketsList -match "corecard-pod5-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod5"
        } elseif (($S3BucketsList -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($EnvironmentAttribution -eq "jazz")) {
            $EnvironmentPod = "jazz"
        }
    }
} else {
    $EnvironmentPod = $AWSVariables.Pod.ToLower()
}

"Environment Pod: $EnvironmentPod" | Out-File -FilePath $OutputFile -Append

$AllResults = @()
$ServerTypeCounts = @{}

foreach ($ServerType in $ServerTypes) {
    Write-Host -ForegroundColor DarkYellow $ServerType
    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json
    $ServerTypeCounts[$ServerType] = $ServerList.Count

    $Option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

    foreach ($Server in $ServerList) {
        $ServerName = $Server.Name
        try {
            $CommandResult = Invoke-Command -ComputerName $ServerName -SessionOption $Option -ErrorAction Stop -ScriptBlock {
                $DBBCDrive = Get-OdbcDriver
                $ODBCDSN = Get-OdbcDsn
                $DBBCDriveCheck = $null

                if ($DBBCDrive -ne $null) {
                    $DBBCDriveCheck = "ODBC Installed"
                }

                if (($DBBCDriveCheck -eq "ODBC Installed") -and
                    ($ODBCDSN.Name -contains "LISTPLAT" -or $ODBCDSN.Name -contains "LISTRPT") -and
                    ($ODBCDSN.Platform -eq "32-bit") -and
                    ($ODBCDSN.DriverName -eq "ODBC Driver 17 for SQL Server") -and
                    ($ODBCDSN.Attribute.MultiSubnetFailover -eq "Yes")) {
                    "PASSED"
                } else {
                    "ODBC not installed or not configured"
                }
            }

            $AllResults += [PSCustomObject]@{
                'Server Type' = $ServerType
                'Server Name' = $ServerName
                'Status'      = $CommandResult
            }
        } catch {
            $AllResults += [PSCustomObject]@{
                'Server Type' = $ServerType
                'Server Name' = $ServerName
                'Status'      = "Connection Failed: $($_.Exception.Message)"
            }
        }
    }
}

$AllResults | Format-Table -AutoSize | Out-String | ForEach-Object { $_ | Out-File -FilePath $OutputFile -Append }

Write-Host "\nSummary of Server Counts:\n" -ForegroundColor Cyan
foreach ($Type in $ServerTypeCounts.Keys) {
    $SummaryLine = "Server Type: $Type, Total Servers: $($ServerTypeCounts[$Type])"
    Write-Host $SummaryLine -ForegroundColor Green
    $SummaryLine | Out-File -FilePath $OutputFile -Append
}
