# ------------------------------------------------------------------------------------------------------
# Backup Script | Developed by: Mahendra Dwivedi
# Version 1.6 | Date:: 10-Oct-2025
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
$ErrorActionPreference = 'Stop'

$sourcePath = "C:\Users\mahendra.dwivedi\Desktop\1"
$destinationPath = "C:\Users\mahendra.dwivedi\Desktop\2"
$logPath = "C:\TEMP\BackupCopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Ensure log directory exists
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
# STEP 3: Collect Items to Copy (excluding CheckSumFiles and unwanted patterns)
# ========================
$excludedItems = @()

try {
    $allItems = Get-ChildItem -Path $sourcePath -Recurse -Force
    $itemsToCopy = foreach ($item in $allItems) {
        $isExcluded = $false

        if ($item.FullName -match '\\CheckSumFiles(\\|$)') {
            $isExcluded = $true
        }
        elseif (-not ($item -is [System.IO.DirectoryInfo]) -and (
            $item.Extension -eq ".log" -or $item.Extension -eq ".zip" -or $item.Extension -eq ".pdf" -or $item.Extension -eq ".gpg" -or `
            $item.Extension -eq ".pgp" -or $item.Extension -eq ".ipm" -or $item.Extension -eq ".A001" -or $item.Extension -eq ".A004" -or $item.Extension -eq ".A005" -or $item.Extension -eq ".A006"-or $item.Extension -eq ".out" -or `
            $item.Extension -like ".pgp" -or $item.Name -match "^ACH12" -or $item.Name -match "^LogFileStep" -or `
            $item.Name -match "^BulkFileResponse_" -or $item.Name -match "^MCI.AR.T" -or  $item.Name -match "^ACH-RET-" -or
            ($item.Extension -eq ".csv" -and $item.Name -ne "amortizationSourceFileinfo.csv")
        )) {
            $isExcluded = $true
        }

        if ($isExcluded) {
            $excludedItems += $item.FullName
            continue
        }

        $item
    }

    # Log excluded items
    if ($excludedItems.Count -gt 0) {
        Log "🔸 The following items were excluded from backup:"
        $excludedItems | ForEach-Object { Log "⛔ Skipped: $_" }
    }

} catch {
    Log "❌ Failed to get source items: $_"
    Write-Host "❌ Failed to get source items. Stopping script." -ForegroundColor Red
    exit 1
}

# ========================
# STEP 3.5: Count Items & Prevent Divide-by-Zero
# ========================
$totalItems = $itemsToCopy.Count
$currentItem = 0

if ($totalItems -eq 0) {
    Log "⚠️ No items found to copy after applying exclusion filters."

    if ($excludedItems.Count -gt 0) {
        Log "🔸 All items were excluded. Here is the list of skipped items:"
        $excludedItems | ForEach-Object { Log "⛔ Skipped: $_" }
    }

    Write-Host "`n⚠️ No items to copy. All files/folders may be excluded." -ForegroundColor Yellow
    exit 0
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
# STEP 5: Ensure Folder Structure (excluding CheckSumFiles)
# ========================
$sourceFolders = Get-ChildItem -Path $sourcePath -Directory -Recurse -Force | Where-Object {
    $_.FullName -notmatch '\\CheckSumFiles(\\|$)'
}
foreach ($folder in $sourceFolders) {
    $destFolder = $folder.FullName.Replace($sourcePath, $destinationPath)
    if (!(Test-Path -Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }
}

# ========================
# STEP 6: Count, Validate & Detect Missing Items
# ========================
$sourceFiles = Get-ChildItem -Path $sourcePath -File -Recurse -Force | Where-Object {
    $_.FullName -notmatch '\\CheckSumFiles(\\|$)'
} | ForEach-Object {
    $_.FullName.Replace($sourcePath, '').TrimStart('\')
}
$destFiles = Get-ChildItem -Path $destinationPath -File -Recurse -Force | ForEach-Object {
    $_.FullName.Replace($destinationPath, '').TrimStart('\')
}

$sourceFolders = Get-ChildItem -Path $sourcePath -Directory -Recurse -Force | Where-Object {
    $_.FullName -notmatch '\\CheckSumFiles(\\|$)'
} | ForEach-Object {
    $_.FullName.Replace($sourcePath, '').TrimStart('\')
}
$destFolders = Get-ChildItem -Path $destinationPath -Directory -Recurse -Force | ForEach-Object {
    $_.FullName.Replace($destinationPath, '').TrimStart('\')
}

$missingFiles = $sourceFiles | Where-Object { $_ -notin $destFiles }
$missingFolders = $sourceFolders | Where-Object { $_ -notin $destFolders }

Write-Output "`n========== Backup Summary =========="
Write-Output "Source File Count      : $($sourceFiles.Count)"
Write-Output "Destination File Count : $($destFiles.Count)"
Write-Output "Source Folder Count    : $($sourceFolders.Count)"
Write-Output "Destination Folder Count: $($destFolders.Count)"

Log "========== Backup Summary =========="
Log "Source File Count      : $($sourceFiles.Count)"
Log "Destination File Count : $($destFiles.Count)"
Log "Source Folder Count    : $($sourceFolders.Count)"
Log "Destination Folder Count: $($destFolders.Count)"

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
