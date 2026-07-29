####################################################################################################################################
# Run CC Operational Scripts | Developed by: Mahendra Dwivedi
# Date:** 16-Jul-2026
####################################################################################################################################


$scripts = [ordered]@{
    "1" = @{ Name = "APIHUB-Validation";     Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\APIHUB-Validation1.6.ps1";     Args = @() }
    "2" = @{ Name = "Batch-Validation";   Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Batch-Validation1.7.ps1";   Args = @() }
    "3" = @{ Name = "Config-Operations";   Path = ".D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Config-Operations4.2.ps1";   Args = @() }
    "4" = @{ Name = "CoreCardServices-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\CoreCardServices-Validation.ps1";  Args = @() }
    "5" = @{ Name = "CoreCredit_WebSite-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\CoreCredit_WebSite-Validation2.3.ps1";  Args = @() }
    "6" = @{ Name = "CoreIssue-WebSite-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\CoreIssue-WebSite-Validation.ps1";  Args = @() }
    "7" = @{ Name = "CoreOps-AppValidation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\CoreOps-AppValidation1.0.ps1";  Args = @() }
    "8" = @{ Name = "CoreOps-WEBAPIValidation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\CoreOps-WEBAPIValidation1.1.ps1";  Args = @() }
    "9" = @{ Name = "DbbtraceErrorconfig-Validatin";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\DbbtraceErrorconfig-Validatin1.2.ps1";  Args = @() }
    "10" = @{ Name = "FileSplitter-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\FileSplitter-Validation3.6.ps1";  Args = @() }
    "11" = @{ Name = "KMS-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\KMS-Validation2.0.ps1";  Args = @() }
    "12" = @{ Name = "NetworkmessageAPI";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\NetworkmessageAPI.ps1";  Args = @() }
    "13" = @{ Name = "Process-Status-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Process-Status-Validation3.5.ps1";  Args = @() }
    "14" = @{ Name = "ReportDelivery-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\ReportDelivery-Validation2.6.ps1";  Args = @() }
    "15" = @{ Name = "ReportServer-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\ReportServer-Validation.ps1";  Args = @() }
    "16" = @{ Name = "ServiceAPIHUBURL-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\ServiceAPIHUBURL-Validation4.1.ps1";  Args = @() }
    "17" = @{ Name = "ServicesAPIConfigurationCert-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\ServicesAPIConfigurationCert-Validation.ps1";  Args = @() }
    "18" = @{ Name = "ServicesAPIConfigurationIP-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\ServicesAPIConfigurationIP-Validation1.0.ps1";  Args = @() }
    "19" = @{ Name = "Services-WebSite-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Services-WebSite-Validation1.0.ps1";  Args = @() }
    "20" = @{ Name = "SetupFile-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\SetupFile-Validation1.2.ps1";  Args = @() }
    "21" = @{ Name = "WCF-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\WCF-Validation.ps1";  Args = @() }
    "22" = @{ Name = "Backup_Script";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\Backup_Script5.7.ps1";  Args = @() }
    "23" = @{ Name = "Backup_SS_Script";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\Backup_SS_Script3.5.ps1";  Args = @() }
    "24" = @{ Name = "HMAC_SHA3DLLValidation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\HMAC_SHA3DLLValidation1.0.ps1";  Args = @() }
    "25" = @{ Name = "KMS-Recovery-ResetValue-Validation";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\KMS-Recovery-ResetValue-Validation1.2.ps1";  Args = @() }
    "26" = @{ Name = "ODBC_ConnectionCheck";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\ODBC_ConnectionCheck1.ps1";  Args = @() }
    "27" = @{ Name = "ODBC_DriversCheck";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\ODBC_DriversCheck.ps1";  Args = @() }
    "28" = @{ Name = "PackageChecksummatch";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\PackageChecksummatchV12.ps1";  Args = @() }
    "29" = @{ Name = "PlatformCodeDelete";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\PlatformCodeDelete1.0.ps1";  Args = @() }
    "30" = @{ Name = "UserChange_WCFAppPool";  Path = "D:\CC_Scripts\Powershell_MD\Config_Operations_4.1\Occasionally_Use\UserChange_WCFAppPool1.1.ps1";  Args = @() }

   }

function Show-Menu {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "      CoreCard Operational Scripts - MAIN MENU"       -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    foreach ($key in $scripts.Keys) {
        Write-Host " [$key] $($scripts[$key].Name)"
    }
    Write-Host " [A] Run ALL validations in sequence"
    Write-Host " [Q] Quit"
    Write-Host "=============================================" -ForegroundColor Cyan
}

function Run-Script {
    param($entry)

    $path = $entry.Path
    Write-Host "`n>>> Running: $($entry.Name)" -ForegroundColor Yellow

    if (-not (Test-Path $path)) {
        Write-Host "ERROR: Script not found at '$path'" -ForegroundColor Red
        return
    }

    try {
        & $path @($entry.Args)
        Write-Host ">>> $($entry.Name) completed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host ">>> $($entry.Name) FAILED: $_" -ForegroundColor Red
    }
}

# ----------------------------------------------------------------------
# 2. Main loop
# ----------------------------------------------------------------------
do {
    Show-Menu
    $choice = Read-Host "`nEnter your choice"

    switch ($choice.ToUpper()) {
        "A" {
            foreach ($key in $scripts.Keys) {
                Run-Script -entry $scripts[$key]
            }
        }
        "Q" {
            Write-Host "Exiting. Goodbye!" -ForegroundColor Cyan
        }
        default {
            if ($scripts.Contains($choice)) {
                Run-Script -entry $scripts[$choice]
            }
            else {
                Write-Host "Invalid choice. Try again." -ForegroundColor Red
            }
        }
    }

    if ($choice.ToUpper() -ne "Q") {
        Write-Host "`nPress Enter to return to the menu..."
        Read-Host | Out-Null
    }

} while ($choice.ToUpper() -ne "Q")
