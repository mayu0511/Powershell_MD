#-------------one liner Decryption command-------------

[System.Net.NetworkCredential]::new("", (ConvertTo-SecureString $Encryptedplat -Key (Get-Content "C:\Temp\aes.key"))).Password
[System.Net.NetworkCredential]::new("", (ConvertTo-SecureString $EncryptedCoreCard -Key (Get-Content "C:\Temp\aes.key"))).Password

#------KMS "plat" key Encryption---------

$key = Get-Content C:\Temp\aes.key
ConvertFrom-SecureString `
    ("plat" | ConvertTo-SecureString -AsPlainText -Force) `
    -Key $key

#------KMS "corecard" key Encryption---------
    $key = Get-Content C:\Temp\aes.key
ConvertFrom-SecureString `
    ("corecard" | ConvertTo-SecureString -AsPlainText -Force) `
    -Key $key


    #------KMS "plat" key Decryption---------
    $AESKey = Get-Content "C:\Temp\aes.key"

$EncryptedPlat = "76492d1116743f0423413b16050a5345MgB8AFUAZwBlAHgAMwBFAFYAYgBpAFAAMwB1AE0AWQBSACsANgBWAG8ARQBLAFEAPQA9AHwANAA5ADAAOABhADUANwAwADQAOAAzADEAMAAwADcANwAzAGIANwAzADEANABjADYANwBkAGEAOQAyAGIANAAxAA=="

$SecurePlat = ConvertTo-SecureString $EncryptedPlat -Key $AESKey
$PlainPlat = [System.Net.NetworkCredential]::new("", $SecurePlat).Password

$PlainPlat

#------KMS "corecard" key Decryption---------

$AESKey = Get-Content "C:\Temp\aes.key"

$EncryptedCoreCard = "76492d1116743f0423413b16050a5345MgB8ADUASABVAFoAdABaADgAVwA5AEIATgBtAGMARABUADUAUABuAGkAbAB5AGcAPQA9AHwAMQA1AGMAYQA4AGUAOQA3ADgAMwBkADIAYgA2AGUAMABiADkAMQA0AGQAMwAyADkAMQA2AGYAMwAzADMANwA0AGUAYQBhADUAZQAxADAAYgA2AD
UAOAA5ADMAYQAyADQAOQBmADcAMgBkADUANgAwAGMAMQAxAGEAYQBjADUANQA="

$SecureCore = ConvertTo-SecureString $EncryptedCoreCard -Key $AESKey
$PlainCore = [System.Net.NetworkCredential]::new("", $SecureCore).Password

$PlainCore