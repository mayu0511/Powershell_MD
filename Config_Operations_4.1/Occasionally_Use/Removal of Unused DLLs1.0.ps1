######################################################################################################################
# Removal of Unused DLLs | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 | Date:: 20-Feb-2026

#======================================================================================================================

# =========================
# Paths & Setup (Date & Time)
# =========================

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

$BaseLogPath = "C:\Temp"
$ReportPath  = "C:\Temp"

$LogFile    = Join-Path $BaseLogPath "DeleteSteps_$TimeStamp.log"
$HtmlReport = Join-Path $ReportPath  "DeleteReport_$TimeStamp.html"

New-Item -ItemType Directory -Path $BaseLogPath -Force | Out-Null
New-Item -ItemType Directory -Path $ReportPath  -Force | Out-Null

$Results = New-Object System.Collections.ArrayList
$ExitScript = $false   # <-- exit flag

# =========================
# Functions
# =========================

function Write-Log {
    param ($Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File -FilePath $LogFile -Append
}

function Show-Menu {
    Write-Host ""
    Write-Host "=============================="
    Write-Host " Select Delete Option"
    Write-Host "=============================="
    Write-Host "1 - Delete CoreCredit"
    Write-Host "2 - Delete WCF"
    Write-Host "3 - Delete CoreCardServices"
    Write-Host "4 - Exit"
    Write-Host ""
}

function Delete-Files {
    param (
        [string]$StepName,
        [string]$Path,
        [string[]]$Files
    )

    Write-Host ""
    Write-Host "Running $StepName"
    Write-Log "Starting $StepName"

    foreach ($file in $Files) {
        $FullPath = Join-Path $Path $file

        if (Test-Path $FullPath) {
            try {
                Remove-Item $FullPath -Force
                Write-Log "Deleted: $FullPath"

                [void]$Results.Add([pscustomobject]@{
                    Step   = $StepName
                    File   = $file
                    Path   = $Path
                    Status = "Deleted"
                })
            }
            catch {
                Write-Log "Failed: $FullPath - $_"

                [void]$Results.Add([pscustomobject]@{
                    Step   = $StepName
                    File   = $file
                    Path   = $Path
                    Status = "Failed"
                })
            }
        }
        else {
            Write-Log "Not Found: $FullPath"

            [void]$Results.Add([pscustomobject]@{
                Step   = $StepName
                File   = $file
                Path   = $Path
                Status = "Not Found"
            })
        }
    }

    Write-Log "Completed $StepName"
}

# =========================
# Main Menu Loop
# =========================

while (-not $ExitScript) {

    Show-Menu
    $Choice = (Read-Host "Enter your choice").Trim()

    switch ($Choice) {

        "1" {
            Delete-Files `
                -StepName "Step 1 - CoreCredit" `
                -Path "E:\Trace\Package\Base\PATQA- 24.8.2\CoreCredit\bin" `
                -Files @("CoreCard.SAML2.dll")
        }

        "2" {
            Delete-Files `
                -StepName "Step 2 - WCF" `
                -Path "E:\Trace\Package\Base\PATQA- 24.8.2\WCFServer\WCF\bin" `
                -Files @(
                    "Elmah.dll",
                    "Microsoft.Extensions.Configuration.Abstractions.dll",
                    "Microsoft.Extensions.Configuration.Binder.dll",
                    "Microsoft.Extensions.Configuration.dll",
                    "Microsoft.Extensions.Configuration.EnvironmentVariables.dll",
                    "Microsoft.Extensions.Configuration.FileExtensions.dll",
                    "Microsoft.Extensions.Configuration.Json.dll",
                    "Microsoft.Extensions.DependencyInjection.dll",
                    "Microsoft.Extensions.FileProviders.Abstractions.dll",
                    "Microsoft.Extensions.FileProviders.Physical.dll",
                    "Microsoft.Extensions.FileSystemGlobbing.dll",
                    "Microsoft.Extensions.Logging.Console.dll",
                    "Microsoft.Extensions.Logging.dll",
                    "Microsoft.Extensions.ObjectPool.dll",
                    "Microsoft.Extensions.Options.ConfigurationExtensions.dll",
                    "Microsoft.Extensions.Options.dll",
                    "Microsoft.Extensions.PlatformAbstractions.dll",
                    "Microsoft.Net.Http.Headers.dll",
                    "Microsoft.Practices.ServiceLocation.dll",
                    "Microsoft.Practices.Unity.Configuration.dll",
                    "Microsoft.Practices.Unity.dll",
                    "Microsoft.Practices.Unity.RegistrationByConvention.dll",
                    "Microsoft.Win32.Primitives.dll",
                    "System.AppContext.dll",
                    "System.ComponentModel.Primitives.dll",
                    "System.ComponentModel.TypeConverter.dll",
                    "System.Console.dll",
                    "System.Globalization.Calendars.dll",
                    "System.IO.Compression.ZipFile.dll",
                    "System.IO.FileSystem.dll",
                    "System.IO.FileSystem.Primitives.dll",
                    "System.Net.Http.dll",
                    "System.Net.Sockets.dll",
                    "System.Runtime.InteropServices.RuntimeInformation.dll",
                    "System.Security.Cryptography.Algorithms.dll",
                    "System.Security.Cryptography.Encoding.dll",
                    "System.Security.Cryptography.Primitives.dll",
                    "System.Security.Cryptography.X509Certificates.dll"
                )
        }

        "3" {
            Delete-Files `
                -StepName "Step 3 - CoreCardServices" `
                -Path "E:\Trace\Package\Base\PATQA- 24.8.2\WCFServer\CoreCardServices\bin" `
                -Files @(
                    "Essential.Diagnostics.Core.dll",
                    "IdentityModel.dll",
                    "System.Net.Http.dll"
                )
        }

        "4" {
            Write-Host "Exiting script..."
            Write-Log "User selected Exit"
            $ExitScript = $true
        }

        default {
            Write-Host "Invalid option. Enter 1, 2, 3, or 4."
        }
    }
}

# =========================
# HTML Report + Auto Open
# =========================

if ($Results.Count -eq 0) {
    Write-Log "No files processed. Report not generated."
    return
}

$HtmlHead = @"
<style>
body { font-family: Segoe UI, Arial; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 6px; }
th { background-color: #f2f2f2; }
.status-deleted { background-color: #c6efce; color: #006100; font-weight: bold; }
.status-other { background-color: #ffe5b4; color: #9c5700; font-weight: bold; }
</style>
"@

$HtmlBody = $Results |
    Select Step, File, Path, Status |
    ConvertTo-Html `
        -Head $HtmlHead `
        -Title "DLL Deletion Report" `
        -PreContent "<h2>DLL Deletion Summary</h2><p>Generated on $(Get-Date)</p>"

$HtmlBody = $HtmlBody `
    -replace '<td>Deleted</td>', '<td class="status-deleted">Deleted</td>' `
    -replace '<td>Failed</td>', '<td class="status-other">Failed</td>' `
    -replace '<td>Not Found</td>', '<td class="status-other">Not Found</td>'

$HtmlBody | Out-File $HtmlReport -Encoding UTF8

Write-Log "HTML report generated: $HtmlReport"
Start-Process $HtmlReport
