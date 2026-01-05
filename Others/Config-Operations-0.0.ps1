######################################################################################################################
# Config Operation CLI | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 18-June-2025
#=====================================================================================================================

Clear-Host
$ThisServer = (hostname).ToLower()

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

$AvailabilityZones
#$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"
$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
    Write-host "* doesn't support anymore"
    break
}

$ServerTypeList = @('bat')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"
    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } })
}

$ServerList | Out-Host

if ($ServerList -eq $null) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

# Define copy options
$CopyOptions = @{
    1 = @{ Name = "DSLs";           LocalPath = "D:\Backup\DBBSetup";            RemotePath = "D:\DBBSetup\DSLs" }
    2 = @{ Name = "BatchScripts";   LocalPath = "C:\LocalDeploy\BatchScripts";   RemotePath = "D:\DBBSetup\BatchScripts" }
    3 = @{ Name = "CC_Python";      LocalPath = "C:\LocalDeploy\CC_Python";      RemotePath = "D:\CC_Python" }
    4 = @{ Name = "PlatformCode";   LocalPath = "C:\LocalDeploy\PlatformCode";   RemotePath = "D:\CC_runtime" }
    5 = @{ Name = "WCFServer";      LocalPath = "C:\LocalDeploy\WCFServer";      RemotePath = "D:\WebServer" }
    6 = @{ Name = "WebServer";      LocalPath = "C:\LocalDeploy\WebServer";      RemotePath = "D:\WebServer" }
    7 = @{ Name = "KMS";            LocalPath = "C:\LocalDeploy\KMS";            RemotePath = "D:\KMS\KMM" }
}

Write-Host "Select the Copy condition:"
$CopyOptions.Keys | Sort-Object | ForEach-Object {
    Write-Host "$_ - Copy $($CopyOptions[$_].Name)"
}
$ConditionSelected = Read-Host "Enter your choice (1-7)"

if (-not $CopyOptions.ContainsKey([int]$ConditionSelected)) {
    Write-Host "Invalid selection. Exiting..."
    exit
}

$Selection = $CopyOptions[[int]$ConditionSelected]
$LocalSource = $Selection.LocalPath
$RemoteDest = $Selection.RemotePath

if (-not (Test-Path $LocalSource)) {
    Write-Host "Local source path not found: $LocalSource"
    exit
}

$ResultList = @()
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

foreach ($Server in $ServerList) {
    try {
        Write-Host "Copying to $Server..." -ForegroundColor Cyan
        $session = New-PSSession -ComputerName $Server -SessionOption $option -ErrorAction Stop

        Invoke-Command -Session $session -ScriptBlock {
            param($dest)
            if (!(Test-Path $dest)) {
                New-Item -ItemType Directory -Path $dest -Force
            }
        } -ArgumentList $RemoteDest

        Copy-Item -Path "$LocalSource\*" -Destination $RemoteDest -ToSession $session -Recurse -Force -ErrorAction Stop

        Remove-PSSession $session

        $ResultList += [PSCustomObject]@{
            ServerName = $Server
            Status     = "Files copy successfully"
        }
    } catch {
        $ResultList += [PSCustomObject]@{
            ServerName = $Server
            Status     = "Error: $($_.Exception.Message)"
        }
    }
}

# Generate HTML Report
$HtmlReport = @"
<html>
<head>
    <style>
        body { font-family: Arial; }
        table { border-collapse: collapse; width: 80%; margin: 20px auto; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .Copied { color: green; font-weight: bold; }
        .Error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h2 style='text-align:center;'>File Copy Report</h2>
    <table>
        <tr>
            <th>Server Name</th>
            <th>Status</th>
        </tr>
"@

foreach ($entry in $ResultList) {
    $statusClass = if ($entry.Status -eq "Files copy successfully") { "Copied" } else { "Error" }
    $HtmlReport += "<tr><td>$($entry.ServerName)</td><td class='$statusClass'>$($entry.Status)</td></tr>`n"
}



$HtmlReport += @"
    </table>
</body>
</html>
"@

$ReportPath = "C:\Temp\FileCopyReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$HtmlReport | Out-File -FilePath $ReportPath -Encoding UTF8
Write-Host "`nHTML Report generated at: $ReportPath"
Start-Process $ReportPath
