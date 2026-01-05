# ------------------------------------------------------------------------------------------------------
# Backup Script | Developed by: Mahendra Dwivedi
# Version 1.6 | Features: Variable cleanup, error handling, logging, count verification, mismatch logging
# ------------------------------------------------------------------------------------------------------

# ========================
# STEP 0: Clear All Variables
# ========================
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}

# ========================
# STEP 1: Configuration
# ========================
$ErrorActionPreference = 'Stop'  # Fail on any error

$sourcePath = "E:\DBBSetup"
$destinationPath = "C:\Users\mahendra.dwivedi\Desktop\a"
$logPath = "C:\TEMP\BackupCopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Create log directory if it doesn't exist
if (!(Test-Path -Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}

# ========================
# STEP 2: Logging Function
# ========================
function Log {
    param([string]$msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $logPath -Value "[$timestamp] $msg"
}

Log "🔁 Starting backup from '$sourcePath' to '$destinationPath'"

# ========================
# STEP 3: Collect Items to Copy
# ========================
try {
    $itemsToCopy = Get-ChildItem -Path $sourcePath -Recurse -Force | Where-Object {
        ($_.FullName -notmatch '\\CheckSumFiles(\\|$)') -and
        ($_.FullName -notmatch '\\Mahendra(\\|$)') -and
        (
            ($_ -is [System.IO.DirectoryInfo]) -or
            (
                -not (
                    $_.Extension -eq ".log" -or
                    $_.Extension -eq ".zip" -or
                    $_.Extension -eq ".gpg" -or
                    $_.Extension -eq ".pgp" -or
                    $_.Extension -eq ".ipm" -or
                    $_.Extension -eq ".out" -or
                    $_.Extension -like ".pgp" -or
                    $_.Name -match "^ACH12" -or
                    $_.Name -match "^LogFileStep" -or
                    $_.Name -match "^BulkFileResponse_" -or
                    $_.Name -match "^MCI.AR.T" -or
                    ($_.Extension -eq ".csv" -and $_.Name -ne "amortizationSourceFileinfo.csv")
                )
            )
        )
    }
    $totalItems = $itemsToCopy.Count
    $currentItem = 0
} catch {
    Log "❌ Failed to get source items: $_"
    Write-Host "❌ Failed to get source items. Stopping script." -ForegroundColor Red
    exit 1
}


# ========================
# STEP 4: Copy Items (with user prompt on failure)
# ========================
foreach ($item in $itemsToCopy) {
    $currentItem++
    $percentComplete = ($currentItem / $totalItems) * 100
    Write-Progress -Activity "Copying Files" -Status "Copying $($item.Name)" -PercentComplete $percentComplete

    $destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)
    $destFolderPath = [System.IO.Path]::GetDirectoryName($destItemPath)

    if (!(Test-Path -Path $destFolderPath)) {
        New-Item -ItemType Directory -Path $destFolderPath -Force | Out-Null
    }

    if ($item.PSIsContainer) {
        if (!(Test-Path -Path $destItemPath)) {
            New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null
        }
    } else {
        $copySuccess = $true
        try {
            Copy-Item -Path $item.FullName -Destination $destItemPath -Force -ErrorAction Stop
            if (!(Test-Path $destItemPath)) {
                throw "Verification failed: '$destItemPath' does not exist after copy."
            }
        } catch {
            $copySuccess = $false
            $errorMsg = "❌ Failed to copy: $($item.FullName) => $_"
            Log $errorMsg
            Write-Host "`n$errorMsg" -ForegroundColor Red
        }

        if (-not $copySuccess) {
            while ($true) {
                $userChoice = Read-Host "`nEnter 1 to STOP or 2 to CONTINUE copying"
                if ($userChoice -eq "1") {
                    Log "User chose to STOP the script after error."
                    Write-Host "Stopping script as requested by user." -ForegroundColor Red
                    exit 1
                } elseif ($userChoice -eq "2") {
                    Log "User chose to CONTINUE despite the error."
                    Write-Host "Continuing to next file..." -ForegroundColor Yellow
                    break
                } else {
                    Write-Host "Invalid input. Please enter 1 or 2." -ForegroundColor Cyan
                }
            }
        }
    }
}

# ========================
# STEP 5: Ensure Folder Structure
# ========================
$sourceFolders = Get-ChildItem -Path $sourcePath -Directory -Recurse -Force
foreach ($folder in $sourceFolders) {
    $destFolder = $folder.FullName.Replace($sourcePath, $destinationPath)
    if (!(Test-Path -Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }
}

# ========================
# STEP 6: Count, Validate & Detect Missing Items
# ========================

# Get all relative file paths
$sourceFiles = Get-ChildItem -Path $sourcePath -File -Recurse -Force | ForEach-Object {
    $_.FullName.Replace($sourcePath, '').TrimStart('\')
}
$destFiles = Get-ChildItem -Path $destinationPath -File -Recurse -Force | ForEach-Object {
    $_.FullName.Replace($destinationPath, '').TrimStart('\')
}

# Get all relative folder paths
$sourceFolders = Get-ChildItem -Path $sourcePath -Directory -Recurse -Force | ForEach-Object {
    $_.FullName.Replace($sourcePath, '').TrimStart('\')
}
$destFolders = Get-ChildItem -Path $destinationPath -Directory -Recurse -Force | ForEach-Object {
    $_.FullName.Replace($destinationPath, '').TrimStart('\')
}

# Compare and find missing files/folders
$missingFiles = $sourceFiles | Where-Object { $_ -notin $destFiles }
$missingFolders = $sourceFolders | Where-Object { $_ -notin $destFolders }

# Summary output (only counts to console)
Write-Output "`n========== Backup Summary =========="
Write-Output "Source File Count      : $($sourceFiles.Count)"
Write-Output "Destination File Count : $($destFiles.Count)"
Write-Output "Source Folder Count    : $($sourceFolders.Count)"
Write-Output "Destination Folder Count: $($destFolders.Count)"

# Log counts
Log "========== Backup Summary =========="
Log "Source File Count      : $($sourceFiles.Count)"
Log "Destination File Count : $($destFiles.Count)"
Log "Source Folder Count    : $($sourceFolders.Count)"
Log "Destination Folder Count: $($destFolders.Count)"

# Handle mismatches quietly in console (log only)
if ($missingFiles.Count -eq 0 -and $missingFolders.Count -eq 0) {
    Log "✅ File and Folder count match. Backup successful."
} else {
    Log "❌ Count mismatch detected."

    if ($missingFiles.Count -gt 0) {
        Log "Missing Files:"
        $missingFiles | ForEach-Object { Log "❌ File missing: $_" }
    }

    if ($missingFolders.Count -gt 0) {
        Log "Missing Folders:"
        $missingFolders | ForEach-Object { Log "❌ Folder missing: $_" }
    }

    Log "❌ Backup integrity failed due to missing items. Stopping script."
    exit 1
}
