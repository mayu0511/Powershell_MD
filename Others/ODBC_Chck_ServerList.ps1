######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 31-Jan-2025
#=====================================================================================================================

$ServerListFile = "E:\Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 

$Result = @()

ForEach ($computername in $ServerList) {
    Write-Host $computername
    try {
        $session = New-PSSession -ComputerName $computername -SessionOption $option -ErrorAction Stop

        Invoke-Command -Session $session -ScriptBlock {
            # Define paths to check for ODBC drivers
            $odbcDrivers = @(
                @{ Name = "ODBC Driver 17 for SQL Server"; Path = "C:\\Windows\\System32\\msodbcsql17.dll" },
                @{ Name = "ODBC Driver 13 for SQL Server"; Path = "C:\\Windows\\System32\\msodbcsql13.dll" },
                @{ Name = "SQL Server Native Client 11.0"; Path = "C:\\Windows\\System32\\sqlncli11.dll" }
            )

            # Check for installed and missing ODBC drivers
            $driverStatus = [ordered]@{}
            foreach ($driver in $odbcDrivers) {
                # Check if the driver exists
                Write-Host "Checking path: $($driver.Path)"
                $driverExists = Test-Path -PathType Leaf $driver.Path
                Write-Host "$($driver.Name) exists: $driverExists"
                $driverStatus[$driver.Name] = if ($driverExists) { "Installed" } else { "Not Installed" }
            }

            # Return the status
            return [PSCustomObject]@{
                'Server Name'                        = $env:COMPUTERNAME
                'ODBC Driver 17 for SQL Server'      = $driverStatus["ODBC Driver 17 for SQL Server"]
                'ODBC Driver 13 for SQL Server'      = $driverStatus["ODBC Driver 13 for SQL Server"]
                'SQL Server Native Client 11.0'      = $driverStatus["SQL Server Native Client 11.0"]
            }
        } | ForEach-Object { $Result += $_ }

        Remove-PSSession -Session $session
    } catch {
        Write-Host "Failed to create session for $computername" -ForegroundColor Red
    }
}

# Generate HTML report
$HtmlFile = "C:\\ODBCDriversCheck.html"
$Result | ConvertTo-Html -Property 'Server Name', 'ODBC Driver 17 for SQL Server', 'ODBC Driver 13 for SQL Server', 'SQL Server Native Client 11.0' -Title 'ODBC Installation Status' | Out-File $HtmlFile
Start-Process $HtmlFile
