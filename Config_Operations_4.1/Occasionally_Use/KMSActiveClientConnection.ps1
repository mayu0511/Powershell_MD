######################################################################################################################
# KMS Active Connection | DEVELOPED BY:: Mahendra Dwivedi
# # Version 1.3 |  KMS Active Connection | Date:: 18-Sep-2025
#=====================================================================================================================

Clear-Host
$ThisServer = (Hostname).ToLower()
if ($ThisServer -match 'e1') {Clear-Host
$ThisServer = (Hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
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
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$ServerTypeList = @('kms')
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { double[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"
}

# ---- Collect Logs ----
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
          
$results = @()

foreach ($computername in $ServerList) {
    $activeConnections = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
        $folderPath = "D:\CoreCard\KMS\Service\Data"
        $today = (Get-Date).ToString("yyyy-MM-dd")

        # First try to get today's file by name
        $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace$today*.txt" |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -ExpandProperty FullName -First 1

        # Fallback to most recent file if today's not found
        if (-not $latestFile) {
            $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace*.txt" |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -ExpandProperty FullName -First 1
        }

        if (-not $latestFile) { return @() }

        $logLines = Get-Content -Path $latestFile -Tail 150

        $connections = foreach ($line in $logLines) {
            if ($line -match "^(?<timestamp>\S+\s+\S+).*INFO Connection received from (?<ip>\d+\.\d+\.\d+\.\d+)") {
                [PSCustomObject]@{ Timestamp = [datetime]$matches['timestamp']; IP = $matches['ip'] }
            }
        }

        $disconnections = foreach ($line in $logLines) {
            if ($line -match "disconnected (?<ip>\d+\.\d+\.\d+\.\d+)") { $matches['ip'] }
        }

        $connections | Where-Object { $disconnections -notcontains $_.IP }
    }

    foreach ($conn in $activeConnections) {
        try { $hostName = ([System.Net.Dns]::GetHostEntry($conn.IP)).HostName }
        catch { $hostName = $conn.IP }

        $results += [PSCustomObject]@{
            "Server Name"     = $computername
            "Host Name"       = $hostName
            "IP"              = $conn.IP
            "User ID"         = "gmsa-app-svc$"
            "Connection Date" = $conn.Timestamp.ToString("MM/dd/yyyy HH:mm:ss")
        }
    }
}

$results = $results | Sort-Object "Server Name", "Connection Date"

# --- Build HTML Report ---
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
if (-not $results) {
    $htmlRows = "<tr><td colspan='6' style='text-align:center;color:red;'>No Active Connections Found</td></tr>"
} else {
    $htmlRows = foreach ($row in $results) {
        "<tr style='background-color:#e8f8e8;'>
            <td>$($row.'Server Name')</td>
            <td>$($row.'Host Name')</td>
            <td>$($row.IP)</td>
            <td><b>$($row.'User ID')</b></td>
            <td>$($row.'Connection Date')</td>
            <td><input type='checkbox'> Disconnect</td>
        </tr>"
    }
}

$htmlContent = @"
<html>
<head>
<title>Active Client Connections</title>
<style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 100%; margin-top: 10px; }
th, td { border: 1px solid black; padding: 5px; text-align: left; font-size: 13px; }
th { background-color: #f2f2f2; }
tr:nth-child(even) { background-color: #f9f9f9; }
</style>
</head>
<body>
<h2>Snapshot of Client Connections</h2>
<table>
<tr><th>Server Name</th><th>Host Name</th><th>IP</th><th>User ID</th><th>Connection Date</th><th>Disconnect?</th></tr>
$htmlRows
</table>
<p>Generated at $timestamp</p>
</body>
</html>
"@

$outputFile = "C:\temp\ActiveClientConnections_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$htmlContent | Out-File -FilePath $outputFile -Encoding UTF8
Start-Process $outputFile
