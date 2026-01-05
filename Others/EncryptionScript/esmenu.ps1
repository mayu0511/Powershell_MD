# Environment Detection
$Domain = $env:USERDOMAIN

$environmentMessage = switch -Regex ($Domain) {
    "cc-pod2-patqa" { "You are in COOKIE POD2 PATQA Environment" }
    "cc-pod2-patuat" { "You are in COOKIE POD2 PATUAT Environment" }
    "cc-pod2-perf" { "You are in COOKIE POD2 PERF Environment" }
    "cc-pod2-qa" { "You are in COOKIE POD2 QA Environment" }
    "cc-pod2-dev" { "You are in COOKIE POD2 DEV Environment" }
    "cc-pod2-uat" { "You are in COOKIE POD2 UAT Environment" }
    "cc-pod2-prod" { "You are in COOKIE POD2 PROD Environment" }
    "cc-pod4-prod" { "You are in COOKIE POD4 PROD Environment" }
    "cc-jazz-uat2" { "You are in JAZZ UAT2 Environment" }
    "cc-jazz-qa" { "You are in JAZZ QA Environment" }
    "cc-jazz-dev" { "You are in JAZZ DEV Environment" }
    "cc-jazz-prod" { "You are in JAZZ PROD Environment" }
    default { "Environment does not match" }
}

# Global Variables
$path = "C:\temp\EncryptionScript"
$keyFile = "$path\keys.key"
$userPasswordFile = "$path\userpasswords.xml"

# Ensure script directory exists
if (-Not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force }

# Function to generate/load encryption key
function Get-EncryptionKey {
    if (-Not (Test-Path $keyFile)) {
        [Byte[]]$RKey = 1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }
        [System.IO.File]::WriteAllBytes($keyFile, $RKey)   # Correct way to write binary data
    }
    return [System.IO.File]::ReadAllBytes($keyFile)  # Correct way to read binary data
}

# Function to load user-password table
function Get-UserPasswordTable {
    if (Test-Path $userPasswordFile) {
        return Import-Clixml $userPasswordFile
    } else {
        return @{ }
    }
}

# Function to save user-password table
function Save-UserPasswordTable ($table) {
    $table | Export-Clixml -Path $userPasswordFile
}

# Encrypt and store passwords
function Script1 {
    Clear-Host
    Write-Host "_____________________Encrypt and Store Passwords_____________________" -ForegroundColor Yellow
    $key = Get-EncryptionKey
    $UserPasswordTable = Get-UserPasswordTable

    while ($true) {
        $Username = Read-Host "Enter Username (or type 'exit' to finish)"
        if ($Username -eq 'exit') { break }

        if ($UserPasswordTable.ContainsKey($Username)) {
            Write-Host "User $Username already exists. Try another username."
        } else {
            $Password = Read-Host "Enter password for $Username" -AsSecureString
            $Description = Read-Host "Enter description for $Username"
            $UserPasswordTable[$Username] = @{
                Password = ConvertFrom-SecureString -SecureString $Password -Key $key
                Description = $Description
            }
            Write-Host "User $Username added successfully." -ForegroundColor Cyan
        }
    }
    Save-UserPasswordTable $UserPasswordTable
    Write-Host "All usernames and passwords stored securely." -ForegroundColor Cyan
}

# Retrieve password
function Script2 {
    Clear-Host
    Write-Host "_____________________Retrieve Password for a User_____________________" -ForegroundColor Yellow
    $key = Get-EncryptionKey
    $UserPasswordTable = Get-UserPasswordTable

    $Username = Read-Host "Enter the username"
    if ($UserPasswordTable.ContainsKey($Username)) {
        $DecryptedPassword = ConvertTo-SecureString -String $UserPasswordTable[$Username].Password -Key $key
        $PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DecryptedPassword))
        $Description = $UserPasswordTable[$Username].Description

        Write-Host "Password for '$Username': $PlainTextPassword" -ForegroundColor Yellow
        Write-Host "Description: $Description" -ForegroundColor Green
    } else {
        Write-Host "Username '$Username' not found." -ForegroundColor Red
    }
}

# Update password
function Script3 {
    Clear-Host
    Write-Host "_____________________Update Password for a User_____________________" -ForegroundColor Yellow
    $key = Get-EncryptionKey
    $UserPasswordTable = Get-UserPasswordTable

    $Username = Read-Host "Enter the username to update"
    if ($UserPasswordTable.ContainsKey($Username)) {
        $NewPassword = Read-Host "Enter new password for $Username" -AsSecureString
        $NewDescription = Read-Host "Enter new description for $Username"
        $UserPasswordTable[$Username] = @{
            Password = ConvertFrom-SecureString -SecureString $NewPassword -Key $key
            Description = $NewDescription
        }
        Save-UserPasswordTable $UserPasswordTable
        Write-Host "Password for '$Username' updated successfully." -ForegroundColor Cyan
    } else {
        Write-Host "Username '$Username' not found." -ForegroundColor Red
    }
}

