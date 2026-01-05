#Check certificates under LocalMachine\Root (Trusted Root Certification Authorities)
Get-ChildItem -Path Cert:\LocalMachine\Root |
Select-Object FriendlyName, Subject, NotBefore, NotAfter, Thumbprint, @{
    Name="DaysRemaining"
    Expression={( $_.NotAfter - (Get-Date) ).Days}
} |
Sort-Object DaysRemaining