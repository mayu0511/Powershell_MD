#########################################################################
# Install | VisualCronMonitoringService | Created BY:: Rahul Bajpai
# Enhance by Mahendra | 6-Aug-2026
#########################################################################

# ------------------- Configuration -------------------
$serviceName = "VisualCronMonitoringJobService"
$displayName = "VisualCronMonitoringJobService"
$exePath     = "D:\DBBSetup\MonitoringScript\VisualCronsJobsMonitor\VisualCronsJobsMonitor.exe"

# ------------------- Validate EXE -------------------
if (!(Test-Path $exePath))
{
    Write-Host "ERROR: Executable not found: $exePath" -ForegroundColor Red
    exit 1
}

# ------------------- Check Existing Service -------------------
$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($existingService)
{
    Write-Host "Service '$serviceName' already exists." -ForegroundColor Yellow
}
else
{
    Write-Host "Installing service '$serviceName'..." -ForegroundColor Cyan

    & sc.exe create $serviceName `
        binPath= "`"$exePath`"" `
        DisplayName= "`"$displayName`"" `
        start= auto

    Start-Sleep -Seconds 2
}

# ------------------- Start Service -------------------
try
{
    Start-Service -Name $serviceName -ErrorAction Stop
}
catch
{
    Write-Host "Unable to start service: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ------------------- Confirm -------------------
$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($null -eq $svc)
{
    Write-Host "Service '$serviceName' was not created." -ForegroundColor Red
}
elseif ($svc.Status -eq 'Running')
{
    Write-Host "Service '$serviceName' installed and running." -ForegroundColor Green
}
else
{
    Write-Host "Service '$serviceName' exists but is not running. Current Status: $($svc.Status)" -ForegroundColor Yellow
}