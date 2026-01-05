######################################################################################################################
# Certificate CHEKC | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

# Specify the URL of the website whose SSL certificate you want to check
$websiteUrl = "https://example.com"

# Get the SSL certificate from the website
$certificate = (Invoke-WebRequest -Uri $websiteUrl).Certificate

# Calculate the number of days until the certificate expires
$daysUntilExpiration = ($certificate.NotAfter - (Get-Date)).Days

# Check if the certificate expires in less than 7 days
if ($daysUntilExpiration < 7) {
    Write-Host "Error: SSL certificate will expire in $daysUntilExpiration days."
} else {
    Write-Host "Success: SSL certificate is valid for $daysUntilExpiration days."
}
