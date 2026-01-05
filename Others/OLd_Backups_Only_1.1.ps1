# ------------------------------------------------------------------------------------------------------
# Backup Script | Developed by: Mahendra Dwivedi
# Version 1.7 | Date:: 10-Oct-2025
# ------------------------------------------------------------------------------------------------------

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
$sourcePath      = "C:\Users\mahendra.dwivedi\Desktop\1"
$destinationPath = "C:\Users\mahendra.dwivedi\Desktop\2"
$logPath         = "C:\TEMP\BackupCopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Validate source
if (!(Test-Path $sourcePath)) {
    Write-Host "❌ Source path does not exist: $sourcePath" -ForegroundColor Red
    exit 1
}

# Ensure log directory exists
$logDir = Split-Path $logPath
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# ========================
# STEP 2: Logging Function
# ========================
function Log {
    param([string]$msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $logPath -Value "[$timestamp] $msg"
}

Log "Starting backup from '$sourcePath' to '$destinationPath'"

# ========================
# STEP 3: Collect Items (with exclusions)
# ========================
$excludedItems = @()

try {
    $allItems = Get-ChildItem -Path $sourcePath -Recurse -Force -ErrorAction Stop

    $itemsToCopy = foreach ($item in $allItems) {
        $isExcluded = $false

        if ($item.FullName -match '\\CheckSumFiles(\\|$)') {
            $isExcluded = $true
        }
        elseif (-not $item.PSIsContainer -and (
            $item.Extension -in @(
                ".log",".zip",".pdf",".gpg",".pgp",".ipm",
                ".A001",".A004",".A005",".A006",".out"
            ) -or
            $item.Name -match "^(ACH12|LogFileStep|BulkFileResponse_|MCI.AR.T|ACH-RET-)" -or
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
}
catch {
    Log "Failed to get source items: $($_.Exception.Message)"
    Write-Host "❌ Failed to scan source path:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ========================
# STEP 4: Item Count Check
# ========================
$totalItems = $itemsToCopy.Count
$currentItem = 0

if ($totalItems -eq 0) {
    Log "No items found after exclusions"
    Write-Host "⚠️ No files/folders to copy" -ForegroundColor Yellow
    exit 0
}

# ========================
# STEP 5: Copy Items
# ========================
foreach ($item in $itemsToCopy) {
    $currentItem++
    $percent = [math]::Round(($currentItem / $totalItems) * 100, 2)

    Write-Progress -Activity "Copying Files" `
                   -Status "$percent% - $($item.FullName)" `
                   -PercentComplete $percent

    $destItemPath  = $item.FullName.Replace($sourcePath, $destinationPath)
    $destFolder    = Split-Path $destItemPath -Parent

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
        Copy-Item $item.FullName $destItemPath -Force -ErrorAction Stop
    }
    catch {
        $err = "Failed to copy: $($item.FullName) | $($_.Exception.Message)"
        Log $err
        Write-Host "`n❌ $err" -ForegroundColor Red

        while ($true) {
            $choice = Read-Host "Enter 1 to STOP or 2 to CONTINUE"
            if ($choice -eq "1") { exit 1 }
            if ($choice -eq "2") { break }
        }
    }
}

# ========================
# STEP 6: Structure Validation
# ========================
$sourceFiles = Get-ChildItem $sourcePath -File -Recurse -Force |
    Where-Object { $_.FullName -notmatch '\\CheckSumFiles(\\|$)' } |
    ForEach-Object { $_.FullName.Replace($sourcePath,'') }

$destFiles = Get-ChildItem $destinationPath -File -Recurse -Force |
    ForEach-Object { $_.FullName.Replace($destinationPath,'') }

$missing = $sourceFiles | Where-Object { $_ -notin $destFiles }

Write-Output "`n========== Backup Summary =========="
Write-Output "Source Files      : $($sourceFiles.Count)"
Write-Output "Destination Files : $($destFiles.Count)"

if ($missing.Count -eq 0) {
    Log "Backup successful. Files match."
    Write-Host "✅ Backup completed successfully" -ForegroundColor Green
}
else {
    Log "Missing files detected:"
    $missing | ForEach-Object { Log $_ }
    Write-Host "❌ Backup completed with missing files" -ForegroundColor Red
    exit 1
}
