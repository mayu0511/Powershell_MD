Import-Module ActiveDirectory
$ServiceAccountName = "ServiceAccountNameHere"
$ServiceAccount = Get-ADServiceAccount -Filter {Name -eq $ServiceAccountName} -Properties "PasswordLastSet"
$ServiceAccount.PasswordLastSet
 