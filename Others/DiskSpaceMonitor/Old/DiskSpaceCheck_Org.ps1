######################################################################################################################
# Disk Size and Space Check | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.2 | Updated Fixes | Date:: 12-March-2025
#=====================================================================================================================
If (!(Test-Path .\Logs\))
{ mkdir .\Logs\
}	
$DATE = Get-date -Format MM-dd-yyyy-HH-mm-ss
Start-Transcript -Path .\Logs\APIHealthChecker_$DATE.log

Clear-Host
$Module = "Disk Drive Check"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
#$ServerTypes = 'svc'
$ThisServer = $env:COMPUTERNAME.ToLower()

# Determine Region
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
} else {
    Write-Host "Unknown region for server: $ThisServer" -ForegroundColor Red
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

# Generate HTML Report
#$OutputFile = "C:\temp\DiskSizeSpaceReport.html"
$OutputFile = "D:\DBBSetup\MonitoringScript\DiskMonitor\Logs\DiskSizeSpaceReport.html"

$HtmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Disk Size and Space Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { width: 80%; border-collapse: collapse; margin: 20px auto; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: center; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2 style="text-align:center;">Disk Size and Space Report</h2>
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
$LastServer = ""

foreach ($Result in $AllResults) {
    # Determine if the usage should be highlighted in red
    $UsageColor = if ($Result.'Usage(%)' -gt 30) { "style='color:red; font-weight:bold;'" } else { "" }

    # If this is a new server, print its name in the first column
    if ($Result.'Server Name' -ne $LastServer) {
        $HtmlContent += "<tr>
                            <td rowspan='2'>$($Result.'Server Name')</td>
                            <td>$($Result.DeviceID)</td>
                            <td>$($Result.TotalSizeGB)</td>
                            <td>$($Result.UsedSpaceGB)</td>
                            <td>$($Result.FreeSpaceGB)</td>
                            <td $UsageColor>$($Result.'Usage(%)')</td>
                         </tr>"
        $LastServer = $Result.'Server Name'
    } else {
        # If this is the same server, just add the drive row
        $HtmlContent += "<tr>
                            <td>$($Result.DeviceID)</td>
                            <td>$($Result.TotalSizeGB)</td>
                            <td>$($Result.UsedSpaceGB)</td>
                            <td>$($Result.FreeSpaceGB)</td>
                            <td $UsageColor>$($Result.'Usage(%)')</td>
                         </tr>"
    }
}

# Combine all parts and write to HTML file
$HtmlReport = $HtmlHeader + $HtmlContent + $HtmlFooter
$HtmlReport | Out-File -Encoding utf8 $OutputFile

# Open the report in the default web browser
Invoke-Item $OutputFile

Write-Host "Disk Space Report generated successfully: $OutputFile" -ForegroundColor Green


