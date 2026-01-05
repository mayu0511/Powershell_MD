$displayName = "VisualCron"
$uninstallCommand = Get-WmiObject -Class Win32_Product | Where-Object {
    $_.Name -like "$displayName*"
} | Select-Object -ExpandProperty UninstallString

if ($uninstallCommand) {
    # Replace /I with /x and add /qn for silent uninstall
    $uninstallCommand = $uninstallCommand -replace "/I", "/x"
    $uninstallCommand += " /qn"

    Write-Host "Uninstalling VisualCron silently..." -ForegroundColor Cyan
    Start-Process "msiexec.exe" -ArgumentList $uninstallCommand -Wait -NoNewWindow
    Write-Host "VisualCron uninstalled successfully." -ForegroundColor Green
}
else {
    Write-Host "VisualCron is not installed." -ForegroundColor Red
}
