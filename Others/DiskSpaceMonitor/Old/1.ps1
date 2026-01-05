Clear-Host
$Module = "Disk Drive Check"
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
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
$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value, Environment:Tags[?Key=='environment']|[0].Value, Stack:Tags[?Key=='stack']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

if (-not $AWSVariables) {
    Write-Host "Failed to retrieve AWS instance details." -ForegroundColor Red
    exit
}

# Extract Environment Details
$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentStack = if ($AWSVariables.Stack) { $AWSVariables.Stack.ToLower()[0] } else { "default" }

# Store Results
$AllResults = @()

foreach ($ServerType in $ServerTypes) {
    Write-Host "Checking Server Type: $ServerType" -ForegroundColor DarkYellow

    # Get Running Servers of Each Type
    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json

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
                                'DeviceID'    = $drive.DeviceID
                                'TotalSize(GB)' = $drive.TotalSizeGB
                                'UsedSpace(GB)' = $drive.UsedSpaceGB
                                'FreeSpace(GB)' = $drive.FreeSpaceGB
                                'Usage(%)'      = $drive."Usage(%)"
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

# Format Output
Write-Host "`nFinal Disk Space Report:`n" -ForegroundColor Green
$AllResults | Format-Table -AutoSize
