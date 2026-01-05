######################################################################################################################
# Unblock Files | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 |  Unblock Files | Date:: 19-July-2025
#=====================================================================================================================

Clear-Host
$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
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
 
if ($PODNumberSelected -eq "1") {$PODName = "pod2"}
elseif ($PODNumberSelected -eq "2") {$PODName = "pod4"}
else{$PODName = NULL
Write-Host "Invalid POD Name. Exiting..." 
Break Script
}
 
$PODName = "pod2"} elseif($Environmentattributon -eq "jazz") {$PODName = "jazz"} else{Write-Host "Invalid Environment Attributon. Exiting..." 
#Break Script
}
 
$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack
 
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZone = $NULL
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone)  | Get-Unique
 
$AvailabilityZones
 
$AvailabilityZone =  Read-Host "Type Availability Zones your choice  $AvailabilityZones or * for all zones "
 
$AvailabilityZone
 
 $ServerTypeList = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
 $ServerType = $Null
 $ServerList = $Null
ForEach($ServerType in $ServerTypeList) {
 Write-Host "serverType - $ServerType"



 
$ServerList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } },@{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } |Sort-Object -Property serial)

 }

$ServerList | Out-Host

if (-not $ServerList -or $ServerList.Count -eq 0) {
    Write-Host "`n? No servers found with the given criteria... Please try again" -ForegroundColor Red
    exit
}

Read-Host "Please verify the server list and press enter to continue or close to exit"

# Extract only server names
$ServerNames = $ServerList | Select-Object -ExpandProperty Name

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

foreach ($computername in $ServerNames) {
    Write-Host "`n?? Processing: $computername" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $computername -SessionOption $option -ScriptBlock {
            try {
                Get-ChildItem -Path "D:\" -Recurse -File -ErrorAction Stop | Unblock-File
                Write-Host "? Files unblocked on $env:COMPUTERNAME" -ForegroundColor Green
            } catch {
                Write-Host "? Failed to unblock files on $env:COMPUTERNAME - $_" -ForegroundColor Red
            }
        } -ErrorAction Stop
    } catch {
        Write-Host "? Connection failed for $computername - $_" -ForegroundColor Red
    }
}