# Update Username
function Script4 {
    Clear-Host
    Write-Host "_____________________Update Username_____________________" -ForegroundColor Yellow
    $key = Get-EncryptionKey
    $UserPasswordTable = Get-UserPasswordTable

    $OldUsername = Read-Host "Enter the current username"
    if ($UserPasswordTable.ContainsKey($OldUsername)) {
        $NewUsername = Read-Host "Enter the new username"
        if ($UserPasswordTable.ContainsKey($NewUsername)) {
            Write-Host "Username '$NewUsername' already exists. Try another username." -ForegroundColor Red
        } else {
            $UserPasswordTable[$NewUsername] = $UserPasswordTable[$OldUsername]
            $UserPasswordTable.Remove($OldUsername)
            Save-UserPasswordTable $UserPasswordTable
            Write-Host "Username updated from '$OldUsername' to '$NewUsername' successfully." -ForegroundColor Cyan
        }
    } else {
        Write-Host "Username '$OldUsername' not found." -ForegroundColor Red
    }
}



# List all users and passwords
function Script5 {
    Clear-Host
    Write-Host "___________________List All Users and Passwords___________________" -ForegroundColor Yellow
    $key = Get-EncryptionKey
    $UserPasswordTable = Get-UserPasswordTable

    $formatString = "{0,-30} {1,-30} {2,-30}"
    Write-Host ($formatString -f "Username", "Password", "Description") -ForegroundColor Cyan
    Write-Host ("-" * 90)

    foreach ($Username in ($UserPasswordTable.GetEnumerator() | Sort-Object { $_.Value.Description })) {
        $entry = $UserPasswordTable[$Username.Key]
        if ($entry.Password -and $entry.Description) {
            $DecryptedPassword = ConvertTo-SecureString -String $entry.Password -Key $key
            $PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DecryptedPassword))
            $Description = $entry.Description

            Write-Host ($formatString -f $Username.Key, $PlainTextPassword, $Description) -ForegroundColor Yellow
        } else {
            Write-Host ($formatString -f $Username.Key, "N/A", "N/A") -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host ""
    Write-Host "_________________________________________________________________"
    Start-Sleep -Seconds 30
    Clear-Host
}

# Delete User
function Script6 {
    Clear-Host
    Write-Host "_____________________Delete User_____________________" -ForegroundColor Yellow
    $UserPasswordTable = Get-UserPasswordTable

    if ($UserPasswordTable.Count -eq 0) {
        Write-Host "No users found to delete." -ForegroundColor Red
        return
    }

    $Username = Read-Host "Enter the username to delete"
    if ($UserPasswordTable.ContainsKey($Username)) {
        $confirmation = Read-Host "Are you sure you want to delete '$Username'? (yes/no)"
        if ($confirmation -eq "yes") {
            $UserPasswordTable.Remove($Username)
            Save-UserPasswordTable $UserPasswordTable
            Write-Host "User '$Username' deleted successfully." -ForegroundColor Cyan
        } else {
            Write-Host "Operation canceled." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Username '$Username' not found." -ForegroundColor Red
    }
}
# Function to display menu
function Show-Menu {
    Clear-Host
    Write-Host "==================================================================="

    Write-Host $environmentMessage -ForegroundColor Yellow

    Write-Host "==================================================================="
    Write-Host "PowerShell Utility for Secure Password Storage and Retrieval"
    Write-Host "==================================================================="
    Write-Host "1. Encrypt and Store Passwords"
    Write-Host "2. Retrieve Password for a User"
    Write-Host "3. Update Password for a User"
    Write-Host "4. Update Username"
    Write-Host "5. List All Users and Passwords"
    Write-Host "6. Delete User"
    Write-Host "0. Exit"
    Write-Host "==================================================================="
}

# Menu Loop
# Menu Loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-6) and Zero to Exit"
    switch ($choice) {
        "1" { Script1; Read-Host "Press Enter to continue..." }
        "2" { Script2; Read-Host "Press Enter to continue..." }
        "3" { Script3; Read-Host "Press Enter to continue..." }
        "4" { Script4; Read-Host "Press Enter to continue..." }
        "5" { Script5; Read-Host "Press Enter to continue..." }
        "6" { Script6; Read-Host "Press Enter to continue..." }
        "0" { Write-Host "Exiting program. Goodbye!" -ForegroundColor Green; break }
        default { Write-Host "Invalid choice. Please select a valid option (0-6)." -ForegroundColor Red }
    }
}
