# ---------------- Paths ----------------
$LogFolderPath = "E:\Upload\Testing\vstask\VisualCron_JOBS_LIST\LOG"
$Jobxmllocation = "E:\Upload\Testing\vstask\settings\jobs.xml"  # Job XML path

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

$htmlReport += "</table><br/><p><b>THANKS,<br/>Akash Mahendra</b></p></body>"

# ---------------- Save HTML ----------------
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$htmlFilePath = "C:\temp\JVJOBTrigertime-$timestamp.html"
$htmlReport | Out-File -FilePath $htmlFilePath -Encoding UTF8

# ---------------- Open HTML ----------------
Start-Process $htmlFilePath

# ---------------- End logging ----------------
Stop-Transcript
