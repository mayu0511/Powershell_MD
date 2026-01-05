$ServerListFile = "E:\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

$results = @()  # Collect output here

foreach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    $logLines = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction SilentlyContinue -ScriptBlock {
        $folderPath = "E:\CoreCard\KMS\Service\Data"
        $today = (Get-Date).ToString("yyyy-MM-dd")

        # --- Try today's file first ---
        $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace$today*.txt" |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First 1

        # --- Fallback to latest if today's file doesn't exist ---
        if (-not $latestFile) {
            $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace*.txt" |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First 1
        }

        if ($latestFile) {
            Get-Content -Path $latestFile.FullName -Tail 1000 |
                Where-Object { $_ -match "INFO Connection received from|Starting as a service|Authenticated|on address https://localhost:8081|GC about to start|GC done|Error Code|decrypt failed|Service Stop" }
        }
        else {
            "NO_LOG_FILE_FOUND"
        }
    }

    if ($logLines.Count -eq 0 -or $logLines -contains "NO_LOG_FILE_FOUND") {
        $results += [PSCustomObject]@{
            "Server Name"   = $computername
            "Status Output" = "NO_CONNECTION_FOUND"
            "StatusClass"   = "error"
        }
    }
    else {
        foreach ($line in $logLines) {
            $statusClass = "ok"

            # Mark these as red
            if ($line -match "Error Code|decrypt failed|Service Stop") {
                $statusClass = "error"
            }

            $results += [PSCustomObject]@{
                "Server Name"   = $computername
                "Status Output" = $line
                "StatusClass"   = $statusClass
            }
        }
    }
}

# --- Build HTML report ---
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$htmlPath = "C:\temp\kmsactiveconnection-$timestamp.html"

$htmlHeader = @"
<html>
<head>
<title>KMS Active Connections</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
th { background-color: #333; color: white; }
tr.ok { background-color: #e6ffe6; }      /* Light green for normal */
tr.error { background-color: #ffe6e6; }   /* Light red for Error Code / decrypt failed / Service Stop */
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

# Save and open HTML report
$htmlContent = $htmlHeader + ($htmlRows -join "`n") + $htmlFooter
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Start-Process $htmlPath
