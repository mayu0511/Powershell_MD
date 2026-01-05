######################################################################################################################
# VisualCron Service Install | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 11-April-2025
#=====================================================================================================================

$ServerListFile = "D:\CC_Scripts\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop
$logPath = "D:\CC_Scripts\VisualCron_InstallLog.txt"

foreach ($computerName in $ServerList) {
    Write-Host "Connecting to $computerName..." -ForegroundColor Yellow
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    try {
        Invoke-Command -ComputerName $computerName -SessionOption $option -ErrorAction Stop -ScriptBlock {
            $msiPath = "C:\Temp\VisualCron.msi"

            if (-not (Test-Path $msiPath)) {
                Write-Host "❌ MSI not found at $msiPath" -ForegroundColor Red
                return
            }

            Write-Host "✅ Installing VisualCron silently via MSI..." -ForegroundColor Cyan
            Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow

            # Optional short wait in case service hasn't registered yet
            Start-Sleep -Seconds 5

            # Start and configure VisualCron service
            Start-Service -Name "VisualCron" -ErrorAction SilentlyContinue
            Set-Service -Name "VisualCron" -StartupType Automatic

            Write-Host "✔ VisualCron installed and service configured!" -ForegroundColor Green
        }

        Add-Content -Path $logPath -Value "$(Get-Date) - SUCCESS - $computerName"

    } catch {
        Write-Host "❌ Failed to install on $computerName $_" -ForegroundColor Red
        Add-Content -Path $logPath -Value "$(Get-Date) - FAIL - $computerName - $_"
    }
}


#$sourceMsi = "D:\CC_Scripts\VisualCron12.1.3.msi"
#$destMsi = "\\$computerName\C$\Temp\VisualCron.msi"
#Copy-Item -Path $sourceMsi -Destination $destMsi -Force
