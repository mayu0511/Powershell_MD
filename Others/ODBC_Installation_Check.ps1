######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================
Clear-Host

$Module = "Processes-Status"
$ServerTypes = 'rpd', 'bat'
#$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = (Hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value,Pod:Tags[?Key=='pod']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

$EnvironmentName = $AWSVariables[0].Environment.ToLower()
$EnvironmentAttribution = $AWSVariables[0].Attribution.ToLower()
$EnvironmentStack = ($AWSVariables[0].Stack.ToLower())[0]

if ($AWSVariables[0].Pod -eq $null) {
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
    $EnvironmentPod = $AWSVariables[0].Pod.ToLower()
}

$EnvironmentPod

$Result = @()

ForEach ($ServerType in $ServerTypes) {
    Write-Host -ForegroundColor DarkYellow $ServerType
   
    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

    ForEach ($server in $ServerList) {
        
        $odbcDriverKey = "HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
        $driverNames = @(
            "ODBC Driver 17 for SQL Server",
            "ODBC Driver 13 For SQL Server",
            "SQL Server Native Client 11.0"
        )

        $statusMessage = ""

        foreach ($driverName in $driverNames) {
            $driverInstalled = (Get-ItemProperty -Path $odbcDriverKey -ErrorAction SilentlyContinue | Get-Member -Name $driverName)

            if ($driverInstalled) {
                $statusMessage += "$driverName is installed. "
            } else {
                $statusMessage += "$driverName is not installed. "
            }
        }

        $Result += [PSCustomObject]@{
            'Server Name' = $server.Name
            'Status'      = $statusMessage.Trim()
        }
    }
}

$Result | ConvertTo-Html -Property 'Server Name', 'Status' -Title 'ODBC Installation Status' | Out-File "C:\ODBCInstalation.html"

Start-Process "C:\ODBCInstalation.html"
