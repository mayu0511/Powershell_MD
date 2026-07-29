######################################################################################################################
# PlatforCode RundbbEXE Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Enhanced with separated steps | Date:: 11-March-2026
#======================================================================================================================

Clear-Host
$ThisServer = (Hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName

$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon

$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack

$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZone = $NULL
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$AvailabilityZone

$ServerTypeList = @('bat' , 'svc')
$ServerType = $Null
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

#Read-Host "Press enter to see the Server List"
if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    Break Script
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

# Report paths
$logFolder = "C:\Temp"

if (!(Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory | Out-Null
}

$date = Get-Date -Format "yyyyMMdd_HHmmss"

$logFile = "$logFolder\Platcoderunddbbexe_$date.log"
$htmlFile = "$logFolder\Platcoderunddbbexe_$date.html"

# Run check on servers
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

$result = Invoke-Command -ComputerName $ServerList -SessionOption $option -ScriptBlock {

    $path = "D:\CC_runtime"

    try {
        $files = Get-ChildItem $path -Filter "rundbb*.exe" -File -ErrorAction Stop
        $names = $files.Name
        $count = $files.Count
    }
    catch {
        $names = @()
        $count = "Error"
    }

    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        Count  = $count
        Files  = $names
    }

}

# Reference server
$reference = $result | Select-Object -First 1
$refFiles = $reference.Files

foreach ($r in $result) {

    if ($r.Count -eq $reference.Count) {

        $status = "Matched"
        $diff = ""

    }
    else {

        $status = "Mismatched"

        $missing = $refFiles | Where-Object { $_ -notin $r.Files }
        $extra   = $r.Files | Where-Object { $_ -notin $refFiles }

        $diff = "Missing: $($missing -join ', ') <br> Extra: $($extra -join ', ')"
    }

    $r | Add-Member Status $status -Force
    $r | Add-Member Difference $diff -Force

    "$($r.Server) - $($r.Count) - $status - $diff" | Out-File $logFile -Append
}

# Build HTML report
$html = @"
<html>
<head>
<style>
table {border-collapse: collapse;font-family: Arial;}
th,td {border:1px solid black;padding:8px;text-align:center;}
.match {background-color:#90EE90;}
.mismatch {background-color:#FFA500;}
</style>
</head>
<body>
<h2>RunDBB EXE Validation Report - $date</h2>
<table>
<tr>
<th>Server</th>
<th>Count</th>
<th>Status</th>
<th>Difference</th>
</tr>
"@

foreach ($r in $result) {

if ($r.Status -eq "Matched") { $class = "match" }
else { $class = "mismatch" }

$html += "<tr>
<td>$($r.Server)</td>
<td>$($r.Count)</td>
<td class='$class'>$($r.Status)</td>
<td>$($r.Difference)</td>
</tr>"
}

$html += "</table></body></html>"

$html | Out-File $htmlFile

Start-Process $htmlFile

Write-Host ""
Write-Host "Report Created:" $htmlFile
Write-Host "Log File:" $logFile