####################################################################################################################################
# Run CC Operational Scripts | Developed by: Mahendra Dwivedi
# Version 1.0 | Date 16-Jul-2026
####################################################################################################################################

$scripts = [ordered]@{
    "1" = @{ Name = "Config Operations";   Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\Config-Operations1.0.ps1";   Args = @() }
    "2" = @{ Name = "Application Variables Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\Variables-Validation1.6.ps1";  Args = @() }
    "3" = @{ Name = "Application SetupFile Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\SetupFile-Validation1.0.ps1";  Args = @() }
    "4" = @{ Name = "Application Process Status Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\Process-Status-Validation1.0.ps1";  Args = @() }
    "5" = @{ Name = "Application ODBC Drivers Check";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ODBC_DriversCheck1.0.ps1";  Args = @() }
    "6" = @{ Name = "Application ODBC Connection Check";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ODBC_ConnectionCheck1.0.ps1";  Args = @() }
    "7" = @{ Name = "Application Dbbtrace Error config Validatin";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\DbbtraceErrorconfig-Validatin1.0.ps1";  Args = @() }
    "8" = @{ Name = "Application Batch Validation";   Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\Batch-Validation1.0.ps1";   Args = @() }
   # "9" = @{ Name = "Application HMAC and SHA3DLL Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\HMAC_SHA3DLLValidation1.0.ps1";  Args = @() }
	"10" = @{ Name = "Application RundbbEXE Count Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\RundbbEXE_CountValidation1.0.ps1";  Args = @() }
	"11" = @{ Name = "Application ScaleFile Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ScaleFile_Validation1.0.ps1";  Args = @() }
    "12" = @{ Name = "Application MIPS Telnet Connection Test";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\MIPS_Telnet_ConnectionTest1.0.ps1";  Args = @() }
	"13" = @{ Name = "Application Service APIHUBURL Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ServiceAPIHUBURL-Validation1.0.ps1";  Args = @() }
    "14" = @{ Name = "WEB Server Services WebSite Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\Services-WebSite-Validation1.0.ps1";  Args = @() }
    "15" = @{ Name = "WEB Server CoreIssue WebSite Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\CoreIssue-WebSite-Validation1.0.ps1";  Args = @() }
    "16" = @{ Name = "WEB Server Services API Configuration Cert Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\ServicesAPIConfigurationCert-Validation1.0.ps1";  Args = @() }
    "17" = @{ Name = "WEB Server Services API Configuration IP Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\ServicesAPIConfigurationIP-Validation1.0.ps1";  Args = @() }
    "18" = @{ Name = "WEB Server Services URL Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\Service-URL-Validation1.0.ps1";  Args = @() }
    "19" = @{ Name = "WEB Server Certificate Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\Cert-Validation1.0.ps1";  Args = @() }
    "20" = @{ Name = "WCF Server CoreCardServices Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WCF\CoreCardServices-Validation1.0.ps1";  Args = @() }
    "21" = @{ Name = "WCF Server NetworkmessageAPI Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WCF\NetworkmessageAPI1.0.ps1";  Args = @() }
    "22" = @{ Name = "WCF Server WCF Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WCF\WCF-Validation1.0.ps1";  Args = @() }
    "23" = @{ Name = "E-WEB Server CoreCredit WebSite Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\EWEB\CoreCredit_WebSite-Validation1.0.ps1";  Args = @() }
    "24" = @{ Name = "KMS Server KMS Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\KMS\KMS-Validation1.0.ps1";  Args = @() }
    "25" = @{ Name = "KMS Server KMS KMS Recovery ResetValue Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\KMS\KMS-Recovery-ResetValue-Validation1.0.ps1";  Args = @() }
    "26" = @{ Name = "ReportDelivery Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\ReportDelivery\ReportDelivery-Validation1.0.ps1";  Args = @() }
    "27" = @{ Name = "ReportServer Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\ReportServer\ReportServer-Validation1.0.ps1";  Args = @() }
    "28" = @{ Name = "CoreOps WEBAPI Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\CoreOps\CoreOps-WEBAPIValidation1.0.ps1";  Args = @() }
    "29" = @{ Name = "CoreOps App Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\CoreOps\CoreOps-AppValidation1.0.ps1";  Args = @() } 
    "30" = @{ Name = "Backup Script";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\Backup_Script1.0.ps1";  Args = @() }
    "31" = @{ Name = "Package Checksum match";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\PackageChecksummatchV11.ps1";  Args = @() }
    "32" = @{ Name = "PlatformCode Delete";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\PlatformCodeDelete1.0.ps1";  Args = @() }
    "33" = @{ Name = "User Change WCF AppPool";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\UserChange_WCFAppPool1.0.ps1";  Args = @() }
    "34" = @{ Name = "Task Creator";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\Task-Creator1.0.ps1";  Args = @() }

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