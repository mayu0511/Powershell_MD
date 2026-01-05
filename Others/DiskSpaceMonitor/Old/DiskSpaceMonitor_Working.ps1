######################################################################################################################
# Disk Usage and Space Monitor | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 | Updated Fixes | Date:: 13-March-2025
#=====================================================================================================================

If (!(Test-Path .\Logs\)) { mkdir .\Logs\ }	
$DATE = Get-date -Format MM-dd-yyyy-HH-mm-ss
Start-Transcript -Path .\Logs\DiskSpaceMonitor_$DATE.log

Clear-Host
$Module = "Disk Drive Check"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat', 'rpd', 'rps'
$ThisServer = $env:COMPUTERNAME.ToLower()

# Determine Region
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
} else {
    exit
}

# Fetch AWS Instance Data
$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value, Environment:Tags[?Key=='environment']|[0].Value, Stack:Tags[?Key=='stack']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

if (-not $AWSVariables) { exit }

# Extract Environment Details
$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentStack = if ($AWSVariables.Stack) { $AWSVariables.Stack.ToLower()[0] } else { "default" }

# Get list of servers
$computers = @()

foreach ($ServerType in $ServerTypes) {
    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json
    if ($ServerList) { $computers += $ServerList.Name }
}

if (-not $computers) {
    Write-Host "No running servers found." -ForegroundColor Yellow
    exit
}

# Print table header
Write-Host "`nServer Name   | DeviceID | TotalSize(GB) | UsedSpace(GB) | FreeSpace(GB) | Usage(%)" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------------------"

foreach ($computer in $computers) {
    try {
        # Get disk space details
        $drives = Get-WmiObject Win32_LogicalDisk -ComputerName $computer -Filter "DriveType=3" | 
                  Select-Object DeviceID, 
                                @{Name="TotalSizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                                @{Name="UsedSpaceGB"; Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}}, 
                                @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, 
                                @{Name="Usage(%)"; Expression={if ($_.Size -gt 0) {[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)} else {"N/A"}}}

        if (-not $drives) { continue }

        # Print first line with server name
        $firstDrive = $true
        foreach ($drive in $drives) {
            $usage = $drive."Usage(%)"
            $color = if ($usage -gt 30) { "Red" } else { "Cyan" }

            if ($firstDrive) {
                Write-Host ("{0,-12} | {1,-8} | {2,-14} | {3,-14} | {4,-14} | {5,-8}" -f $computer, $drive.DeviceID, $drive.TotalSizeGB, $drive.UsedSpaceGB, $drive.FreeSpaceGB, $drive."Usage(%)") -ForegroundColor $color
                $firstDrive = $false
            } else {
                Write-Host ("{0,-12} | {1,-8} | {2,-14} | {3,-14} | {4,-14} | {5,-8}" -f "", $drive.DeviceID, $drive.TotalSizeGB, $drive.UsedSpaceGB, $drive.FreeSpaceGB, $drive."Usage(%)") -ForegroundColor $color
            }
        }
    } catch {
        Write-Host "Failed to retrieve data for $computer" -ForegroundColor Red
    }
}
