######################################################################################################################
# Backup Script: FileSplitter & API HUB  | DEVELOPED BY :: Mahendra Dwivedi
# Version 1.0 | Date :: 16-Mar-2026
######################################################################################################################

Clear-Host
$ErrorActionPreference = "Stop"

# ========================
# STEP 0: Log Setup
# ========================
$logPath = "C:\Temp\DBBBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Log {
    param([string]$msg)
    Add-Content -Path $logPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
}

# ========================
# STEP 1: Main Menu
# ========================
Write-Host ""
Write-Host "Select Backup Option:"
Write-Host "1. FileSplitter Backup"
Write-Host "2. API HUB Backup"

$mainChoice = Read-Host "Enter option"

switch ($mainChoice) {

    "1" {
        # ========================
        # FILESPLITTER BACKUP
        # ========================

# STEP 1: Environment Selection

# ========================

Write-Host ""
Write-Host "Select Environment"
Write-Host "1. PATUAT"
Write-Host "2. PROD"

$choice = Read-Host "Enter option"

$CurrentDate = Get-Date -Format "yyyyMMdd"
$sourcePath = "D:\DBBSetup"
$backupRoot = "D:\Backup"

switch ($choice) {


"1" {
    $environment = "PATUAT"
    $destinationPath = "$backupRoot\CCFSE1PATUATB1"
    $zipName = "CCFSE1PATUATB1.zip"

    $s3Locations = @(
    "s3://corecard-sharedservices-patuat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    )
}

"2" {
    $environment = "PROD"
    $destinationPath = "$backupRoot\CCFSE1PRODB1"
    $zipName = "CCFSE1PRODB1.zip"

    $s3Locations = @(
    "s3://corecard-sharedservices-prod-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/",
    "s3://corecard-sharedservices-prod-us-west-2-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    )
}

default {
    Write-Host "Invalid option selected." -ForegroundColor Red
    exit
}


}

$zipPath = "$zipName"

# ========================

# STEP 1.5: Ask Backup Option

# ========================

Write-Host ""
$backupChoice = Read-Host "Do you want to take backup now? (Y/N)"

if ($backupChoice -eq "Y") {

# ========================

# STEP 2: Validate Source

# ========================

if (!(Test-Path $sourcePath)) {
Write-Host "Source folder not found: $sourcePath" -ForegroundColor Red
exit
}

# ========================

# STEP 3: Collect Items

# ========================

$scanErrors = @()

$allItems = Get-ChildItem -Path $sourcePath -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable scanErrors

if ($scanErrors.Count -gt 0) {


Log "Some paths skipped during scan due to long-path, missing-path or access issues."

foreach ($err in $scanErrors) {
    Log "Skipped: $($err.TargetObject)"
}


}

$itemsToCopy = @()

foreach ($item in $allItems) {


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

$totalItems = $itemsToCopy.Count
$currentItem = 0

Write-Host "Total items to copy: $totalItems"

# ========================

# STEP 4: Prepare Destination

# ========================

if (Test-Path $destinationPath) {


Write-Host "Cleaning old backup folder..."
Remove-Item "$destinationPath\*" -Recurse -Force -ErrorAction SilentlyContinue


}
else {


New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null


}

# ========================

# STEP 5: Copy Items

# ========================

foreach ($item in $itemsToCopy) {


$currentItem++
$percent = [math]::Round(($currentItem / $totalItems) * 100, 2)

Write-Progress `
-Activity "Copying Files" `
-Status "$percent% - $($item.FullName)" `
-PercentComplete $percent

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

    Copy-Item `
    -Path $item.FullName `
    -Destination $destItemPath `
    -Force `
    -ErrorAction Stop

}
catch {

    Log "Skipped (copy failed): $($item.FullName) | $($_.Exception.Message)"
    Write-Host "Skipping file due to error: $($item.FullName)" -ForegroundColor Yellow
    continue
}


}

Write-Progress -Activity "Copying Files" -Completed
Write-Host "Backup copy completed."

# ========================

# STEP 6: Validation

# ========================

Write-Host ""
Write-Host "Validating Backup Counts..."

$sourceFiles   = (Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue).Count
$sourceFolders = (Get-ChildItem $sourcePath -Recurse -Directory -ErrorAction SilentlyContinue).Count

$destFiles     = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue).Count
$destFolders   = (Get-ChildItem $destinationPath -Recurse -Directory -ErrorAction SilentlyContinue).Count

Write-Host ""
Write-Host "=========== Backup Validation ===========" -ForegroundColor Cyan

Write-Host "Source Files        : $sourceFiles"
Write-Host "Destination Files   : $destFiles"
Write-Host "Source Folders      : $sourceFolders"
Write-Host "Destination Folders : $destFolders"

if ($sourceFiles -eq $destFiles -and $sourceFolders -eq $destFolders) {


Write-Host ""
Write-Host "Validation PASSED: File and folder counts match." -ForegroundColor Green
Log "Validation PASSED"


}
else {


Write-Host ""
Write-Host "WARNING: File or folder count mismatch!" -ForegroundColor Yellow
Log "Validation WARNING: Source/Destination count mismatch"


}

# ========================

# STEP 7: Create ZIP

# ========================

Write-Host ""
Write-Host "Creating ZIP..."

if (Test-Path $zipPath) {
Remove-Item $zipPath -Force
}

Compress-Archive -Path $destinationPath -DestinationPath $zipPath -CompressionLevel Optimal 
Write-Host "ZIP Created: $zipPath"

# ========================

# STEP 8: Validate ZIP

# ========================

Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$zip.Dispose()

Write-Host "ZIP validation successful."

}
else {


Write-Host ""
Write-Host "Backup step skipped by user." -ForegroundColor Yellow
Log "Backup skipped by user"


}

# ========================
# STEP 9: Upload to S3
# ========================

Write-Host ""
$uploadChoice = Read-Host "Do you want to upload backup ZIP to S3 buckets? (Y/N)"

if ($uploadChoice -eq "Y") {

    # Auto locate ZIP inside backup folder
    $zipPath = Join-Path $backupRoot $zipName

    if (!(Test-Path $zipPath)) {

        Write-Host ""
        Write-Host "ZIP file not found in backup location." -ForegroundColor Red
        Write-Host "Expected location: $zipPath"
        Log "ZIP not found in backup location"
        exit

    }

    Write-Host ""
    Write-Host "Using ZIP file: $zipPath"
    Write-Host "Starting S3 upload..."

    foreach ($s3 in $s3Locations) {

        Write-Host ""
        Write-Host "Uploading to $s3" -ForegroundColor Cyan

        try {

            aws s3 cp "$zipPath" "$s3" --only-show-errors
            Log "Upload successful to $s3"

        }
        catch {

            Log "Upload failed to $s3"
            Write-Host "Upload failed for $s3" -ForegroundColor Red

        }
    }

    Write-Host ""
    Write-Host "S3 upload completed." -ForegroundColor Green

}
else {

    Write-Host "User skipped S3 upload."
    Log "S3 upload skipped"

}
    }

    "2" {
        # ========================
        # API HUB BACKUP
        # ========================

        # ========================
        # STEP 1: Environment Selection
        # ========================
        Write-Host ""
        Write-Host "Select Environment for API HUB backup"
        Write-Host "1. PATUAT"
        Write-Host "2. PATQA"
        Write-Host "3. QA"
        Write-Host "4. DEV"
        Write-Host "5. PERF"
        Write-Host "6. UAT"
        Write-Host "7. PROD"

        $choice = Read-Host "Enter option"
        $CurrentDate = Get-Date -Format "yyyyMMdd"
        $backupRoot = "D:\Backup"

        # Define environment mapping
        $envMap = @{
            "1" = @{ Name="PATUAT"; Source="D:\ApiHub"; Dest="CCHUBE1PATUATB1"; S3=@("s3://corecard-sharedservices-patuat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
            "2" = @{ Name="PATQA";  Source="D:\ApiHub"; Dest="CCHUBE1PATQAB1";  S3=@("s3://corecard-sharedservices-patqa-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
            "3" = @{ Name="QA";     Source="D:\ApiHub"; Dest="CCHUBE1QAB1";     S3=@("s3://corecard-sharedservices-qa-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
            "4" = @{ Name="DEV";    Source="D:\ApiHub"; Dest="CCHUBE1DEVB1";    S3=@("s3://corecard-sharedservices-dev-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
            "5" = @{ Name="PERF";   Source="D:\ApiHub"; Dest="CCHUBE1PERFB1";   S3=@("s3://corecard-sharedservices-perfus-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
            "6" = @{ Name="UAT";    Source="D:\ApiHub"; Dest="CCHUBE1UATB1";    S3=@("s3://corecard-sharedservices-uat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/","s3://corecard-sharedservices-uat-us-west-2-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
            "7" = @{ Name="PROD";   Source="D:\ApiHub"; Dest="CCHUBE1PRODB1";   S3=@("s3://corecard-sharedservices-prod-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/","s3://corecard-sharedservices-prod-us-us-west-2-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
        }

        if (-not $envMap.ContainsKey($choice)) {
            Write-Host "Invalid option selected." -ForegroundColor Red
            exit
        }

        $envInfo = $envMap[$choice]

        # ========================
        # STEP 2: Ask Backup Option
        # ========================
        Write-Host ""
        $backupChoice = Read-Host "Do you want to take API HUB backup now? (Y/N)"

        $sourcePath = $envInfo.Source
        $destinationPath = Join-Path $backupRoot $envInfo.Dest
        $zipPath = "$destinationPath.zip"
        $s3Locations = $envInfo.S3

        # ========================
        # STEP 3: Backup Logic (Copy + ZIP)
        # ========================

        function Backup-ApiHub {
            param($sourcePath,$destinationPath,$zipPath)

            if ($backupChoice -eq "Y") {

                if (!(Test-Path $sourcePath)) {
                    Write-Host "Source folder not found: $sourcePath" -ForegroundColor Red
                    exit
                }

                # Copy items
                Write-Host "Starting copy from $sourcePath to $destinationPath"

                if (Test-Path $destinationPath) {
                    Remove-Item "$destinationPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                }
                else {
                    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                }

                Copy-Item -Path $sourcePath\* -Destination $destinationPath -Recurse -Force

                Write-Host "Copy completed."

                # Create ZIP
                if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
                Compress-Archive -Path $destinationPath -DestinationPath $zipPath -CompressionLevel Optimal
                Write-Host "ZIP Created: $zipPath"

            }
            else {
                Write-Host "Backup skipped by user." -ForegroundColor Yellow
            }
        }

        Backup-ApiHub -sourcePath $sourcePath -destinationPath $destinationPath -zipPath $zipPath

        # ========================
        # STEP 4: Upload to S3
        # ========================
        Write-Host ""
        $uploadChoice = Read-Host "Do you want to upload API HUB backup ZIP to S3? (Y/N)"
        if ($uploadChoice -eq "Y") {
            if (!(Test-Path $zipPath)) {
                Write-Host "ZIP file not found: $zipPath" -ForegroundColor Red
                exit
            }

            foreach ($s3 in $s3Locations) {
                Write-Host "Uploading $zipPath to $s3"
                aws s3 cp "$zipPath" "$s3" --only-show-errors
            }
            Write-Host "Upload completed."
        }
        else { Write-Host "S3 upload skipped by user." }

    }

    default {
        Write-Host "Invalid option selected in main menu." -ForegroundColor Red
        exit
    }

}

Write-Host ""
Write-Host "Backup Script Completed Successfully."