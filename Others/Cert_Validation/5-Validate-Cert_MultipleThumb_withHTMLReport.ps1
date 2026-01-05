# Path to the text file containing the list of server names (one server per line).
$ServerListFile = "D:\BKP\Servers.txt"
try {
    $ServerList = Get-Content $ServerListFile -ErrorAction Stop
}
catch {
    Write-Host "Error: Could not find the server list file at '$ServerListFile'. Please check the path and try again." -ForegroundColor Red
    return
}

# List of valid thumbprints
$ExpectedThumbprints = @(
    "73E38D4A41B176351105FD6AE73E6F5A5A297B3F",
    "73E38D4A41B176351105FD85E73E6F5A5A297B3F",
    "73E38D4A41B176351107896AE73E6F5A5A297B3F",
    "73E38D4A41B17645105FD6AE73E6F5A5A297B3F"
)

$Results = @()

foreach ($computername in $ServerList) {
    Write-Host "Checking certificates on $computername ..." -ForegroundColor Cyan
    
    try {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer

        $certs = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            Get-ChildItem -Path "Cert:\LocalMachine\Root" |
            Where-Object { $using:ExpectedThumbprints -contains $_.Thumbprint } |
            Select-Object Subject, Thumbprint, NotAfter
        }

        if ($certs -and $certs.Count -gt 0) {
            foreach ($cert in $certs) {
                $status = if ($cert.NotAfter -lt (Get-Date)) { "❌ Expired" } else { "✔ Found" }
                $Results += [PSCustomObject]@{
                    Server     = $computername
                    Thumbprint = $cert.Thumbprint
                    Expiry     = $cert.NotAfter
                    Status     = $status
                }
            }
        } else {
            $Results += [PSCustomObject]@{
                Server     = $computername
                Thumbprint = ($ExpectedThumbprints -join ", ")
                Expiry     = ""
                Status     = "✖ Not Found"
            }
        }
    }
    catch {
        $Results += [PSCustomObject]@{
            Server     = $computername
            Thumbprint = ($ExpectedThumbprints -join ", ")
            Expiry     = ""
            Status     = "⚠ Error: $($_.Exception.Message)"
        }
    }
}

# --- Export results to HTML (preserve order from Servers.txt) ---
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HtmlFilePath = "C:\Temp\CertificateExpiryReport_$TimeStamp.html"

$Results | ConvertTo-Html -Property Server,Thumbprint,Expiry,Status -Head "
<style>
    body { font-family: Arial; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #0078D7; color: white; }
    tr:nth-child(even) { background-color: #f2f2f2; }
</style>
" -Title "Certificate Validation Report - $TimeStamp" |
Out-File -FilePath $HtmlFilePath -Encoding UTF8

Write-Host "Validation complete. HTML report saved to $HtmlFilePath" -ForegroundColor Green

# --- Auto-open the report ---
Invoke-Item $HtmlFilePath

