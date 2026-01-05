######################################################################################################################
# Disk Usage and Space Monitor | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 | Updated Fixes | Date:: 13-March-2025
#=====================================================================================================================
If (!(Test-Path .\Logs\)) { mkdir .\Logs\ }	
$DATE = Get-date -Format MM-dd-yyyy-HH-mm-ss
Start-Transcript -Path .\Logs\DiskSpaceMonitor_$DATE.log

Clear-Host
$Module = "Disk Usage and Space Monitor"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = $env:COMPUTERNAME.ToLower()

# Determine AWS Region
$RegionMap = @{
    "e1" = "us-east-1"
    "w2" = "us-west-2"
    "eu1" = "eu-central-1"  # Example for EU region
}
$ShortRegion = $RegionMap.Keys | Where-Object { $ThisServer -match $_ }

if ($ShortRegion) {
    $Region = $RegionMap[$ShortRegion]
} else {
    Write-Host "Warning: Unable to determine AWS region for server: $ThisServer" -ForegroundColor Yellow
    exit
}

# Fetch AWS Instance Data
$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value,Pod:Tags[?Key=='pod']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

if (-not $AWSVariables) {
    Write-Host "Failed to retrieve AWS instance details." -ForegroundColor Red
    exit
}

# Extract Environment Details
$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()
$EnvironmentStack = if ($AWSVariables.Stack) { $AWSVariables.Stack.ToLower()[0] } else { "default" }
$EnvironmentPod = if ($AWSVariables.Pod) { $AWSVariables.Pod.ToLower() } else { "" }

# Store Results
$AllResults = @()

foreach ($ServerType in $ServerTypes) {
    Write-Host "Checking Server Type: $ServerType" -ForegroundColor DarkYellow

    # Get Running Servers of Each Type
    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value, Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json

    if ($ServerList) {
        foreach ($Server in $ServerList) {
            $ComputerName = $Server.Name
            if ($ComputerName) {
                Write-Host "`nChecking disk space on: $ComputerName" -ForegroundColor Cyan

                # Get Disk Space Details
                try {
                    $drives = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType=3" | 
                              Select-Object DeviceID, 
                                            @{Name="TotalSizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                                            @{Name="UsedSpaceGB"; Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}}, 
                                            @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, 
                                            @{Name="Usage(%)"; Expression={if ($_.Size -gt 0) {[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)} else {"N/A"}}}

                    if ($drives) {
                        foreach ($drive in $drives) {
                            $AllResults += [PSCustomObject]@{
                                'Server Name' = $ComputerName
                                'DeviceID' = $drive.DeviceID
                                'TotalSizeGB' = $drive.TotalSizeGB
                                'UsedSpaceGB' = $drive.UsedSpaceGB
                                'FreeSpaceGB' = $drive.FreeSpaceGB
                                'Usage(%)' = $drive."Usage(%)"
                            }
                        }
                    } else {
                        Write-Host "No valid drive information found on $ComputerName" -ForegroundColor Yellow
                    }

                } catch {
                    Write-Host "Error retrieving disk space for $ComputerName $_" -ForegroundColor Red
                }
            }
        }
    }
}

# Set HostName dynamically
$HostName = $env:COMPUTERNAME

# Generate HTML Report
$OutputFile = "C:\Temp\DiskUsageandSpaceMonitor.html"

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
    $UsageColor = if ($Result.'Usage(%)' -gt 80) { "style='color:red; font-weight:bold;'" } else { "" }

    $HtmlContent += "<tr>
                        <td>$($Result.'Server Name')</td>
                        <td>$($Result.DeviceID)</td>
                        <td>$($Result.TotalSizeGB)</td>
                        <td>$($Result.UsedSpaceGB)</td>
                        <td>$($Result.FreeSpaceGB)</td>
                        <td $UsageColor>$($Result.'Usage(%)')</td>
                     </tr>"
}

$HtmlReport = $HtmlHeader + $HtmlContent + "</table></body></html>"
$HtmlReport | Out-File -Encoding utf8 $OutputFile
Invoke-Item $OutputFile

Write-Host "Disk Usage and Space Monitor generated successfully: $OutputFile" -ForegroundColor Green


# Email Configuration
$SMTPServer = "email-smtp.$($Region.ToLower()).amazonaws.com"
$SecretObject = Get-SECSecretValue -secretid "ses-smtp-$EnvironmentName-secret"
$SMTPUser = ($SecretObject.SecretString | ConvertFrom-Json).id
$SMTPPassword= ($SecretObject.SecretString | ConvertFrom-Json).ses_smtp_password_v4
$EmailSender = "$Environmentpod-$EnvironmentName-alerts@infra.marcus.com"
$EmailReceiver = @("POD3ConfigTeam@corecard.com")
$ReportFile = "C:\Temp\DiskUsageandSpaceMonitor.html"

# Ensure the report file exists
if (Test-Path $ReportFile) {
    Write-Host "Report file found: $ReportFile" -ForegroundColor Green
    $EmailBody = Get-Content $ReportFile -Raw  # Read HTML content
} else {
    Write-Host "Error: Report file not found: $ReportFile" -ForegroundColor Red
    exit 1
}

# Convert SMTP Password to Secure String
$SMTPPasswordSecure = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUser, $SMTPPasswordSecure)

# Send Email with HTML Report as Body
Send-MailMessage -SmtpServer $SMTPServer -Port 587 `
    -Credential $SMTPCredential `
    -UseSsl -From $EmailSender -To $EmailReceiver `
    -Subject "Disk Usage and Space Monitor" -Body $EmailBody `
    -BodyAsHtml  # This ensures HTML formatting is applied

Write-Host "Email Notification Sent with Report in Body" -ForegroundColor Green

Write-Host "Email Notification Sent with Attachment" -ForegroundColor Green

