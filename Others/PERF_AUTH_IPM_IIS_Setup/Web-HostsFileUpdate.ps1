######################################################################################################################
# Web Server: Auth and IPM Setup- Get IP of WCF Sever and Hosts File Update  | DEVELOPED BY:: Netra Chettri
# Version 1.0 | Date:: 11-MAY-2026
#=====================================================================================================================
Clear-Host
$ThisServer = (Hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName

$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon

if ($Environmentattributon -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2"
    Write-Host "2. COOKIE - POD3 (POD4)"
    
    $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
    
    if ($PODNumberSelected -eq "1") {
        $PODName = "pod2"
    } elseif ($PODNumberSelected -eq "2") {
        $PODName = "pod4"
    } else {
        $PODName = $NULL
        Write-Host "Invalid POD Name. Exiting..."
        break
    }

    $PODName = "pod2"

} elseif ($Environmentattributon -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attributon. Exiting..."
}

$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack

$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"
$AvailabilityZone

#$ServerTypeList = @('bat' , 'wcf')
$ServerTypeList = @('web')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) |
    Select-Object @{
        n = "Name"; e = { $_.Name }
    }, @{
        n = "AvailabilityZone"; e = { $_.AvailabilityZone }
    }, @{
        n = "serial"; e = { 
            if ($_.Name -match "$EnvironmentName$EnvironmentStack") {
                [double](($_.Name -split "$EnvironmentName$EnvironmentStack")[1])
            } else { 0 }
        }
    } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if (-not $ServerList) {
    Write-Host "No Server in the given criteria... Please try again"
    break
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

#################################################################
# Step-1 Host File Update
#################################################################

if ($EnvironmentStack -match '^b') {

    $CertName  = "authipm-blue.api.cc-pod2.infra.marcus.com"
    $ServerName = "CCWCFE1PERFB1"

} elseif ($EnvironmentStack -match '^g') {

    $CertName  = "authipm-green.api.cc-pod2.infra.marcus.com"
    $ServerName = "CCWCFE1PERFG1"

} else {

    Write-Host "Unknown Stack : $EnvironmentStack" -ForegroundColor Red
    break
}

Write-Host "Selected Stack       : $EnvironmentStack" -ForegroundColor Cyan
Write-Host "Selected Cert Name   : $CertName" -ForegroundColor Green
Write-Host "Selected Server Name : $ServerName" -ForegroundColor Green

# Get IPv4 Address of Remote Server
$IPAddress = (
    [System.Net.Dns]::GetHostAddresses($ServerName) |
    Where-Object { $_.AddressFamily -eq 'InterNetwork' }
).IPAddressToString

Write-Host ""
Write-Host "Detected IP Address of $ServerName : $IPAddress" -ForegroundColor Green

# Hosts File Path
$HostsFile = "C:\Windows\System32\drivers\etc\hosts"

# Entry to Add
$Entry = "$IPAddress`t$CertName"

# Add Entry
if (-not (Select-String -Path $HostsFile -Pattern $CertName -Quiet)) {

    Add-Content -Path $HostsFile -Value $Entry

    Write-Host "Entry added to local hosts file:" -ForegroundColor Green
    Write-Host $Entry -ForegroundColor Yellow

} else {

    Write-Host "Entry already exists in local hosts file." -ForegroundColor Yellow
}

#################################################################
# Step-2 Update Hosts File on Remote Servers
#################################################################

foreach ($Server in $ServerList) {

    try {

        Write-Host ""
        Write-Host "Updating hosts file on $Server ..." -ForegroundColor Cyan

        $RemoteHostsFile = "\\$Server\C$\Windows\System32\drivers\etc\hosts"

        # Check if entry already exists
        if (-not (Select-String -Path $RemoteHostsFile -Pattern $CertName -Quiet)) {

            Add-Content -Path $RemoteHostsFile -Value $Entry

            Write-Host "Hosts entry added successfully on $Server" -ForegroundColor Green

        } else {

            Write-Host "Entry already exists on $Server" -ForegroundColor Yellow
        }

    } catch {

        Write-Host "Failed on ${Server}: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Script execution completed." -ForegroundColor Green
#################################################################
# Step-3 HTML Report Generation
#################################################################

$result = @()

foreach ($Server in $ServerList) {

    $RemoteHostsFile = "\\$Server\C$\Windows\System32\drivers\etc\hosts"

    try {

        if (Select-String -Path $RemoteHostsFile -Pattern $CertName -Quiet) {

            $Status = "Updated"

        } else {

            $Status = "Failed"
        }

    } catch {

        $Status = "Unreachable"
    }

    $result += [PSCustomObject]@{
        Server     = $Server
        Status     = $Status
        Certificate = $CertName
        IPAddress  = $IPAddress
    }
}

# Date
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Report Paths
$htmlFile = "C:\Temp\HostsFileUpdateReport.html"
$logFile  = "C:\Temp\HostsFileUpdateReport.log"

# HTML Header
$html = @"
<html>
<head>
<title>Hosts File Update Report</title>
<style>
body {
    font-family: Arial;
}

table {
    border-collapse: collapse;
    width: 100%;
}

th, td {
    border: 1px solid black;
    padding: 8px;
    text-align: center;
}

th {
    background-color: #D3D3D3;
}

.success {
    background-color: #90EE90;
}

.failed {
    background-color: #FFA500;
}

.unreachable {
    background-color: #FF7F7F;
}
</style>
</head>

<body>

<h2>Hosts File Update Report - $date</h2>

<table>

<tr>
<th>Server Name</th>
<th>Status</th>
<th>Certificate Name</th>
<th>IP Address of WCF Server</th>
</tr>
"@

# Table Rows
foreach ($r in $result) {

    switch ($r.Status) {

        "Updated"     { $class = "success" }
        "Failed"      { $class = "failed" }
        "Unreachable" { $class = "unreachable" }
        default       { $class = "" }
    }

    $html += @"
<tr>
<td>$($r.Server)</td>
<td class='$class'>$($r.Status)</td>
<td>$($r.Certificate)</td>
<td>$($r.IPAddress)</td>
</tr>
"@
}

# HTML Footer
$html += @"
</table>
</body>
</html>
"@

# Save HTML
$html | Out-File $htmlFile -Encoding UTF8

# Optional Log File
$result | Out-File $logFile

# Open Report
Start-Process $htmlFile

Write-Host ""
Write-Host "HTML Report Created :" -ForegroundColor Green
Write-Host $htmlFile -ForegroundColor Yellow

Write-Host ""
Write-Host "Log File Created :" -ForegroundColor Green
Write-Host $logFile -ForegroundColor Yellow
