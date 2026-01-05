# ================= Certificate Report =================
# Output HTML file with timestamp
$DateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$HtmlFilePath = "C:\Temp\CertificateReport_$DateTime.html"

# Collect certificates from Root store
$certs = Get-ChildItem -Path Cert:\LocalMachine\Root |  ## CurrentUser Root
#$certs = Get-ChildItem -Path Cert:\LocalMachine\CA |  ## CurrentUser Intermediate Certification Authorities
#$certs = Get-ChildItem -Path Cert:\LocalMachine\My |  # CurrentUser Personal (My) store

    Select-Object @{Name="IssuedTo";Expression={ ($_.Subject -split ',')[0] -replace '^CN=', '' }},
                  @{Name="IssuedBy";Expression={ ($_.Issuer -split ',')[0] -replace '^CN=', '' }},
                  @{Name="ExpirationDate";Expression={ $_.NotAfter }} |
    Sort-Object IssuedTo

# Convert to HTML with style
$HtmlReport = $certs | ConvertTo-Html -Property IssuedTo, IssuedBy, ExpirationDate `
    -Head "<style>
            body { font-family: Arial; font-size: 12px; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid black; padding: 6px; text-align: left; }
            th { background-color: #f2f2f2; }
           </style>" `
    -Title "Certificate Report"

# Save to file
$HtmlReport | Out-File $HtmlFilePath -Encoding UTF8

# Auto-open report
Invoke-Item $HtmlFilePath
