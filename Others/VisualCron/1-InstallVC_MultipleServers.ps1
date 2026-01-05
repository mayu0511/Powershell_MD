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
            $msiPath = "C:\Temp\VisualCron.msi"  # Update this if MSI is in a different path

            if (-not (Test-Path $msiPath)) {
                Write-Host "❌ MSI not found at $msiPath" -ForegroundColor Red
                return
            }

            # Ensure running with admin rights
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")
            if (-not $isAdmin) {
                Write-Host "❌ Script not running with admin privileges!" -ForegroundColor Red
                return
            }

            Write-Host "✅ Installing VisualCron silently via MSI..." -ForegroundColor Cyan
            Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
            Write-Host "✔ VisualCron installed successfully!" -ForegroundColor Green
        }

        Add-Content -Path $logPath -Value "$(Get-Date) - SUCCESS - $computerName"

    } catch {
        Write-Host "❌ Failed to install on $computerName $_" -ForegroundColor Red
        Add-Content -Path $logPath -Value "$(Get-Date) - FAIL - $computerName - $_"
    }
}
