$ServerListFile = "D:\BKP\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop
######################################################################################################################
# IIS SSL Certificate Check | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.2 | Remote Server Report in HTML | Date:: 18-Aug-2025
#=====================================================================================================================

$Results = @()

foreach ($computername in $ServerList) {
    try {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer
        $ServerResult = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            Import-Module WebAdministration -ErrorAction Stop
            $sites = Get-ChildItem IIS:\Sites
            $out = @()
            foreach ($site in $sites) {
                foreach ($binding in $site.bindings.Collection) {
                    if ($binding.CertificateHash) {
                        $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $binding.CertificateHash }
                        if ($cert) {
                            $out += [PSCustomObject]@{
                                SiteName       = $site.Name
                                Binding        = $binding.BindingInformation
                                IssuedTo       = ($cert.Subject -split ',')[0] -replace '^CN=', ''
                                IssuedBy       = ($cert.Issuer -split ',')[0] -replace '^CN=', ''
                                ExpirationDate = $cert.NotAfter.ToString("yyyy-MM-dd HH:mm:ss")
                                DaysRemaining  = (New-TimeSpan -Start (Get-Date) -End $cert.NotAfter).Days
                            }
                        }
                    }
                }
            }
            return $out
        }
        
        foreach ($row in $ServerResult) {
            $Results += [PSCustomObject]@{
                ServerName     = $computername
                SiteName       = $row.SiteName
                Binding        = $row.Binding
                IssuedTo       = $row.IssuedTo
                IssuedBy       = $row.IssuedBy
                ExpirationDate = $row.ExpirationDate
                DaysRemaining  = $row.DaysRemaining
            }
        }

    } catch {
        $Results += [PSCustomObject]@{
            ServerName     = $computername
            SiteName       = "-"
            Binding        = "-"
            IssuedTo       = "-"
            IssuedBy       = "-"
            ExpirationDate = "-"
            DaysRemaining  = "Error: $_"
        }
    }
}

# Create timestamped report
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = "D:\BKP\IISCertReport_$TimeStamp.html"

# HTML Styling
$Head = @"
<style>
    body { font-family: Arial; }
    h2 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin-top: 10px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #4CAF50; color: white; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .expired { background-color: #ffcccc; }
    .warning { background-color: #fff3cd; }
    .ok { background-color: #d4edda; }
</style>
"@

$ReportHeader = "<h2>IIS SSL Certificate Expiration Report</h2><p>Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>"

# Convert to HTML rows
$Html = $Results | Sort-Object ServerName,SiteName |
    ForEach-Object {
        $class = if ($_.DaysRemaining -is [int]) {
                    if ($_.DaysRemaining -lt 0) { "expired" }
                    elseif ($_.DaysRemaining -lt 30) { "warning" }
                    else { "ok" }
                 } else { "" }

        "<tr class='$class'><td>$($_.ServerName)</td><td>$($_.SiteName)</td><td>$($_.Binding)</td><td>$($_.IssuedTo)</td><td>$($_.IssuedBy)</td><td>$($_.ExpirationDate)</td><td>$($_.DaysRemaining)</td></tr>"
    }

$Table = @"
<table>
<tr>
<th>Server Name</th><th>Site Name</th><th>Binding</th><th>Issued To</th><th>Issued By</th><th>Expiration Date</th><th>Days Remaining</th>
</tr>
$Html
</table>
"@

# Save report
$Report = ConvertTo-Html -Head $Head -Title "IIS SSL Certificate Expiration Report" -Body "$ReportHeader $Table"
$Report | Out-File $ReportFile -Encoding UTF8

Invoke-Item $ReportFile
Write-Host "Report generated: $ReportFile"
