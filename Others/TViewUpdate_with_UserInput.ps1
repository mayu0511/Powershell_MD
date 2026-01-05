######################################################################################################################
# TView Update with User Input  | DEVELOPED BY:: Netra Chettri
# Version 1.1 | HTML Report Added | Date:: 26-Nov-2025
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
#$ServerTypeList = @('svc','iss','aut','awf','tnp','bat')
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

# Prepare HTML Report File
$ReportFolder = "C:\TView-Reports"
if (!(Test-Path $ReportFolder)) { New-Item -ItemType Directory -Path $ReportFolder -Force }

$TimeStamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$ReportFile = "$ReportFolder\TView_Report_$TimeStamp.html"

$HTMLHeader = @"
<html>
<head>
<title>TView Update Execution Report</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #999; padding: 8px; text-align: left; }
th { background-color: #222; color: white; }
.success { background-color: #c8f7c5; }
.error { background-color: #f7c5c5; }
</style>
</head>
<body>
<h2>TView Update Execution Report</h2>
<p><b>Generated On:</b> $(Get-Date)</p>
<table>
<tr>
<th>Server Name</th>
<th>TView Tag Name</th>
<th>Value</th>
<th>Status</th>
</tr>
"@

$HTMLFooter = @"
</table>
</body>
</html>
"@

$HTMLBody = ""



$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

# User choice for DT Execution
Write-Host "`nDo you want to execute 'dt.exe' on all selected servers?"
Write-Host "1. Yes"
Write-Host "2. No"
$ExecuteChoice = Read-Host "Enter your choice (1 or 2)"

if ($ExecuteChoice -eq "1") {

    # dt.exe requires 3 parameters (-s TRACE VALUE)
    $DtOperation = Read-Host "Enter operation (example: -s(SET) or -p(PRINT))"
    $DtTraceName = Read-Host "Enter Trace Name / OID"
    
    if ($DtOperation -eq "-s") {
        $DtTraceValue = Read-Host "Enter Value (example: 0 or 1)"
    } else {
        $DtTraceValue = $null
    }

    Write-Host "`nExecution started on remote servers...`n"

    foreach ($computername in $ServerList) { 
        Write-Host "---------------------------------------------"
        Write-Host "Connecting to: $computername"
        Write-Host "---------------------------------------------"

        try {
    $Output = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock { 
        param($Op, $Trace, $Val)

        if ($Val -ne $null) {
            & "D:\CC_Runtime\dt.exe" $Op $Trace $Val
        } else {
            & "D:\CC_Runtime\dt.exe" $Op $Trace
        }
    } -ArgumentList $DtOperation, $DtTraceName, $DtTraceValue

    # Extract value from dt.exe output
    $ValueField = ($Output | Select-String -Pattern "\b\d+\b" | Select-Object -First 1).Matches.Value
if (-not $ValueField) { $ValueField = "N/A" }

    $HTMLBody += "<tr class='success'>
    <td>$computername</td>
    <td>$DtTraceName</td>
    <td>$ValueField</td>
    <td>Success</td>
    </tr>"
}
catch {
    $Err = $_.Exception.Message.Replace("<","[").Replace(">","]")
    $HTMLBody += "<tr class='error'>
    <td>$computername</td>
    <td>$DtTraceName</td>
    <td>N/A</td>
    <td>Error: $Err</td>
    </tr>"
}
        }
    }

 else {
    Write-Host "Execution skipped as per user choice."
}

# Write HTML Report
$FullHTML = $HTMLHeader + $HTMLBody + $HTMLFooter
Set-Content -Path $ReportFile -Value $FullHTML -Encoding UTF8

Write-Host "`nHTML Report generated at:"
Write-Host $ReportFile -ForegroundColor Yellow

# Auto-open Report
Start-Process $ReportFile

# -------------------------------
# ALSO SAVE REPORT TO C:\Temp
# -------------------------------

$TempReport = "C:\Temp\TViewUpdate.html"

# Ensure folder exists
if (!(Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" -Force }

# Save identical HTML to C:\Temp
Set-Content -Path $TempReport -Value $FullHTML -Encoding UTF8

# Open the HTML report from C:\Temp
Start-Process $TempReport

