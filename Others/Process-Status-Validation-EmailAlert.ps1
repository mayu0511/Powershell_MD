Clear-Host
$Module = "Processes-Status"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
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
#$ServerList.name

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$ResultServerType += Invoke-Command -ComputerName $($ServerList.name) -SessionOption $option -ErrorAction inquire -ScriptBlock {
param ($ServerList,
$AvailabilityZone
)

$ServerAZ = $NULL
$ServerAZ = ($ServerList | Where-Object { ($_.Name).ToLower() -eq "$env:computername".ToLower()}).AvailabilityZone



$resultvalue = @()
$scheduledtasknames = $NULL
$scheduledtasknames = (Get-Scheduledtask -TaskName Task_*).TaskName
$ProcessesNames = $NULL
$ProcessesNames = (Get-Process -Name 'DbbAppServer*', 'Rundbb*').ProcessName

if($scheduledtasknames.count -eq $ProcessesNames.count) {$ServerTasksVsProcessesCount = "Matching"} else{$ServerTasksVsProcessesCount = "Mismatch"}
if($scheduledtasknames -eq $NULL){


$resultvalue += [PSCustomObject] @{ 
    ServerName = "$($env:computername)"
    ProcessName = "$("No Tasks")"
    TaskUSer = "$("No Tasks")"
    ProcessStatus = "$("No Tasks")"
    ProcessCount = "$("Mismatch")"
    ProcessUser = "$("Mismatch")"
    ServerTasksVsProcessesCount = "$("$ServerTasksVsProcessesCount")"
    AvailabilityZone = "$($ServerAZ)"
    IntentMode = "$($IntentMode)"}
}
#}


foreach($scheduledtaskname in $scheduledtasknames){
$HealthPort = $NULL
$ProcessStatus = $NULL
$HealthWebcall = $NULL
$HealthyContent = $NULL
$TaskDetails = $NULL
$TaskDetails = Get-Scheduledtask -TaskName $scheduledtaskname
$TaskUser = $NULL
$TaskUser = $TaskDetails.Principal.UserID
$FindProcessName = $NULL

if($scheduledtaskname -match "Task_DbbAppServer"){$FindProcessName = $scheduledtaskname.Replace("Task_","")} else {$FindProcessName = $scheduledtaskname.Replace("Task_","Rundbb_")}
$ProcessDetails = $NULL
$ProcessDetails = Get-Process -Name $FindProcessName -IncludeUserName -ErrorAction SilentlyContinue 
$ProcessCount = $NULL
if($ProcessDetails.Name.count -eq 1){$ProcessCount = "Matching"} else{$ProcessCount = "Mismatch"}
$ProcessUser = $NULL
if($ProcessDetails.UserName -eq $TaskUser){$ProcessUser = "Matching"} else{$ProcessUser = "Mismatch"}

$IntentMode = (Select-String -Path D:\DBBSetup\BatchScripts\CoreIssue\RTM.config -Pattern "RunTimeMode=").ToString().Split('=')[1]

try{
$HealthPort = $TaskDetails.Actions.Arguments.split(' ')[1]
if($HealthPort -eq $NULL){$ProcessStatus = "HEALTH PORT NOT FOUND"} }
catch{$ProcessStatus = "HEALTH PORT NOT FOUND" 
}

if($ProcessStatus -ne "HEALTH PORT NOT FOUND"){
try{
$HealthWebcall = Invoke-WebRequest -Uri "http://localhost:$HealthPort/healthy" -TimeoutSec 5 -ErrorAction SilentlyContinue
if($HealthWebcall -eq $NULL){$ProcessStatus = "PROCESS DOWN"}
}catch{$ProcessStatus = "PROCESS DOWN"}

}
if(($ProcessStatus -ne "HEALTH PORT NOT FOUND") -and ($ProcessStatus -ne "PROCESS DOWN")){
$HealthyContent = $HealthWebcall.RawContent -match "GMT

Healthy"

if(($HealthWebcall.StatusCode -eq "200") -and ($HealthyContent)){$ProcessStatus = "Process Healthy" }
else{$ProcessStatus = "Process Unhealthy"}
}
#$resultvalueSchedule = @() 
$resultvalue += [PSCustomObject] @{ 
    ServerName = "$($env:computername)"
    ProcessName = "$($scheduledtaskname)"
    TaskUser = "$($TaskUser)"
    ProcessStatus = "$($ProcessStatus)"
    ProcessCount = "$($ProcessCount)"
    ProcessUser = "$($ProcessUser)"
    ServerTasksVsProcessesCount = "$($ServerTasksVsProcessesCount)"
    AvailabilityZone = "$($ServerAZ)"
    IntentMode = "$($IntentMode)"
    
    }

#$resultvalue += $resultvalueSchedule
}
$resultvalue
} -ArgumentList $ServerList, $ServerList.AvailabilityZone

