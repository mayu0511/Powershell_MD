Clear-Variable response

 Import-Module -Name WebAdministration
  $IP = (Get-WebBinding "Services" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
  #$IP = (Get-WebBinding "CoreIssue" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
  $IP = $IP.Substring(0,$IP.Length-5)
  class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
    [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                 [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                 [System.Net.WebRequest] $c,
                                 [int] $d) {
        return $true
    }
}
[System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  
  $response = Invoke-WebRequest -Uri "https://$IP/HealthServiceApp/api/server/maintenance/1" -Method GET -UseDefaultCredentials
  #$response = Invoke-WebRequest -Uri "https://$IP/HealthCoreIssueApp/api/server/maintenance/1" -Method GET -UseDefaultCredentials
  if ($response.StatusCode -eq 200) {
  Write-Output "Disabled"
  } else {
  Write-Output "Failed" }
