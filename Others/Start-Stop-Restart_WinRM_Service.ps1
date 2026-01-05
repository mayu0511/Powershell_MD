######################################################################################################################
# Start-Stop-Restart WinRM Service | DEVELOPED BY:: Netra Chettri
# Version 1.2 | HTML Report Added | Date:: 28-Nov-2025
#=====================================================================================================================

Clear-Host

# Detect Region
$ThisServer = (Hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

# Fetch AWS Details
$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

# POD Selection
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

# Availability Zones
$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZones
$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"

if ($AvailabilityZone -contains "*") {
    Write-host "* doesn't support anymore"
    Break
}

# Server List Fetch
$ServerTypeList = @('bat')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | 
    Select-Object @{n = "Name"; e = { $_.Name } })
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

# ============================
#  WINRM ACTION SELECTION
# ============================
Write-Host "`nSelect WinRM Operation:" -ForegroundColor Cyan
Write-Host "1. Start WinRM"
Write-Host "2. Stop WinRM"
Write-Host "3. Restart WinRM"

$WinRMAction = Read-Host "Enter choice (1/2/3)"

switch ($WinRMAction) {
    "1" { $ActionName = "Start"; $PowerShellAction = { Start-Service -Name WinRM -ErrorAction Stop } }
    "2" { $ActionName = "Stop"; $PowerShellAction = { Stop-Service -Name WinRM -Force -ErrorAction Stop } }
    "3" { $ActionName = "Restart"; $PowerShellAction = { Restart-Service -Name WinRM -Force -ErrorAction Stop } }
    default { Write-Host "Invalid option. Exiting..."; exit }
}

# ============================
#  EXECUTE ACTION + LOG OUTPUT
# ============================
$LogData = @()

try {
    $BeforeStatus = (Get-Service -Name WinRM).Status

    & $PowerShellAction   # execute action

    $AfterStatus = (Get-Service -Name WinRM).Status

    $LogData += [PSCustomObject]@{
        Action        = $ActionName
        BeforeStatus  = $BeforeStatus
        AfterStatus   = $AfterStatus
        Result        = "Success"
        TimeStamp     = (Get-Date)
    }

    Write-Host "WinRM $ActionName Completed Successfully!" -ForegroundColor Green
}
catch {
    $LogData += [PSCustomObject]@{
        Action        = $ActionName
        BeforeStatus  = $BeforeStatus
        AfterStatus   = "Failed"
        Result        = "Error: $($_.Exception.Message)"
        TimeStamp     = (Get-Date)
    }

    Write-Host "WinRM action failed: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================
#  GENERATE HTML REPORT
# ============================
$HTMLPath = "C:\Temp\WinRM-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"

$HTMLContent = @"
<html>
<head>
<title>WinRM Service Report</title>
<style>
body { font-family: Arial; background:#f4f4f4; padding:20px; }
table { border-collapse: collapse; width:100%; background:white; }
th, td { padding:10px; border:1px solid #ccc; text-align:left; }
th { background:#333; color:white; }
.success { background:#d4edda; }
.error { background:#f8d7da; }
</style>
</head>
<body>
<h2>WinRM Service Operation Report</h2>
<p><b>Executed On:</b> $ThisServer<br>
<b>Region:</b> $Region<br>
<b>Action:</b> $ActionName<br>
<b>Generated:</b> $(Get-Date)</p>

<table>
<tr>
<th>Action</th>
<th>Before Status</th>
<th>After Status</th>
<th>Result</th>
<th>Timestamp</th>
</tr>
"@

foreach ($row in $LogData) {

    $class = if ($row.Result -eq "Success") { "success" } else { "error" }

    $HTMLContent += @"
<tr class='$class'>
<td>$($row.Action)</td>
<td>$($row.BeforeStatus)</td>
<td>$($row.AfterStatus)</td>
<td>$($row.Result)</td>
<td>$($row.TimeStamp)</td>
</tr>
"@
}

$HTMLContent += "</table></body></html>"

$HTMLContent | Out-File -FilePath $HTMLPath -Encoding UTF8

# ============================
#  AUTO OPEN REPORT
# ============================
Start-Process $HTMLPath
Write-Host "HTML report generated at: $HTMLPath" -ForegroundColor Cyan
