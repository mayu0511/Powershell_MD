$data=Get-secsecretvalue -secretid uat2-mdw-pgp-secret-key

 

Write-host $data.SecretString

Write-host "Actual key length: $($data.SecretString.Length)"

Write-host "After trime: $($data.SecretString.Trim().Length)"