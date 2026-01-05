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
 
 $ServerTypeList = 'web'
 $ServerType = $Null
 $ServerList = $Null
ForEach($ServerType in $ServerTypeList) {
 Write-Host "ServerType - $ServerType"
 
$ServerList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } },@{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } |Sort-Object -Property serial)
 }

$ServerList | Out-Host
 
#Read-Host "Press enter to see the Server List"
if ($ServerList -eq $NULL) {
Write-Host "No Server in the the gven criteria... Please try again"
Break Script
}
 
$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"
 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
#$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach($computername in $ServerList)
#ForEach($ServerType in $ServerTypeList)
{

Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {

$FolderName = "D:\Temp1\"
if (Test-Path $FolderName) {
 
    Write-Host "Folder Exists"
    Remove-Item $FolderName -Force -recurse
}
else
{
    Write-Host "Folder Doesn't Exists"
}
mkdir D:\Temp1\
Select-String -Path C:\inetpub\logs\LogFiles\W3SVC2\u_ex220920_x.log -Pattern "- 200" >D:\Temp1\$env:computername.txt
Read-Host -Prompt "Press Any Ket To Continue"
aws s3 cp D:\Temp1\$env:computername.txt s3://corecard-pod2-patuat-us-east-1-config-files/Copy/Temp/$env:computername.txt

}
}
aws s3 cp s3://corecard-pod2-patuat-us-east-1-config-files/Copy/Temp/ D:\TempLog\ --recursive
aws s3 rm s3://corecard-pod2-patuat-us-east-1-config-files/Copy/Temp/ --recursive
 