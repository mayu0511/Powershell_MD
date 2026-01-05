Clear-Host

$DATE = Get-date -Format MM-dd-yyyy-HH-mm-ss

start-transcript -path D:\Temp\TestPath$DATE.log


$ServerTypes = 'web'

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

$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]

$EnvironmentStack

$ServerList = $NULL

 

$path =$null

 

 

ForEach($ServerType in $ServerTypes) {

$ServerType

 

    $ServerListDetails = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

    $ServerList += ($ServerListDetails | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial).Name

 

 }

 

 

 $ServerList

 
 

ForEach($computername in $ServerList)

{

 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Continue -HideComputerName -ScriptBlock{

 

$report = hostname

 
$report += Get-Content -Path D:\WebServer\ScaleService\Log\scaleservice.log | select -Last 10 | Select-String -Pattern "All_Sinks_Down"
#$report += Select-String -Path D:\WebServer\ScaleService\Log\scaleservice.log -Pattern "All_Sinks_Down"
 

Write-output "********************************************************************************************************************************************"

$report

}

}


Stop-transcript