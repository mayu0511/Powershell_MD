$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet' | Where-Object {$_.Preferred -eq 'True'}).IPAddress
Write-Host "IPv4 Address: $ipAddress"
(Get-NetIPAddress).IPAddress -and 'internetface'

$localIPAddress = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
Write-Host "Local IPv4 Address: $localIPAddress"

