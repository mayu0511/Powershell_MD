If (!(Test-Path .\Logs\)) { mkdir .\Logs\ }	
$DATE = Get-date -Format MM-dd-yyyy-HH-mm-ss
Start-Transcript -Path .\Logs\DiskSizeSpaceChecker_$DATE.log

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

# Store Results
$AllResults = @()

foreach ($ServerType in $ServerTypes) {
    # Get Running Servers of Each Type
    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json

    if ($ServerList) {
        foreach ($Server in $ServerList) {
            $ComputerName = $Server.Name
            if ($ComputerName) {
                # Get Disk Space Details
                try {
                    $drives = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType=3" | 
                              Select-Object DeviceID, 
                                            @{Name="TotalSize(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                                            @{Name="UsedSpace(GB)"; Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}}, 
                                            @{Name="FreeSpace(GB)"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, 
                                            @{Name="Usage(%)"; Expression={if ($_.Size -gt 0) {[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)} else {"N/A"}}}

                    if ($drives) {
                        foreach ($drive in $drives) {
                            $AllResults += [PSCustomObject]@{
                                'Server Name'   = $ComputerName
                                'DeviceID'      = $drive.DeviceID
                                'TotalSize(GB)' = $drive.'TotalSize(GB)'
                                'UsedSpace(GB)' = $drive.'UsedSpace(GB)'
                                'FreeSpace(GB)' = $drive.'FreeSpace(GB)'
                                'Usage(%)'      = $drive.'Usage(%)'
                            }
                        }
                    }
                } catch {}
            }
        }
    }
}

# Print Table with Proper Formatting
$header = "{0,-15} {1,-10} {2,15} {3,15} {4,15} {5,10}" -f "Server Name", "DeviceID", "TotalSize(GB)", "UsedSpace(GB)", "FreeSpace(GB)", "Usage(%)"
Write-Host "`n$header" -ForegroundColor Cyan
Write-Host ("-" * 80)

foreach ($entry in $AllResults) {
    $usage = $entry.'Usage(%)'
    $color = if ($usage -gt 25) { "Red" } else { "White" }

    $output = "{0,-15} {1,-10} {2,15} {3,15} {4,15} {5,10}" -f $entry.'Server Name', 
                                                              $entry.'DeviceID', 
                                                              $entry.'TotalSize(GB)', 
                                                              $entry.'UsedSpace(GB)', 
                                                              $entry.'FreeSpace(GB)', 
                                                              $entry.'Usage(%)'

    Write-Host $output -ForegroundColor $color
}
