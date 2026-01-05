$ServerListFile = "E:\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

$results = @()

foreach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

    $activeConnections = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
        $folderPath = "E:\CoreCard\KMS\Service\Data"

        $today = (Get-Date).ToString("yyyy-MM-dd")

        # First try to get today's file by name
        $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace$today*.txt" |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -ExpandProperty FullName -First 1

        # Fallback to most recent file if today's not found
        if (-not $latestFile) {
            $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace*.txt" |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -ExpandProperty FullName -First 1
        }

        if (-not $latestFile) { return @() }

        $logLines = Get-Content -Path $latestFile -Tail 150

        $connections = foreach ($line in $logLines) {
            if ($line -match "^(?<timestamp>\S+\s+\S+).*INFO Connection received from (?<ip>\d+\.\d+\.\d+\.\d+)") {
                [PSCustomObject]@{ Timestamp = [datetime]$matches['timestamp']; IP = $matches['ip'] }
            }
        }

        $disconnections = foreach ($line in $logLines) {
            if ($line -match "disconnected (?<ip>\d+\.\d+\.\d+\.\d+)") { $matches['ip'] }
        }

        $connections | Where-Object { $disconnections -notcontains $_.IP }
    }

    foreach ($conn in $activeConnections) {
        try { $hostName = ([System.Net.Dns]::GetHostEntry($conn.IP)).HostName }
        catch { $hostName = $conn.IP }

        $results += [PSCustomObject]@{
            "Server Name"     = $computername
            "Host Name"       = $hostName
            "IP"              = $conn.IP
            "User ID"         = "gmsa-app-svc$"
            "Connection Date" = $conn.Timestamp.ToString("MM/dd/yyyy HH:mm:ss")
        }
    }
}

# --- Build HTML Report ---
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$htmlRows = foreach ($row in $results) {
    "<tr>
        <td>$($row.'Server Name')</td>
        <td>$($row.'Host Name')</td>
        <td>$($row.IP)</td>
        <td><b>$($row.'User ID')</b></td>
        <td>$($row.'Connection Date')</td>
        <td><input type='checkbox'> Disconnect</td>
    </tr>"
}

$htmlContent = @"
<html>
<head>
<title>Active Client Connections</title>
<style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 100%; margin-top: 10px; }
th, td { border: 1px solid black; padding: 5px; text-align: left; }
th { background-color: #f2f2f2; }
tr:nth-child(even) { background-color: #f9f9f9; }
</style>
</head>
<body>
<h2>Snapshot of Client Connections</h2>
<table>
<tr><th>Server Name</th><th>Host Name</th><th>IP</th><th>User ID</th><th>Connection Date</th><th>Disconnect?</th></tr>
$htmlRows
</table>
<p>Generated at $timestamp</p>
</body>
</html>
"@

$outputFile = "C:\temp\ActiveClientConnections_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$htmlContent | Out-File -FilePath $outputFile -Encoding UTF8
Start-Process $outputFile
