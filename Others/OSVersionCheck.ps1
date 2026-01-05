######################################################################################################################
# OS Version Check | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.1 | Revised | Date:: 31-Jan-2025
#=====================================================================================================================

Clear-Host
$Module = "OS Version Check"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = (Hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

# Fetch AWS instance details
$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value,Pod:Tags[?Key=='pod']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()
$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]

# Determine the POD name
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

$AllResults = @()
$ServerTypeCounts = @{}

foreach ($ServerType in $ServerTypes) {
    Write-Host "Server Type: $ServerType" -ForegroundColor DarkYellow

    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value, Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json

    $ServerTypeCounts[$ServerType] = $ServerList.Count
    $Option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

    foreach ($Server in $ServerList) {
        $ServerName = $Server.Name
        Write-Host "Checking Server: $ServerName" -ForegroundColor Magenta
        try {
            $CommandResult = Invoke-Command -ComputerName $ServerName -SessionOption $Option -ErrorAction Stop -ScriptBlock {
                $OS = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
                $Architecture = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }

                [PSCustomObject]@{
                    ServerName   = $env:COMPUTERNAME
                    OSName       = $OS.ProductName
                    Version      = "$($OS.DisplayVersion) (Build $($OS.CurrentBuild))"
                    Architecture = $Architecture
                }
            }

            $AllResults += $CommandResult

        } catch {
            Write-Host "Failed to retrieve details for $ServerName" -ForegroundColor Red
        }
    }
}

# Generate HTML report
$HtmlFile = "C:\Temp\OSVersionCheck.html"
$HtmlContent = @"
<html>
<head>
    <title>OS Version Check</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid black; padding: 10px; text-align: left; }
        th { background-color: #f2f2f2; }
        .server-name { color: blue; font-weight: bold; }
    </style>
</head>
<body>
    <h2>OS Version Check</h2>
    <table>
        <tr>
            <th>Server Name</th>
            <th>OS Name</th>
            <th>Version</th>
            <th>Architecture</th>
        </tr>
"@

foreach ($entry in $AllResults) {
    $HtmlContent += "<tr>"
    $HtmlContent += "<td class='server-name'>$($entry.ServerName)</td>"
    $HtmlContent += "<td>$($entry.OSName)</td>"
    $HtmlContent += "<td>$($entry.Version)</td>"
    $HtmlContent += "<td>$($entry.Architecture)</td>"
    $HtmlContent += "</tr>"
}

$HtmlContent += "</table></body></html>"

# Save and open the report
$HtmlContent | Out-File $HtmlFile -Encoding utf8
Start-Process $HtmlFile
