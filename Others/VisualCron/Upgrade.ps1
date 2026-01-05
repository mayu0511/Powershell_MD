$msiPath = "C:\Users\mahendra.dwivedi\Downloads\VisualCron12.1.3\12.1.3\VisualCron.msi"

# Step 1: Uninstall old version (if found)
$vcUninstallKey = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
                                "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
    Get-ItemProperty |
    Where-Object { $_.DisplayName -like "VisualCron*" } |
    Select-Object -First 1

if ($vcUninstallKey) {
    $uninstallString = $vcUninstallKey.UninstallString
    if ($uninstallString -match "msiexec") {
        $uninstallArgs = $uninstallString -replace "/I", "/x" + " /qn /norestart"
        Write-Host "Uninstalling VisualCron $($vcUninstallKey.DisplayVersion)..." -ForegroundColor Yellow
        Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallArgs -Wait -NoNewWindow
        Start-Sleep -Seconds 5
    }
    else {
        Write-Host "Uninstall string found, but format not supported." -ForegroundColor Red
        Write-Output $uninstallString
        exit
    }
}
else {
    Write-Host "No existing VisualCron installation found. Continuing with install..." -ForegroundColor Cyan
}

# Step 2: Install the new version
if (Test-Path $msiPath) {
    Write-Host "Installing VisualCron 12.1.3 silently..." -ForegroundColor Cyan
    Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
    Write-Host "✔ VisualCron 12.1.3 installed successfully." -ForegroundColor Green
}
else {
    Write-Host "❌ MSI not found at: $msiPath" -ForegroundColor Red
}
