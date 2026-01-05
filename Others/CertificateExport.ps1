######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================
$website = "coreissue-blue.qa.api.cc-pod2.infra.marcus.com"
$outputPath = "D:\exported_certificate1.cer"
 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$tcpClient = New-Object System.Net.Sockets.TcpClient
$tcpClient.Connect($website, 443)
$sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, { return $true })
$sslStream.AuthenticateAsClient($website, $null, [System.Security.Authentication.SslProtocols]::Tls12, $false)
 
$cert = $sslStream.RemoteCertificate
 
if ($cert) {
    $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
    $base64Cert = [Convert]::ToBase64String($cert2.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
    $base64CertLines = $base64Cert -split "(.{64})" | Where-Object { $_ -ne "" }
    $formattedCert = "-----BEGIN CERTIFICATE-----`n$($base64CertLines -join "`n")`n-----END CERTIFICATE-----"
    Set-Content -Path $outputPath -Value $formattedCert -Encoding ASCII
 
    Write-Host "Certificate exported to $outputPath in Base-64 format"
} else {
    Write-Host "No certificate found."
}
 
$sslStream.Close()
$tcpClient.Close()