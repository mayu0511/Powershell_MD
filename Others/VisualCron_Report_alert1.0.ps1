clear-host
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

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | Out-Null
$ErrorActionPreference = "Continue"

# ---------------- Paths ----------------
$LogFolderPath = "D:\DBBSetup\MonitoringScript\SSMScripts\VisualCron_JOBS_LIST\LOG"
$Jobxmllocation = "C:\Program Files (x86)\VisualCron\settings\jobs.xml"  # Job XML path

# Create folders if not exist
If (!(Test-Path $LogFolderPath)) { mkdir $LogFolderPath }

# ---------------- Logging ----------------
$DATE = Get-Date -Format "MM-dd-yyyy-HH-mm-ss"
$Logfile = "$LogFolderPath\VisualCron_$DATE.log"
Start-Transcript -Path $Logfile

Function LogWrite {
    Param ([string]$logstring)
    $time = (Get-Date).ToString()
    Write-Host "`r`n$time : $logstring"
    [System.IO.File]::AppendAllText($Logfile, "`r`n$time : $logstring")
    [System.IO.File]::AppendAllText($Logfile, "`r`n-------------------------------------------------------------")
}

$hostname = [System.Net.Dns]::GetHostName()

# ---------------- Load XML ----------------
[xml]$jobslistxml = Get-Content -Path $Jobxmllocation -Raw

# ---------------- Build HTML ----------------
$htmlReport = @"
<style>
table { border-collapse: collapse; width: 100%; font-size: 8.5pt; }
th, td { border: 1px solid black; padding: 8px; text-align: center; }
</style>
<body style='font-family: Verdana, sans-serif'>
<h2>VisualCron Job Trigger Report</h2>
<table><tr bgcolor='gray' style='color:white;'><th>Responsible Team</th><th>Alert Source</th><th>Host Name</th></tr>
<tr><td>Config Team</td><td>VisualCron</td><td>$hostname</td></tr></table>
<br/>
<table><tr bgcolor='gray' style='color:white;'><th>S.no</th><th>Job Name</th><th>Trigger Time</th><th>Job Status</th><th>Task Name</th><th>Task Status</th></tr>
"@

$sno = 1

foreach ($job in $jobslistxml.ArrayOfJobClass.JobClass) {
    $sn = $sno++
    $jobName = $job.Name
    $jobActive = $job.Stats.Active
    $triggerTime = $job.Triggers.TriggerClass.Description
    if (-not $triggerTime) { $triggerTime = "No Trigger Description" }

    $taskList = $job.Tasks.TaskClass
    $taskCount = $taskList.Count
    $style = if ($jobActive -eq 'True') { 'background-color: green;color: white;' } else { 'background-color: red;color: white;' }

    $first = $true
    foreach ($task in $taskList) {
        $taskName = $task.Name
        $taskActive = $task.Stats.Active
        $stylet = if ($taskActive -eq 'True') { 'background-color: green;color: white;' } else { 'background-color: red;color: white;' }

        if ($first) {
            $htmlReport += "<tr><td rowspan='$taskCount'>$sn</td><td rowspan='$taskCount'>$jobName</td><td rowspan='$taskCount'>$triggerTime</td><td rowspan='$taskCount' style='$style'>$jobActive</td><td>$taskName</td><td style='$stylet'>$taskActive</td></tr>"
            $first = $false
        } else {
            $htmlReport += "<tr><td>$taskName</td><td style='$stylet'>$taskActive</td></tr>"
        }
    }
}

$htmlReport += "</table><br/><p><b>THANKS,<br/>Configuration Team</b></p></body>"

# -------- SES Email Sending --------


$SMTPServer = "email-smtp.$($Region.ToLower()).amazonaws.com"
$SecretObject = Get-SECSecretValue -secretid "ses-smtp-$EnvironmentName-secret"
$SMTPUser = ($SecretObject.SecretString | ConvertFrom-Json).id
$SMTPPassword= ($SecretObject.SecretString | ConvertFrom-Json).ses_smtp_password_v4
if($Environmentpod -eq "jazz"){$EmailSender = "pod3-$EnvironmentName-alerts@infra.marcus.com"}else{$EmailSender = "$Environmentpod-$EnvironmentName-alerts@infra.marcus.com"}

if($Environmentattributon -eq "jazz"){$EmailReceiver = "pod3configteam@corecard.com"}else{$EmailReceiver = "pod2configteam@corecard.com"}
$SMTPPasswordSecure = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUser, $SMTPPasswordSecure)
$EmailSubject = "[$($Environmentattributon.ToUpper()) $($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper())] -- [VisualCron Report] -- [$hostname]"

Write-Host "Sending Email Notification via SES..."
Send-MailMessage -SmtpServer $SMTPServer -Port 587 -Credential $SMTPCredential -UseSsl -From $EmailSender -To $EmailReceiver -Subject $EmailSubject -BodyAsHtml $htmlReport

Write-host "Email Sent"


# --- Delete log files older than 1 day ---
$RetentionDays = 1
Write-Host "Cleaning up log files older than $RetentionDays day(s)..."
Get-ChildItem -Path $LogFolderPath -Filter *.log |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
    ForEach-Object {
        LogWrite "Deleting old log file: $($_.FullName)"
        Remove-Item $_.FullName -Force
    }

Stop-Transcript