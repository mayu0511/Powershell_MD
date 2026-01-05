Clear-Host
$Module = "Intent-"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
#$ServerTypes = 'svc','bat'
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
$ServerType
$ServerList = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)
$ServerList = ($ServerList | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial).Name

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$ResultServerType += Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction inquire -ScriptBlock {
$resultvalue = @()
$scheduledtasknames = $NULL
$scheduledtasknames = (Get-Scheduledtask -TaskName Task_*).TaskName
$scheduledtaskdesc = $NULL
$scheduledtaskdesc = (Get-Scheduledtask -TaskName Task_*).Description
$IntentMode = $NULL
$IntentMode = (Select-String -Path D:\DBBSetup\BatchScripts\CoreIssue\RTM.config -Pattern "RunTimeMode=").ToString().Split('=')[1]


if($scheduledtasknames -eq $NULL){
$resultvalue += [PSCustomObject] @{ 
    ServerName = "$($env:computername)"
    TaskScheularName = "$("No Tasks")"
    TaskUSer = "$("No Tasks")"
    scheduledtaskdesc = "$("No Tasks")"
    IntentMode = "$("No Tasks")"}
}

foreach($scheduledtaskname in $scheduledtasknames){

$TaskDetails = $NULL
$TaskDetails = Get-Scheduledtask -TaskName $scheduledtaskname
$TaskUser = $NULL
$TaskUser = $TaskDetails.Principal.UserID



$resultvalue += [PSCustomObject] @{ 
    ServerName = "$($env:computername)"
    TaskScheularName = "$($scheduledtaskname)"
    TaskUser = "$($TaskUser)" 
    scheduledtaskdesc = "$($scheduledtaskdesc)"    
    IntentMode = "$($IntentMode)"}


}
$resultvalue
}

$Result += $ResultServerType | Sort-Object -Property @{Expression = {($_.ServerName -replace '\d', '') }}, {[int]($_.ServerName -replace '\D+', '')} 

}


$upgUsername = "<td>$env:USERDOMAIN\gmsa-app-upg$</td>"
$upgUsernameColor = "<td bgcolor='lightsalmon'>$env:USERDOMAIN\gmsa-app-upg$</td>"
$IntentMode = "<td>ZDT</td>"
$IntentModeColor = "<td bgcolor='lightsalmon'>ZDT</td>"




$ProcessesReport = $Result | select ServerName, TaskScheularName, TaskUser, scheduledtaskdesc, IntentMode | ConvertTo-Html -Title "Processes Status Validation Report " 
$BodyHeader = "<h2 style='color: steelblue;'>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</h2>"

$Outputreport = $ProcessesReport.Replace("<body>", "<body><h2 style='color: steelblue;'>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</h2>").Replace("<table>", "<Table border=1 cellpadding=0 cellspacing=0>").Replace($upgUsername, $upgUsernameColor).Replace($IntentMode, $IntentModeColor)



$ReportFileNamePrefix = $Module +"_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | out-file "$ReportFile"
#aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

if($host.Name -eq "Windows PowerShell ISE Host"){Invoke-Item $ReportFile}

Clear-Variable Module
Clear-Variable ServerType
Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable Environmentpod
Clear-Variable result
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
