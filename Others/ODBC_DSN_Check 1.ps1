Clear-Host
$Module = "Processes-Status"
$ServerTypes = 'bat'#, 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
$ShortRegion = 'w2'
}


$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution,Pod:Tags[?Key=='pod']|[0].Value,Status:State.pod}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)


$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName
$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon
$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack
if(($AWSVarialbes.Pod) -eq $NULL){
if($Environmentattributon -eq "jazz"){
$Environmentpod = $Environmentattributon
}else{
$S3bucketslist = $NULL
$S3bucketslist = aws s3 ls
if($S3bucketslist -match "corecard-pod2-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod2"}
elseif($S3bucketslist -match "corecard-pod4-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod4"}
elseif($S3bucketslist -match "corecard-pod5-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod5"}
elseif(($S3bucketslist -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($Environmentattributon -eq "jazz")) {$Environmentpod = "jazz"}
}
}
else{
$Environmentpod = $AWSVarialbes.Pod.ToLower()}
$Environmentpod
$Result = @()
ForEach($ServerType in $ServerTypes) {
$ResultServerType =@()
Write-Host -ForegroundColor DarkYellow $ServerType
$ServerList = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)
#$ServerList

 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
Invoke-Command -ComputerName $ServerList.name -SessionOption $option -ErrorAction inquire -ScriptBlock{
 
$DBBCDrive = Get-OdbcDriver
$ODBCDSN = Get-OdbcDsn

$DBBCDrivecheck = $null

if ($DBBCDrive -ne $null) {
    $DBBCDrivecheck = "ODBC Installed"
}

if (($DBBCDrivecheck -eq "ODBC Installed") -and ($ODBCDSN.Name -contains "LISTPLAT") -or ($ODBCDSN.Name -contains "LISTRPT") -and ($ODBCDSN.Platform -eq "32-bit") -and ($ODBCDSN.DriverName -eq "ODBC Driver 17 for SQL Server") -and ($ODBCDSN.Attribute.MultiSubnetFailover -eq "Yes") -and ($ODBCDSN.Attribute.Server -eq "CCAPPLIST1") -and ($ODBCDSN.Attribute.Description -eq "CCAPPLIST1")) {

Write-Host -ForegroundColor Green $env:COMPUTERNAME
    Write-Output "ODBCName - $($ODBCDSN.Name)"
    Write-Output "Server - $($ODBCDSN.Attribute.Server)"
    Write-Output "Description - $($ODBCDSN.Attribute.Description)"
   #Write-Output "Platform - $($ODBCDSN.Platform)"
   #Write-Output "DriverName - $($ODBCDSN.DriverName)"
   #Write-Output "MultiSubnetFailover - $($ODBCDSN.Attribute.MultiSubnetFailover)"

} else {
    Write-Host -ForegroundColor red $env:COMPUTERNAME
    Write-Host -ForegroundColor red "ODBCName - $($ODBCDSN.Name)"
    Write-Host -ForegroundColor red "Server - $($ODBCDSN.Attribute.Server)"
    Write-Host -ForegroundColor red "Description - $($ODBCDSN.Attribute.Description)"
}
 
}}
