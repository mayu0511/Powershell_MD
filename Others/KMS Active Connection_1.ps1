######################################################################################################################
# KMS Active Connection | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.1 | HTML Reporting + AWS Dynamic Server Discovery
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
    try {
        $logLines = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            $folderPath = "D:\CoreCard\KMS\Service\Data"
            $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace*.txt" |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First 1
            if ($latestFile) {
                Get-Content -Path $latestFile.FullName -Tail 200 |
                    #Where-Object { $_ -match "INFO Connection received from" }
                    Where-Object { $_ -match "INFO Connection received from|Authenticated" }
            }
            else {
                "NO_LOG_FILE_FOUND"
            }
        }

        if ($logLines.Count -eq 0 -or $logLines -contains "NO_LOG_FILE_FOUND") {
            $results += [PSCustomObject]@{
                "Server Name"   = $computername
                "Status Output" = "NO_CONNECTION_FOUND"
                "StatusClass"   = "error"
            }
        } else {
            foreach ($line in $logLines) {
                $results += [PSCustomObject]@{
                    "Server Name"   = $computername
                    "Status Output" = $line
                    "StatusClass"   = "ok"
                }
            }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            "Server Name"   = $computername
            "Status Output" = "UNREACHABLE"
            "StatusClass"   = "error"
        }
    }
}

# ---- Build HTML Report ----
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$htmlPath = "C:\temp\kmsactiveconnection-$timestamp.html"

$htmlHeader = @"
<html>
<head>
<title>KMS Active Connections</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
th { background-color: #333; color: white; }
tr.ok { background-color: #e6ffe6; }
tr.error { background-color: #ffe6e6; }
</style>
</head>
<body>
<h2>KMS Active Connection Report - $timestamp</h2>
<table>
<tr><th>Server Name</th><th>Status Output</th></tr>
"@

$htmlRows = foreach ($row in $results) {
    "<tr class='$($row.StatusClass)'><td>$($row.'Server Name')</td><td>$($row.'Status Output')</td></tr>"
}

$htmlFooter = @"
</table>
</body>
</html>
"@

$htmlContent = $htmlHeader + ($htmlRows -join "`n") + $htmlFooter
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8

Start-Process $htmlPath