$Result += $ResultServerType | Sort-Object -Property @{Expression = {($_.ServerName -replace '\d', '') }}, {[int]($_.ServerName -replace '\D+', '')} 

}

#$upgUsername = "$env:USERDOMAIN\gmsa-app-upg$"
$upgUsername = "<td>$env:USERDOMAIN\gmsa-app-upg$</td>"
$upgUsernameColor = "<td bgcolor='lightsalmon'>$env:USERDOMAIN\gmsa-app-upg$</td>"
$IntentMode = "<td>ZDT</td>"
$IntentModeColor = "<td bgcolor='lightsalmon'>ZDT</td>"



$ProcessesReport = $Result | select ServerName, ProcessName, TaskUser, ProcessStatus, ProcessCount, ProcessUser, ServerTasksVsProcessesCount, AvailabilityZone, IntentMode | ConvertTo-Html -Title "Processes Status Validation Report " 
$BodyHeader = "<h2 style='color: steelblue;'>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</h2>"
#$ProcessesReport = $Result | select ServerName, ProcessName, Status | Sort-Object -Property @{Expression = {($_.ServerName -replace '\d', '') }}, {[int]($_.ServerName -replace '\D+', '')} | ConvertTo-Html -Title "Processes Status"
$Outputreport = $ProcessesReport.Replace("<body>", "<body><h2 style='color: steelblue;'>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</h2>").Replace("<table>", "<Table border=1 cellpadding=0 cellspacing=0>").Replace("<td>PROCESS DOWN</td>", "<td bgcolor=LightSalmon>PROCESS DOWN</td>").Replace("<td>HEALTH PORT NOT FOUND</td>", "<td bgcolor=LightSalmon>HEALTH PORT NOT FOUND</td>").Replace("<td>No Tasks</td>", "<td bgcolor=LightSalmon>No Tasks</td>").Replace("<th>", '<th bgcolor=gray>').Replace($upgUsername, $upgUsernameColor).Replace("<td>Mismatch</td>", "<td bgcolor=LightSalmon>Mismatch</td>").Replace($IntentMode, $IntentModeColor).Replace("<td>Process Unhealthy</td>", "<td bgcolor=LightSalmon>Process Unhealthy</td>")
#$Result | select ServerName, ProcessName, Status | Group-Object -Property ProcessName -NoElement | Sort-Object  -Property  Name -Descending


$ReportFileNamePrefix = $Module +"_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | out-file "$ReportFile"

$reportbody = [string]$Outputreport


aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

if($host.Name -eq "Windows PowerShell ISE Host"){Invoke-Item $ReportFile}

$SMTPServer = "email-smtp.$($Region.ToLower()).amazonaws.com"
$SecretObject = Get-SECSecretValue -secretid "ses-smtp-$EnvironmentName-secret"
$SMTPUser = ($SecretObject.SecretString | ConvertFrom-Json).id
$SMTPPassword= ($SecretObject.SecretString | ConvertFrom-Json).ses_smtp_password_v4
if($Environmentpod -eq "jazz"){$EmailSender = "pod3-$EnvironmentName-alerts@infra.marcus.com"}else{$EmailSender = "$Environmentpod-$EnvironmentName-alerts@infra.marcus.com"}

if($Environmentattributon -eq "jazz"){$EmailReceiver = "akash.sharma@corecard.com"}else{$EmailReceiver = "akash.sharma@corecard.com"}
$SMTPPasswordSecure = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUser, $SMTPPasswordSecure)
if([string]$Outputreport -notmatch "LightSalmon"){$EmailSubject = "[$($Environmentattributon.ToUpper()) $($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper())] -- [Processes-Status Validation Report] -- [Success]"}
else{$EmailSubject = "[$($Environmentattributon.ToUpper()) $($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper())] -- [Processes-Status Validation Report] -- [Failure]"}

Write-Host "Sending Email Notification"
Send-MailMessage -SmtpServer $SMTPServer -Port 587 -Credential $SMTPCredential -UseSsl -From $EmailSender -To $EmailReceiver -Subject $EmailSubject -BodyAsHtml $reportbody
Write-Host "Email Notification Sent"

Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable EnvironmentName
Clear-Variable Environmentpod


Clear-Variable SMTPServer
Clear-Variable SecretObject
Clear-Variable SMTPUser
Clear-Variable SMTPPassword
Clear-Variable EmailSender
Clear-Variable EmailReceiver
Clear-Variable SMTPPasswordSecure
Clear-Variable SMTPCredential
Clear-Variable EmailSubject

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
Clear-Variable reportbody
