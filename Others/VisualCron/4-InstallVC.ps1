######################################################################################################################
# VisualCron Service Install | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 11-April-2025
#=====================================================================================================================


# Path to extracted MSI
$msiPath = "C:\Users\mahendra.dwivedi\Downloads\VisualCron11.2.3\VisualCron.msi"

if (Test-Path $msiPath) {
    Write-Host "Installing VisualCron silently via MSI..." -ForegroundColor Cyan

    # Perform silent MSI install
    Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow

    Write-Host "VisualCron installed silently via MSI." -ForegroundColor Green
}
else {
    Write-Host "MSI not found at: $msiPath" -ForegroundColor Red
}

#Start-Service -Name "VisualCron"
#Set-Service -Name "VisualCron" -StartupType Automatic



