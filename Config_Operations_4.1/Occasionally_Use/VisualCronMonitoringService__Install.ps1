# Install | VisualCronMonitoringService | Created BY::Rahul Bajpai
#########################################################################

# ------------------- Configuration -------------------
$serviceName    = "VisualCronMonitoringService"
$displayName    = "VisualCronMonitoringService"
$exePath        = "D:\DBBSetup\MonitoringScript\VisualCronsJobsMonitor\VisualCronsJobsMonitor.exe"

# ------------------- Create Service -------------------
# Note: binPath= must be followed immediately by a space

$createServiceCmd = "sc.exe create $serviceName binPath= `"$exePath`" DisplayName= `"$displayName`" start= auto"

Write-Host "🔧 Installing service '$serviceName'..." -ForegroundColor Cyan
Invoke-Expression $createServiceCmd

# ------------------- Start Service -------------------
Start-Service -Name $serviceName -ErrorAction SilentlyContinue

# ------------------- Confirm -------------------
$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($svc.Status -eq 'Running') {
    Write-Host "✅ Service '$serviceName' installed and running." -ForegroundColor Green
} else {
    Write-Host "⚠️ Service '$serviceName' created but not running. Check manually." -ForegroundColor Yellow
}
