$SecretObj = (Get-SECSecretValue -SecretId DEV/app-rw-secret)
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$username = $Secret.username
#$username = "jayesh.dholi"
$pair = "$($username):"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encodedCredentials"
}
Invoke-RestMethod -Uri 'http://ccsvce1devb1:7011/MaintenanceSet?mode=0' -Headers $headers -Method Get