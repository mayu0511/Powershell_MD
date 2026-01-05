######################################################################################################################
# Disk Usage and Space Monitor | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.5 | Updated Fixes | Date:: 13-March-2025
#=====================================================================================================================

# Define Server List
$ServerListFile = "D:\Archive\DiskSpaceMonitor\Serverlist.txt"
if (!(Test-Path $ServerListFile)) {
    Write-Host "Error: Server list file not found at $ServerListFile" -ForegroundColor Red
    exit 1
}

$ServerList = Get-Content $ServerListFile -ErrorAction Stop
if ($ServerList.Count -eq 0) {
    Write-Host "Error: Server list file is empty!" -ForegroundColor Red
    exit 1
}
$Timestamp = Get-Date -Format "dd-MM-yyyy-HH-mm-ss"
$OutputFile = "C:\Temp\DiskUsageandSpaceMonitor$Timestamp.html"
# Output file for HTML Report
#$OutputFile = "C:\Temp\DiskUsageandSpaceMonitor.html"

# Get the hostname dynamically where the script is running
$HostName = $env:COMPUTERNAME

# Array to store results
$AllResults = @()

# Print table header once
Write-Host "`nServer Name   | DeviceID | TotalSize(GB) | UsedSpace(GB) | FreeSpace(GB) | Usage(%)" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------------------"

ForEach ($computername in $ServerList) {
    try {
        # Capture results from remote servers
        $drives = Invoke-Command -ComputerName $computername -ErrorAction Stop -ScriptBlock {
            Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | 
                Select-Object @{Name="Server Name"; Expression={$env:COMPUTERNAME}} ,
                              DeviceID, 
                              @{Name="TotalSizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                              @{Name="UsedSpaceGB"; Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}}, 
                              @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, 
                              @{Name="Usage(%)"; Expression={if ($_.Size -gt 0) {[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)} else {"N/A"}}}
        }
        
        # Display results and store in array
        foreach ($drive in $drives) {
            Write-Host ("{0,-12} | {1,-8} | {2,-14} | {3,-14} | {4,-14} | {5,-8}" -f $computername, $drive.DeviceID, $drive.TotalSizeGB, $drive.UsedSpaceGB, $drive.FreeSpaceGB, $drive."Usage(%)") -ForegroundColor Cyan
            $AllResults += $drive
        }
    }
    catch {
        Write-Host "Error: Unable to connect to $computername - $_" -ForegroundColor Red
    }
}

# Generate HTML Report
$HtmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Disk Usage and Space Monitor</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { width: 80%; border-collapse: collapse; margin: 20px auto; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: center; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .high-usage { background-color:#ffcccc; color:red; font-weight:bold; }
    </style>
</head>
<body>
    <h2 style="text-align:center;">Disk Usage and Space Monitor</h2>
    
    <!-- Additional Details Table -->
    <table>
        <tr>
            <th>Responsible Team</th>
            <th>Alert Source</th>
            <th>Host Name</th>
        </tr>
        <tr>
            <td>Config Team</td>
            <td>Windows Task Scheduler</td>
            <td>$HostName</td>
        </tr>
    </table>
    <br/>

    <table>
        <tr>
            <th>Server Name</th>
            <th>DeviceID</th>
            <th>TotalSize (GB)</th>
            <th>UsedSpace (GB)</th>
            <th>FreeSpace (GB)</th>
            <th>Usage (%)</th>
        </tr>
"@

$HtmlContent = ""
foreach ($Result in $AllResults) {
    $RowStyle = if ($Result.'Usage(%)' -gt 80) { "class='high-usage'" } else { "" }

    $HtmlContent += "<tr $RowStyle>
                        <td>$($Result.'Server Name')</td>
                        <td>$($Result.DeviceID)</td>
                        <td>$($Result.TotalSizeGB)</td>
                        <td>$($Result.UsedSpaceGB)</td>
                        <td>$($Result.FreeSpaceGB)</td>
                        <td>$($Result.'Usage(%)')</td>
                     </tr>"
}

$HtmlReport = $HtmlHeader + $HtmlContent + "</table></body></html>"
$HtmlReport | Out-File -Encoding utf8 $OutputFile

Write-Host "Disk Usage and Space Monitor generated successfully: $OutputFile" -ForegroundColor Green

# Define email details
$SMTPServer = "corecard-com.mail.protection.outlook.com"
$EmailSender = "mahendra.dwivedi@corecard.com"
$EmailReceiver = @("pod2configteam@corecard.com" , "pod1configteam@corecard.com")

# Ensure the report file exists
if (Test-Path $OutputFile) {
    Write-Host "Report file found: $OutputFile" -ForegroundColor Green
    $EmailBody = Get-Content $OutputFile -Raw  # Read HTML content
} else {
    Write-Host "Error: Report file not found: $OutputFile" -ForegroundColor Red
    exit 1
}

# Check if any server has disk usage above 80%
$HighUsage = $AllResults | Where-Object { $_.'Usage(%)' -gt 80 }

# Determine Email Subject
$EmailSubject = if ($HighUsage) { "[Disk Usage and Space Monitor]-[FAILURE]" } else { "[Disk Usage and Space Monitor]-[SUCCESS]" }





# Send Email with HTML Report as Body
try {
    Send-MailMessage -SmtpServer $SMTPServer -Port 25 `
        -UseSsl -From $EmailSender -To $EmailReceiver `
        -Subject $EmailSubject -Body $EmailBody `
        -BodyAsHtml  # Ensure HTML formatting is applied

    Write-Host "Email Notification Sent with Report in Body" -ForegroundColor Green
} catch {
    Write-Host "Error: Failed to send email - $_" -ForegroundColor Red
}

Write-Host "Script Execution Completed Successfully!" -ForegroundColor Green
