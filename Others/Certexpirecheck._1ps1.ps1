######################################################################################################################
# Certificate Check | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

# Import the WebAdministration module
Import-Module WebAdministration

# Get the list of IIS sites
$sites = Get-ChildItem IIS:\Sites

# Iterate through each site and check the SSL certificate expiration date
foreach ($site in $sites) {
    $siteName = $site.Name
    $bindings = $site.bindings.Collection

    foreach ($binding in $bindings) {
        $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $binding.CertificateHash }

        if ($cert) {
            $expirationDate = $cert.NotAfter
            Write-Host "Site: $siteName, Binding: $($binding.BindingInformation), Certificate Expiration Date: $expirationDate"
        }
    }
}
