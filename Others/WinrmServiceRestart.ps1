######################################################################################################################
# Winrm Service Restart  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 | Fixed Folder Copy Issue | Date:: 23-April-2025
#=====================================================================================================================

Clear-Host

$ThisServer = (hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
} else {
    Write-Host "Unable to determine region from hostname. Exiting..." -ForegroundColor Red
    exit
}

$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

if ($EnvironmentAttribution -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2"
    Write-Host "2. COOKIE - POD3 (POD4)"
    
    $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
    
    if ($PODNumberSelected -eq "1") {
        $PODName = "pod2"
    } elseif ($PODNumberSelected -eq "2") {
        $PODName = "pod4"
    } else {
        Write-Host "Invalid POD Name. Exiting..."
        exit
    }
} elseif ($EnvironmentAttribution -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attribution. Exiting..."
    exit
}

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"

$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$ServerTypeList = @('bat', 'svc')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"
    
    $Servers = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" `
        --filters "Name=instance-state-name,Values=running" `
                  "Name=tag:Name,Values=*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*" `
                  "Name=availability-zone,Values=$AvailabilityZone" `
        --region $Region | ConvertFrom-Json

    $ServerList += $Servers | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }
}

$ServerList | Out-Host

if (-not $ServerList) {
    Write-Host "No servers found matching the criteria. Exiting..." -ForegroundColor Red
    exit
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$ResultList = @()

foreach ($server in $ServerList) {
    Write-Host "`nRestarting WinRM on $server..." -ForegroundColor Cyan
    try {
        
        Invoke-Command -ComputerName $server -SessionOption $option -ScriptBlock {
            Restart-Service -Name WinRM -Force -Verbose
        } -ErrorAction Stop

        $ResultList += [PSCustomObject]@{
            ServerName = $server
            Status     = 'Restarted'
        }

        Write-Host "WinRM restarted successfully on $server" -ForegroundColor Green
    } catch {
        $ResultList += [PSCustomObject]@{
            ServerName = $server
            Status     = 'Error'
        }

        Write-Host "Failed to restart WinRM on $server" -ForegroundColor Red
    }
}

$HtmlReport = @"
<html>
<head>
    <style>
        body { font-family: Arial; }
        table { border-collapse: collapse; width: 80%; margin: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .Restarted { color: green; font-weight: bold; }
        .Error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h2>WinRM Restart Report</h2>
    <table>
        <tr><th>Server Name</th><th>Status</th></tr>
"@

foreach ($entry in $ResultList) {
    $statusClass = $entry.Status -replace '\s+', ''
    $HtmlReport += "<tr><td>$($entry.ServerName)</td><td class='$statusClass'>$($entry.Status)</td></tr>`n"
}

$HtmlReport += @"
    </table>
</body>
</html>
"@

$ReportPath = "C:\temp\WinRM_Restart_Report.html"
if (-not (Test-Path "C:\temp")) { New-Item -Path "C:\temp" -ItemType Directory | Out-Null }

$HtmlReport | Out-File -FilePath $ReportPath -Encoding UTF8
Write-Host "`nHTML Report generated at: $ReportPath"
Start-Process $ReportPath
