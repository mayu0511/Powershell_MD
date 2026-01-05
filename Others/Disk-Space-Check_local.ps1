$computers = @("localhost") # Add remote computers like "Server1", "Server2"

# Print table header
Write-Host "`nServer Name   | DeviceID | TotalSize(GB) | UsedSpace(GB) | FreeSpace(GB) | Usage(%)" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------------------"

foreach ($computer in $computers) {
    # Get disk space details
    $drives = Get-WmiObject Win32_LogicalDisk -ComputerName $computer -Filter "DriveType=3" | 
              Select-Object DeviceID, 
                            @{Name="TotalSizeGB"; Expression={[math]::Round(($_.Size / 1GB), 2) -as [double]}}, 
                            @{Name="UsedSpaceGB"; Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2) -as [double]}}, 
                            @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2) -as [double]}}, 
                            @{Name="Usage(%)"; Expression={if ($_.Size -gt 0) {[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)} else {"N/A"}}}

    # Print first line with server name
    $firstDrive = $true
    foreach ($drive in $drives) {
        if ($firstDrive) {
            Write-Host ("{0,-12} | {1,-8} | {2,-14} | {3,-14} | {4,-14} | {5,-8}" -f $computer, $drive.DeviceID, $drive.TotalSizeGB, $drive.UsedSpaceGB, $drive.FreeSpaceGB, $drive."Usage(%)") -ForegroundColor Cyan
            $firstDrive = $false
        } else {
            Write-Host ("{0,-12} | {1,-8} | {2,-14} | {3,-14} | {4,-14} | {5,-8}" -f "", $drive.DeviceID, $drive.TotalSizeGB, $drive.UsedSpaceGB, $drive.FreeSpaceGB, $drive."Usage(%)") -ForegroundColor Cyan
        }
    }
}
