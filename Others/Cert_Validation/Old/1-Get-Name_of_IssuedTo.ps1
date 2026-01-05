# List Issued To, Issued By, and Expiration Date (clean CN format like MMC, sorted alphabetically by IssuedTo)

Get-ChildItem -Path Cert:\LocalMachine\Root | #Root
#Get-ChildItem -Path Cert:\LocalMachine\My |  #CurrentUser Personal (My) store
#Get-ChildItem -Path Cert:\LocalMachine\CA |   #LocalMachine Intermediate Certification Authorities

Select-Object @{Name="IssuedTo";Expression={ ($_.Subject -split ',')[0] -replace '^CN=', '' }},
              @{Name="IssuedBy";Expression={ ($_.Issuer -split ',')[0] -replace '^CN=', '' }},
              @{Name="ExpirationDate";Expression={ $_.NotAfter }} |
Sort-Object IssuedTo |
Format-Table -AutoSize
