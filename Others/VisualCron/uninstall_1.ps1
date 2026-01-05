# Search both 64-bit and 32-bit uninstall paths
$paths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$vcUninstall = $null

foreach ($path in $paths) {
    $vcUninstall = Get-ChildItem -Path $path |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -like "VisualCron*" }

    if ($vcUninstall) { break }
}

if ($vcUninstall) {
    $uninstallString = $vcUninstall.UninstallString

    if ($uninstallString -match "msiexec") {
        # Convert to silent uninstall
        $silentUninstall = $uninstallString -replace "/I", "/x" + " /qn"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $silentUninstall -Wait -NoNewWindow
        Write-Host "VisualCron uninstalled silently via MSI." -ForegroundColor Green
    }
    elseif ($uninstallString -like "*.exe*") {
        # Run EXE uninstall silently if supported
        Start-Process -FilePath $uninstallString -ArgumentList "/S" -Wait -NoNewWindow
        Write-Host "VisualCron uninstalled silently via EXE." -ForegroundColor Green
    }
    else {
        Write-Host "Uninstall string found but format not recognized." -ForegroundColor Yellow
        Write-Output $uninstallString
    }
}
else {
    Write-Host "VisualCron is not found in the registry." -ForegroundColor Red
}
