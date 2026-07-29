# Output file
$OutputFile = "C:\Temp\Installed_Applications_Report.csv"

$apps = @()

# Function to read installed applications from registry
function Get-InstalledApps {
    param([string]$RegistryPath)

    if (Test-Path $RegistryPath) {
        Get-ChildItem $RegistryPath | ForEach-Object {
            $item = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue

            if ($item.DisplayName) {
                [PSCustomObject]@{
                    Name            = $item.DisplayName
                    Version         = $item.DisplayVersion
                    Publisher       = $item.Publisher
                    InstallDate     = $item.InstallDate
                    InstallLocation = $item.InstallLocation
                }
            }
        }
    }
}

# 64-bit applications
$apps += Get-InstalledApps "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

# 32-bit applications
$apps += Get-InstalledApps "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

# Current user applications
$apps += Get-InstalledApps "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

# Remove duplicates and sort
$apps = $apps | Sort-Object Name -Unique

# Export
$apps | Export-Csv $OutputFile -NoTypeInformation

Write-Host ""
Write-Host "Report saved to $OutputFile" -ForegroundColor Green

# Display on screen
$apps | Format-Table Name, Version, Publisher -AutoSize