$Username = "username"
$User = Get-ADUser -Filter {SamAccountName -eq $Username} -Properties "DisplayName", "PasswordLastSet"
$User.PasswordLastSet