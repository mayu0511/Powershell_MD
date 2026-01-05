# Example: match certificate by "Issued To" (Subject)
$IssuedTo = "DigiCert Global Root CA"   # <-- change this text

Get-ChildItem -Path Cert:\LocalMachine\Root |
Where-Object { $_.Subject -like "*$IssuedTo*" } |
Select-Object FriendlyName, Subject, NotBefore, NotAfter, Thumbprint, @{
    Name="DaysRemaining"
    Expression={ ($_.NotAfter - (Get-Date)).Days }
} |
Sort-Object DaysRemaining
