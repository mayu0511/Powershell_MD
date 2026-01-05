# ======================================================================================================
# BACKUP + ZIP PACKAGE SCRIPT
# Developed by: Mahendra Dwivedi
# Version: 2.0 | Date: 10-Oct-2025
# ------------------------------------------------------------------------------------------------------
# Step 1: Backup Files
# Step 2: Zip Folders
# ======================================================================================================

Clear-Host

# ==========================================
# USER INPUT: Choose Step to Run
# ==========================================
Write-Host "Select Step to Run:"
Write-Host "1 - Run Backup Only"
Write-Host "2 - Run Zipping Only"
$stepChoice = Read-Host "Enter your choice (1/2)"

# ======================================================================================================
# STEP 1 - BACKUP
# ======================================================================================================
if ($stepChoice -eq "1" -or $stepChoice -eq "3") {

    Write-Host "`n===================== STEP 1: BACKUP STARTED =====================" -ForegroundColor Cyan

    # Clear variables (except core PowerShell ones)
    Get-Variable | Where-Object {
        ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
        $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
    } | ForEach-Object {
        Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
    }

    $ErrorActionPreference = 'Stop'
    $sourcePath = "E:\CoreCard"
    $destinationPath = "C:\Users\mahendra.dwivedi\Desktop\asd"
    $logPath = "C:\TEMP\BackupCopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    # Ensure log folder
    if (!(Test-Path (Split-Path $logPath))) {
        New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
    }

    function Log { param([string]$msg)
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Add-Content -Path $logPath -Value "[$timestamp] $msg"
    }

    Log "🔁 Starting backup from '$sourcePath' to '$destinationPath'"

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
            $item.Extension -eq ".pgp" -or $item.Extension -eq ".ipm" -or $item.Extension -eq ".out" -or `
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

        if ($excludedItems.Count -gt 0) {
            Log "🔸 Excluded items:"
            $excludedItems | ForEach-Object { Log "⛔ Skipped: $_" }
        }

    } catch {
        Log "❌ Failed to read source: $_"
        Write-Host "❌ Error getting source items." -ForegroundColor Red
        exit 1
    }

    $totalItems = $itemsToCopy.Count
    if ($totalItems -eq 0) {
        Log "⚠️ No items found for backup."
        Write-Host "⚠️ Nothing to back up. Exiting..." -ForegroundColor Yellow
        exit 0
    }

    $currentItem = 0
    foreach ($item in $itemsToCopy) {
        $currentItem++
        $percentComplete = ($currentItem / $totalItems) * 100
        Write-Progress -Activity "Copying Files" -Status "Copying $($item.Name)" -PercentComplete $percentComplete

        $destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)
        $destFolder = Split-Path $destItemPath

        if (!(Test-Path $destFolder)) { New-Item -ItemType Directory -Path $destFolder -Force | Out-Null }

        if ($item.PSIsContainer) {
            if (!(Test-Path $destItemPath)) { New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null }
        } else {
            try {
                Copy-Item $item.FullName $destItemPath -Force -ErrorAction Stop
            } catch {
                Log "❌ Failed to copy $($item.FullName): $_"
                Write-Host "❌ Copy failed for: $($item.FullName)" -ForegroundColor Red
                $choice = Read-Host "Enter 1 to STOP or 2 to CONTINUE"
                if ($choice -eq "1") { exit 1 }
            }
        }
    }

    Log "✅ Backup completed successfully."
    Write-Host "`nBackup completed successfully." -ForegroundColor Green
}

# ======================================================================================================
# STEP 2 - ZIP PACKAGE
# ======================================================================================================
if ($stepChoice -eq "2" -or $stepChoice -eq "3") {

    Write-Host "`n===================== STEP 2: ZIPPING STARTED =====================" -ForegroundColor Cyan

    $SourceFolderPath = "C:\Users\mahendra.dwivedi\Desktop\asd\1\"
    $destinationFolderPath = "E:\Test"

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFileName = "Packagezip_$timestamp.txt"
    $logFilePath = "C:\Temp\$logFileName"

    $logOutput = @()
    $errorOutput = @()
    $totalFilesZipped = 0

    $logOutput += "Log Timestamp: $timestamp"
    $logOutput += "Source Folder: $SourceFolderPath"
    $logOutput += "Destination Folder: $destinationFolderPath`n"

    $subfolders = Get-ChildItem -Path $SourceFolderPath -Directory
    $totalItems = $subfolders.Count
    $currentItem = 0

    foreach ($folder in $subfolders) {
        $currentItem++
        $percentComplete = ($currentItem / $totalItems) * 100
        Write-Progress -Activity "Zipping Folders" -Status "Zipping $($folder.Name)" -PercentComplete $percentComplete

        $folderPath = $folder.FullName
        $zipFileName = Join-Path $destinationFolderPath "$($folder.Name).zip"

        try {
            if (Test-Path $zipFileName) { Remove-Item $zipFileName -Force }
            $fileCount = (Get-ChildItem $folderPath -Recurse -File).Count
            Compress-Archive -Path $folderPath -DestinationPath $zipFileName -CompressionLevel Fastest
            $totalFilesZipped += $fileCount
        } catch {
            $errorOutput += "ERROR: Failed to zip '$folderPath' - $($_.Exception.Message)"
            continue
        }
    }

    $logOutput += "`n$($subfolders.Count) folders processed."
    $logOutput += "$totalFilesZipped total files zipped."

    if ($errorOutput.Count -gt 0) {
        $logOutput += "`nErrors Encountered:"
        $logOutput += $errorOutput
        Write-Host "`nErrors during zipping:" -ForegroundColor Red
        $errorOutput | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    }

    $logOutput | Set-Content -Path $logFilePath
    Write-Host "`nZipping complete. Log saved to: $logFilePath" -ForegroundColor Green
}

Write-Host "`n===================== SCRIPT COMPLETED =====================" -ForegroundColor Cyan
