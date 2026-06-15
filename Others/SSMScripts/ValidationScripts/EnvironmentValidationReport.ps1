
Clear-Host
$Modules = 'App-Setup', 'Web-WCF', 'Web-CoreCardServices', 'Web-Services', 'Web-CoreIssue', 'Web-CoreCredit', 'KMS-Validation', 'Processes-Status'
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

$EnvironmentValidationReportsPath = "C:\Temp\EnvironmentValidationReports"
$CurrentDate = Get-Date -Format yyyy-MM-dd
if(Test-Path -Path "$EnvironmentValidationReportsPath"){Remove-Item -Force -Path "$EnvironmentValidationReportsPath" -Recurse}
New-Item -ItemType Directory -Force -Path "$EnvironmentValidationReportsPath"
Write-Host "Removing older validation files from S3 bucket"
aws s3 rm s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/ --recursive --exclude "*$CurrentDate*"
Write-Host "Downloading today's validation files from S3 bucket"
aws s3 cp  "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/" $EnvironmentValidationReportsPath --recursive --exclude "*" --include "*$CurrentDate*"
$Outputreport = $NULL
$Outputreport = "<HTML><TITLE> Validation Report </TITLE>"
Write-Host "Merging All Validation Files"
foreach($Module in $Modules){
$ValidationFilePath = $NULL
$ValidationFilePath = "$EnvironmentValidationReportsPath\$Module" + "_Validation_$CurrentDate.html"
if(Test-Path -Path $ValidationFilePath){
Write-Host "Merging $Module validation file"
$Outputreport += (Get-Content $ValidationFilePath).Replace("<HTML><TITLE> $Module Validation Report </TITLE>", "").Replace("</HTML>", "") 
$Outputreport += "<br><br>"
}else{
Write-Host "$Module validation file not exist"
$Outputreport += "<BODY background-color:peachpuff>
                  <H2 Style=""color:#CD5C5C"">$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</H2>
                  <H4 Style=""color:#CD5C5C"">Validation Failed - File not exist. $ValidationFilePath</H4><br><br>"}
}
$Outputreport += "</HTML>" 

$Outputreport | out-file "$EnvironmentValidationReportsPath\EnvironmentValidationReport.html"

[regex]$RedColorCountRegex = "#CD5C5C"
$RedColorCount = $NULL
$RedColorCount = $RedColorCountRegex.Matches($Outputreport).count
Write-Host "Failure Counts in Consolidated  Report - $RedColorCount"

[regex]$LightSalmonColorCountRegex = "LightSalmon"
$LightSalmonColorCount = $NULL
$LightSalmonColorCount = $LightSalmonColorCountRegex.Matches($Outputreport).count
Write-Host "Failure Counts in Consolidated  Report - $LightSalmonColorCount"


$SMTPServer = "email-smtp.$($Region.ToLower()).amazonaws.com"
$SecretObject = Get-SECSecretValue -secretid "ses-smtp-$EnvironmentName-secret"
$SMTPUser = ($SecretObject.SecretString | ConvertFrom-Json).id
$SMTPPassword= ($SecretObject.SecretString | ConvertFrom-Json).ses_smtp_password_v4
if($Environmentpod -eq "jazz"){$EmailSender = "pod3-$EnvironmentName-alerts@infra.marcus.com"}else{$EmailSender = "$Environmentpod-$EnvironmentName-alerts@infra.marcus.com"}
#$EmailReceiver = "utsav.tyagi@corecard.com"
if($Environmentattributon -eq "jazz"){$EmailReceiver = "POD3ConfigTeam@corecard.com"}else{$EmailReceiver = "POD2ConfigTeam@corecard.com"}
$SMTPPasswordSecure = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUser, $SMTPPasswordSecure)
if(($RedColorCount -eq "0") -and ($LightSalmonColorCount -eq "0")){$EmailSubject = "[$($Environmentattributon.ToUpper()) $($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper())] -- [Environment Validation Report] -- [Success]"}
else{$EmailSubject = "[$($Environmentattributon.ToUpper()) $($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper())] -- [Environment Validation Report] -- [Failure]"}

Write-Host "Sending Email Notification"
Send-MailMessage -SmtpServer $SMTPServer -Port 587 -Credential $SMTPCredential -UseSsl -From $EmailSender -To $EmailReceiver -Subject $EmailSubject -BodyAsHtml $Outputreport
Write-Host "Email Notification Sent"

Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable EnvironmentName
Clear-Variable Environmentpod
Clear-Variable EnvironmentValidationReportsPath
Clear-Variable currentDate
Clear-Variable RedColorCountRegex
Clear-Variable RedColorCount
Clear-Variable LightSalmonColorCountRegex
Clear-Variable LightSalmonColorCount
Clear-Variable SMTPServer
Clear-Variable SecretObject
Clear-Variable SMTPUser
Clear-Variable SMTPPassword
Clear-Variable EmailSender
Clear-Variable EmailReceiver
Clear-Variable SMTPPasswordSecure
Clear-Variable SMTPCredential
Clear-Variable EmailSubject
