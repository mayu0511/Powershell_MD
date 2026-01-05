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

        $driverStatus = Invoke-Command -Session $session -ScriptBlock {
            # Define paths to check for ODBC drivers
            $odbcDrivers = @(
                @{ Name = "ODBC Driver 17 for SQL Server"; Path = "C:\\Windows\\System32\\msodbcsql17.dll" },
                @{ Name = "ODBC Driver 13 for SQL Server"; Path = "C:\\Windows\\System32\\msodbcsql13.dll" },
                @{ Name = "SQL Server Native Client 11.0"; Path = "C:\\Windows\\System32\\sqlncli11.dll" }
            )

            # Check for installed and missing ODBC drivers
            $driverStatus = [ordered]@{}
            foreach ($driver in $odbcDrivers) {
                $driverExists = Test-Path -PathType Leaf $driver.Path
                $driverStatus[$driver.Name] = if ($driverExists) { "Installed" } else { "Not Installed" }
            }

            return [PSCustomObject]@{
                'Server Name'                        = $env:COMPUTERNAME
                'ODBC Driver 17 for SQL Server'      = $driverStatus["ODBC Driver 17 for SQL Server"]
                'ODBC Driver 13 for SQL Server'      = $driverStatus["ODBC Driver 13 for SQL Server"]
                'SQL Server Native Client 11.0'      = $driverStatus["SQL Server Native Client 11.0"]
            }
        }

        $Result += $driverStatus
        Remove-PSSession -Session $session
    } catch {
        Write-Host "Failed to create session for $computername" -ForegroundColor Red
    }
}

# Generate HTML report with color coding
$HtmlFile = "C:\\ODBCDriversCheck.html"

$HtmlHeader = @"
<html>
<head>
    <title>ODBC Installation Status</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .server { color: blue; font-weight: bold; }
        .installed { color: green; font-weight: bold; }
        .not-installed { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h2>ODBC Installation Status</h2>
    <table>
        <tr>
            <th>Server Name</th>
            <th>ODBC Driver 17 for SQL Server</th>
            <th>ODBC Driver 13 for SQL Server</th>
            <th>SQL Server Native Client 11.0</th>
        </tr>
"@

$HtmlBody = ""

foreach ($item in $Result) {
    $HtmlBody += "<tr>"
    $HtmlBody += "<td class='server'>$($item.'Server Name')</td>"
    
    foreach ($driver in ('ODBC Driver 17 for SQL Server', 'ODBC Driver 13 for SQL Server', 'SQL Server Native Client 11.0')) {
        $statusClass = if ($item.$driver -eq "Installed") { "installed" } else { "not-installed" }
        $HtmlBody += "<td class='$statusClass'>$($item.$driver)</td>"
    }

    $HtmlBody += "</tr>"
}

$HtmlFooter = "</table></body></html>"

$FullHtml = $HtmlHeader + $HtmlBody + $HtmlFooter
$FullHtml | Out-File $HtmlFile

Start-Process $HtmlFile
