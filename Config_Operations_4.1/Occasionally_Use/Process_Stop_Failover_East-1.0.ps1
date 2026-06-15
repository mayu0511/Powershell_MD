######################################################################################################################
# Process_Stop_Failover_East  | DEVELOPED BY:: Rahul Bajpai
# Version 1.0 | Date:: 23-Dec-2025
# Latest Updated by : Mahendra Dwivedi |
#====================================================================================================================
############################################################
# STEP 0 – Initialize folders, report & logging
############################################################

Clear-Host

$ReportFolder = "C:\Temp"
$ReportFile   = "$ReportFolder\Process_Stop_Upgrade.html"
$LogFile      = "$ReportFolder\Process_Stop_Upgrade.log"

if (!(Test-Path $ReportFolder)) {
    New-Item -Path $ReportFolder -ItemType Directory | Out-Null
}

Start-Transcript -Path $LogFile -Append
Write-Host "Script started at $(Get-Date)"

############################################################
# STEP 1 – Read server list & define rules
############################################################

$ServerListFile = "D:\Backup\AWF_East.txt"
$ServerList = Get-Content $ServerListFile | ForEach-Object { $_.Trim().ToUpper() }

# Target servers (special behavior)
$TargetServers = @(
    "CCAWFE1PROD11","CCAWFE1PROD26","CCAWFE1PROD80","CCAWFE1PROD31"
    #"CCAWFW2PROD11","CCAWFW2PROD26","CCAWFW2PROD80","CCAWFW2PROD31"
)

# Processes NEVER stopped on TargetServers
$ExcludedProcesses = @(
    "Rundbb_AlertNotification",
    "Rundbb_BatchNotification",
    "Rundbb_BatchNotification2",
    "Rundbb_Rewardnotification",
    "Rundbb_UpdateCall",
    "Rundbb_MSMQ"
)

$sessionOption = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

############################################################
# STEP 2 – Stop rundbb_* processes
############################################################

$StoppedProcessData = Invoke-Command -ComputerName $ServerList `
    -SessionOption $sessionOption `
    -ErrorAction Continue `
    -HideComputerName `
    -ScriptBlock {

    param($TargetServers, $ExcludedProcesses)

    $server = $env:COMPUTERNAME.ToUpper()
    $results = @()

    $processes = Get-Process -Name "rundbb_*" -ErrorAction SilentlyContinue

    foreach ($proc in $processes) {

        # Skip excluded processes on TargetServers
        if ($TargetServers -contains $server -and
            $ExcludedProcesses -contains $proc.Name) {
            continue
        }

        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            $status = "Stopped"
        }
        catch {
            $status = "Already Stopped"
        }

        $results += [PSCustomObject]@{
            ServerName        = $server
            ProcessName       = $proc.Name
            ProcessStatus     = $status
            ProcessStopTime   = Get-Date
        }
    }

    return $results

} -ArgumentList $TargetServers, $ExcludedProcesses

############################################################
# STEP 3 – Clean & sequence data
############################################################

$FinalProcessData = $StoppedProcessData |
    Where-Object {
        $_ -ne $null -and
        $_.ServerName -and
        $_.ProcessName
    } |
    Sort-Object ServerName, ProcessName

############################################################
# STEP 4 – Generate clean HTML report
############################################################

$GeneratedTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$HtmlHeader = @"
<html>
<head>
<title>Process Stop Report</title>
<style>
body {
    font-family: Arial;
    background-color: #ffffff;
}
h2, p {
    text-align: center;
}
table {
    border-collapse: collapse;
    width: 100%;
    font-size: 13px;
}
th {
    background-color: #e6e6e6;
    border: 1px solid black;
    padding: 8px;
}
td {
    border: 1px solid black;
    padding: 6px;
    text-align: center;
}
tr:nth-child(even) {
    background-color: #f9f9f9;
}
</style>
</head>
<body>

<h2>Process Stop Report</h2>
<p>Generated on: $GeneratedTime</p>
"@

if ($FinalProcessData.Count -gt 0) {
    $HtmlBody = $FinalProcessData |
        Select ServerName, ProcessName, ProcessStatus, ProcessStopTime |
        ConvertTo-Html -Fragment
}
else {
    $HtmlBody = "<p><b>No rundbb_* processes found.</b></p>"
}

$HtmlFooter = "</body></html>"

$HtmlHeader + $HtmlBody + $HtmlFooter | Out-File $ReportFile -Encoding UTF8

############################################################
# STEP 5 – Open report & stop logging
############################################################

Write-Host "HTML Report generated at: $ReportFile"
Write-Host "Log file generated at:   $LogFile"

Start-Process $ReportFile
Stop-Transcript
