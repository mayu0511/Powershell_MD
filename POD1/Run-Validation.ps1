####################################################################################################################################
# Run CC Operational Scripts | Developed by: Mahendra Dwivedi
# Date:** 16-Jul-2026
####################################################################################################################################


$scripts = [ordered]@{
    "1" = @{ Name = "Config Operations";   Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\Config-Operations1.0.ps1";   Args = @() }
    "2" = @{ Name = "SetupFile Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\SetupFile-Validation1.0.ps1";  Args = @() }
    "3" = @{ Name = "Process Status Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\Process-Status-Validation1.0.ps1";  Args = @() }
    "4" = @{ Name = "ODBC Drivers Check";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ODBC_DriversCheck1.0.ps1";  Args = @() }
    "5" = @{ Name = "ODBC Connection Check";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ODBC_ConnectionCheck1.0.ps1";  Args = @() }
    "6" = @{ Name = "Dbbtrace Error config Validatin";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\DbbtraceErrorconfig-Validatin1.0.ps1";  Args = @() }
    "7" = @{ Name = "Batch Validation";   Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\Batch-Validation1.0.ps1";   Args = @() }
    "8" = @{ Name = "HMAC and SHA3DLL Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\HMAC_SHA3DLLValidation1.0.ps1";  Args = @() }
	"9" = @{ Name = "RundbbEXE Count Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\RundbbEXE_CountValidation1.0.ps1";  Args = @() }
	"10" = @{ Name = "ScaleFile Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ScaleFile_Validation1.0.ps1";  Args = @() }
    "11" = @{ Name = "MIPS Telnet Connection Test";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\MIPS_Telnet_ConnectionTest1.0.ps1";  Args = @() }
	"12" = @{ Name = "Service APIHUBURL Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Application\ServiceAPIHUBURL-Validation1.0.ps1";  Args = @() }
    "13" = @{ Name = "Services WebSite Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\Services-WebSite-Validation1.0.ps1";  Args = @() }
    "14" = @{ Name = "CoreIssue WebSite Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\CoreIssue-WebSite-Validation1.0.ps1";  Args = @() }
    "15" = @{ Name = "Service APIHUB URL Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\ServiceAPIHUBURL-Validation1.0.ps1";  Args = @() }
    "16" = @{ Name = "Services API Configuration Cert Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\ServicesAPIConfigurationCert-Validation1.0.ps1";  Args = @() }
    "17" = @{ Name = "Services API Configuration IP Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WEB\ServicesAPIConfigurationIP-Validation1.0.ps1";  Args = @() }
    "18" = @{ Name = "CoreCardServices Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WCF\CoreCardServices-Validation1.0.ps1";  Args = @() }
    "19" = @{ Name = "NetworkmessageAPI Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WCF\NetworkmessageAPI1.0.ps1";  Args = @() }
    "20" = @{ Name = "WCF Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\WCF\WCF-Validation1.0.ps1";  Args = @() }
    "21" = @{ Name = "CoreCredit WebSite Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\EWEB\CoreCredit_WebSite-Validation1.0.ps1";  Args = @() }
    "22" = @{ Name = "KMS Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\KMS\KMS-Validation1.0.ps1";  Args = @() }
    "23" = @{ Name = "KMS Recovery ResetValue Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\KMS\KMS-Recovery-ResetValue-Validation1.0.ps1";  Args = @() }
    "24" = @{ Name = "ReportDelivery Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\ReportDelivery\ReportDelivery-Validation1.0.ps1";  Args = @() }
    "25" = @{ Name = "ReportServer Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\ReportServer\ReportServer-Validation1.0.ps1";  Args = @() }
    "26" = @{ Name = "CoreOps WEBAPI Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\CoreOps\CoreOps-WEBAPIValidation1.0.ps1";  Args = @() }
    "27" = @{ Name = "CoreOps App Validation";  Path = "D:\CC_Scripts\Powershell_MD\POD1\CoreOps\CoreOps-AppValidation1.0.ps1";  Args = @() } 
    "28" = @{ Name = "Backup Script";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\Backup_Script1.0.ps1";  Args = @() }
    "29" = @{ Name = "Package Checksum match";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\PackageChecksummatchV11.ps1";  Args = @() }
    "30" = @{ Name = "PlatformCode Delete";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\PlatformCodeDelete1.0.ps1";  Args = @() }
    "31" = @{ Name = "User Change WCF AppPool";  Path = "D:\CC_Scripts\Powershell_MD\POD1\Occasionally_Use\UserChange_WCFAppPool1.0.ps1";  Args = @() }

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