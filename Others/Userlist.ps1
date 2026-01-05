Import-Module ActiveDirectory
$Users = Get-ADUser -Filter * -Properties DisplayName, SamAccountName
$Users | Select-Object DisplayName, SamAccountName | Format-Table -AutoSize
