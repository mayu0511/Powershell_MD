# Define Server List
$ServerListFile = "E:\Servers.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction Stop 

# Print table header once
Write-Host "`nServer Name   | DeviceID | TotalSize(GB) | UsedSpace(GB) | FreeSpace(GB) | Usage(%)" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------------------"

ForEach ($computername in $ServerList) {
    try {
        Invoke-Command -ComputerName $computername -ErrorAction Stop -ScriptBlock {
            param ($computer)

            # Get Disk Details (Using Get-CimInstance instead of Get-WmiObject)
            $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | 
                      Select-Object DeviceID, 
                                    @{Name="TotalSizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                                    @{Name="UsedSpaceGB"; Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}}, 
                                    @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, 
                                    @{Name="Usage(%)"; Expression={if ($_.Size -gt 0) {[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)} else {"N/A"}}}

            # Display results
            $firstDrive = $true
            foreach ($drive in $drives) {
                $line = if ($firstDrive) {
                    "{0,-12} | {1,-8} | {2,-14} | {3,-14} | {4,-14} | {5,-8}" -f $computer, $drive.DeviceID, $drive.TotalSizeGB, $drive.UsedSpaceGB, $drive.FreeSpaceGB, $drive."Usage(%)"
                } else {
                    "{0,-12} | {1,-8} | {2,-14} | {3,-14} | {4,-14} | {5,-8}" -f "", $drive.DeviceID, $drive.TotalSizeGB, $drive.UsedSpaceGB, $drive.FreeSpaceGB, $drive."Usage(%)"
                }
                Write-Host $line -ForegroundColor Cyan
                $firstDrive = $false
            }
        } -ArgumentList $computername
    }
    catch {
        Write-Host "Error: Unable to connect to $computername - $_" -ForegroundColor Red
    }
}
