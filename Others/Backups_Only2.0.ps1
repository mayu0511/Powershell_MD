######################################################################################################################
# Backup  Scripts  | DEVELOPED BY:: Mahendra Dwivedi
# Version 2.0 | Date:: 11-DEc-2025
#======================================================================================================================

Clear-Host
$ErrorActionPreference = 'Stop'

# ========================
# STEP 0: Clear Variables
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
$sourcePath      = "C:\Users\mahendra.dwivedi\Desktop\copy\1\"
$destinationPath = "C:\Users\mahendra.dwivedi\Desktop\1\"
$logPath         = "C:\TEMP\BackupCopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Log function
function Log {
    param([string]$msg)
    Add-Content -Path $logPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
}

# Validate source
if (!(Test-Path $sourcePath)) {
    Write-Host "Source path does not exist: $sourcePath" -ForegroundColor Red
    exit 1
}

# Ensure log directory exists
$logDir = Split-Path $logPath
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# ========================
# STEP 3: Collect Items
# ========================
$scanErrors = @()

$allItems = Get-ChildItem -Path $sourcePath -Recurse -Force `
            -ErrorAction SilentlyContinue `
            -ErrorVariable scanErrors

if ($scanErrors.Count -gt 0) {
    Log "Some paths skipped during scan due to long-path, missing-path or access issues."
    foreach ($err in $scanErrors) {
        Log "Skipped: $($err.TargetObject)"
    }
}

$itemsToCopy = @()
foreach ($item in $allItems) {

    # Exclusion Rules
    if ($item.PSIsContainer -and $item.Name -in @()) {
        continue
    }
    elseif (-not $item.PSIsContainer -and (
        $item.Extension -in @(
            ".log",".zip",".pdf",".gpg",".pgp",".ipm",
            ".A001",".A004",".A005",".A006",".Xlsx",".out"
        ) -or
        $item.Name -match "^(ACH12|LogFileStep|BulkFileResponse_|MCI.AR.T|ACH-RET-)" -or
        ($item.Extension -eq ".csv" -and $item.Name -ne "amortizationSourceFileinfo.csv")
    )) {
        continue
    }

    $itemsToCopy += $item
}

# ========================
# STEP 4: Item Count Check
# ========================
$totalItems = $itemsToCopy.Count
$currentItem = 0

if ($totalItems -eq 0) {
    Log "No items found after exclusions"
    Write-Host "No files or folders to copy" -ForegroundColor Yellow
    exit 0
}

# ========================
# STEP 5: Copy Items (Ignore Long-Path / Missing-Path Errors)
# ========================
foreach ($item in $itemsToCopy) {
    $currentItem++
    $percent = [math]::Round(($currentItem / $totalItems) * 100, 2)

    Write-Progress -Activity "Copying Files" -Status "$percent% - $($item.FullName)" -PercentComplete $percent

    $destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)
    $destFolder   = Split-Path $destItemPath -Parent

    if (!(Test-Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }

    if ($item.PSIsContainer) {
        if (!(Test-Path $destItemPath)) {
            New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null
        }
        continue
    }

    try {
        Copy-Item -Path $item.FullName -Destination $destItemPath -Force -ErrorAction Stop
    }
    catch {
        Log "Skipped (copy failed): $($item.FullName) | $($_.Exception.Message)"
        Write-Host "Skipping file due to error: $($item.FullName)" -ForegroundColor Yellow
        continue
    }
}

# ========================
# ========================
# STEP 6: Summary
# ========================
$sourceFiles = Get-ChildItem $sourcePath -File -Recurse -Force | ForEach-Object { $_.FullName.Replace($sourcePath,'') }
$sourceFolders = Get-ChildItem $sourcePath -Directory -Recurse -Force | ForEach-Object { $_.FullName.Replace($sourcePath,'') }

$destFiles   = Get-ChildItem $destinationPath -File -Recurse -Force | ForEach-Object { $_.FullName.Replace($destinationPath,'') }
$destFolders = Get-ChildItem $destinationPath -Directory -Recurse -Force | ForEach-Object { $_.FullName.Replace($destinationPath,'') }

$missingFiles   = $sourceFiles   | Where-Object { $_ -notin $destFiles }
$missingFolders = $sourceFolders | Where-Object { $_ -notin $destFolders }

Write-Output "
========== Backup Summary =========="
Write-Output "Source Files       : $($sourceFiles.Count)"
Write-Output "Destination Files  : $($destFiles.Count)"
Write-Output "Source Folders     : $($sourceFolders.Count)"
Write-Output "Destination Folders: $($destFolders.Count)"

if ($missingFiles.Count -eq 0 -and $missingFolders.Count -eq 0) {
    Log "Backup successful (all matching files and folders copied except intentionally skipped)."
    Write-Host "Backup completed successfully" -ForegroundColor Green
}
else {
    Log "Some items failed to copy (likely long-path or missing-path issues)."
    foreach ($m in $missingFiles)   { Log "Missing File: $m" }
    foreach ($m in $missingFolders) { Log "Missing Folder: $m" }
    Write-Host "Backup completed with skipped items" -ForegroundColor Yellow
}
