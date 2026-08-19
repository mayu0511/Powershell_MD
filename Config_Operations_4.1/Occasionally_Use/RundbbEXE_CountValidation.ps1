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
        Break Script
    }
    
    $PODName = "pod2"
} elseif ($Environmentattributon -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attributon. Exiting..."
    #Break Script
}

$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack

$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZone = $NULL
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$AvailabilityZone

$ServerTypeList = @('svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat')
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

# Run command on servers
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

$result = Invoke-Command -ComputerName $ServerList -SessionOption $option -ScriptBlock {

    $path = "D:\CC_runtime"

    try {
        $files = Get-ChildItem $path -Filter "rundbb*.exe" -File -ErrorAction Stop
        $count = $files.Count
    }
    catch {
        $count = "Error"
    }

    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        Count  = $count
    }

}

# Compare counts
$refCount = ($result | Select-Object -First 1).Count

foreach ($r in $result) {

    if ($r.Count -eq $refCount) {
        $status = "Matched"
    }
    else {
        $status = "Mismatched"
    }

    $r | Add-Member -Name Status -Value $status -MemberType NoteProperty

    "$($r.Server) - $($r.Count) - $status" | Out-File $logFile -Append
}

# Create HTML report
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
<th>Server Name</th>
<th>RunDBB Count</th>
<th>Status</th>
</tr>
"@

foreach ($r in $result) {

if ($r.Status -eq "Matched") { $class = "match" }
else { $class = "mismatch" }

$html += "<tr><td>$($r.Server)</td><td>$($r.Count)</td><td class='$class'>$($r.Status)</td></tr>"

}

$html += "</table></body></html>"

$html | Out-File $htmlFile

# Open report
Start-Process $htmlFile

Write-Host "Report created:"
Write-Host $htmlFile
Write-Host "Log file:"
Write-Host $logFile