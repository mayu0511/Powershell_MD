# Un-Install | VisualCronMonitoringService | Created BY::Rahul Bajpai
#########################################################################


$serviceName = "VisualCronMonitoringService"

Write-Host "🧹 Uninstalling service: $serviceName" -ForegroundColor Cyan

# Check if the service exists
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    # Stop the service if it's running
    if ($service.Status -eq 'Running') {
        Write-Host "⏹️ Stopping service before uninstall..." -ForegroundColor Yellow
        Stop-Service -Name $serviceName -Force
    }

    # Delete the service
    sc.exe delete $serviceName | Out-Null

    Start-Sleep -Seconds 2 # Give it time to remove

    # Confirm deletion
    if (-not (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
        Write-Host "✅ Service '$serviceName' uninstalled successfully." -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to uninstall service '$serviceName'. Try manually." -ForegroundColor Red
    }
} else {
    Write-Host "ℹ️ Service '$serviceName' not found. Nothing to uninstall." -ForegroundColor Gray
}
