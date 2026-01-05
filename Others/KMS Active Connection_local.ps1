$ServerListFile = "E:\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

$results = @()  # Collect output here

foreach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    $logLines = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction SilentlyContinue -ScriptBlock {
        $folderPath = "E:\CoreCard\KMS\Service\Data"
        #$folderPath = "E:\Upload\Testing\KMS"

        # Get latest file based on LastWriteTime
        $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace*.txt" |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First 1

        if ($latestFile) {
            Get-Content -Path $latestFile.FullName -Tail 1000000 |
                #Where-Object { $_ -match "INFO Connection received from" }
                Where-Object { $_ -match "INFO Connection received from|Authenticated" }
        }
        else {
            "NO_LOG_FILE_FOUND"
        }
    }

    if ($logLines.Count -eq 0) {
        $results += [PSCustomObject]@{
            "Server Name"   = $computername
            "Status Output" = "NO_CONNECTION_FOUND"
            "StatusClass"   = "error"
        }
    }
    else {
        foreach ($line in $logLines) {
            $results += [PSCustomObject]@{
                "Server Name"   = $computername
                "Status Output" = $line
                "StatusClass"   = "ok"
            }
        }
    }
}

# Build custom HTML with inline CSS for color coding
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$htmlPath = "C:\temp\kmsactiveconnection-$timestamp.html"

# Build HTML manually for better control
$htmlHeader = @"
<html>
<head>
<title>KMS Active Connections</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
th { background-color: #333; color: white; }
tr.ok { background-color: #e6ffe6; }      /* Light green for matches */
tr.error { background-color: #ffe6e6; }   /* Light red for missing data */
</style>
</head>
<body>
<h2>KMS Active Connection Report - $timestamp</h2>
<table>
<tr><th>Server Name</th><th>Status Output</th></tr>
"@

$htmlRows = foreach ($row in $results) {
    "<tr class='$($row.StatusClass)'><td>$($row.'Server Name')</td><td>$($row.'Status Output')</td></tr>"
}

$htmlFooter = @"
</table>
</body>
</html>
"@

# Save HTML file
$htmlContent = $htmlHeader + ($htmlRows -join "`n") + $htmlFooter
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8

# Open report in browser
Start-Process $htmlPath
