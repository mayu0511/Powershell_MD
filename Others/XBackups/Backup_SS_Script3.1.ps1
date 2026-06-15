######################################################################################################################
# Backup Script: FileSplitter & API HUB  | DEVELOPED BY :: Mahendra Dwivedi
# Version 3.0 | Fixed & Enhanced | Date 26-March-2026
#Update EAST WEST Bucket
######################################################################################################################


Clear-Host
$ErrorActionPreference = "Stop"

# ========================
# Task-1 : Log Setup
# ========================

# Log folder
$logFolder = "C:\Temp"

# Create folder if not exists
if (!(Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

# Log file path (your required format)
$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $logFolder "SS_Backup-$timeStamp.log"

# Create log file
New-Item -ItemType File -Path $logPath -Force | Out-Null

# Logging function
function Log {
    param([string]$msg)

    $time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $finalMsg = "[$time] $msg"

    Write-Host $finalMsg
    Add-Content -Path $logPath -Value $finalMsg
}

# Start log
Log "================ SS BACKUP SCRIPT STARTED ================"
Log "Log File Location: $logPath"

# ========================
# Task-2 : Main Menu
# ========================

Log ""
Log "================ MAIN MENU ================"

Write-Host ""
Write-Host "Select Backup Type:" -ForegroundColor Cyan
Write-Host "1. FileSplitter Backup"
Write-Host "2. API HUB Backup"
Write-Host ""

$choice = Read-Host "Enter your choice (1 or 2)"

switch ($choice) {
    "1" {
        Log "User selected: FileSplitter Backup"
        $backupType = "FileSplitter"
    }
    "2" {
        Log "User selected: API HUB Backup"
        $backupType = "APIHUB"
    }
    default {
        Log "Invalid selection entered: $choice"
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
        exit
    }
}

Log "Selected Backup Type: $backupType"
Log "================ MENU COMPLETED ================"

# ========================
# Task-3 : Environment Selection
# ========================

Log ""
Log "================ ENVIRONMENT SELECTION ================"

Write-Host ""
Write-Host "Select Environment:" -ForegroundColor Cyan
Write-Host "1. PATUAT"
Write-Host "2. PATQA"
Write-Host "3. GS-QA"
Write-Host "4. GS-DEV"
Write-Host "5. GS-UAT"
Write-Host "6. PERF"
Write-Host "7. PROD"
Write-Host ""

$envChoice = Read-Host "Enter your choice (1-7)"

switch ($envChoice) {
    "1" { $envName = "PATUAT" }
    "2" { $envName = "PATQA" }
    "3" { $envName = "GS-QA" }
    "4" { $envName = "GS-DEV" }
    "5" { $envName = "GS-UAT" }
    "6" { $envName = "PERF" }
    "7" { $envName = "PROD" }
    default {
        Log "Invalid environment selection: $envChoice"
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
        exit
    }
}

Log "Selected Environment: $envName"
Log "================ ENVIRONMENT SELECTION COMPLETED ================"


# ========================
# PRE-CLEANUP: Delete all files/folders in D:\Backup
# ========================

Log ""
Log "================ PRE-CLEANUP STARTED ================"

$backupRoot = "D:\Backup"

if (Test-Path $backupRoot) {

    # Ask user
    $deleteChoice = Read-Host "Do you want to delete all existing files and folders in $backupRoot? (Y/N)"

    if ($deleteChoice.Trim().ToUpper() -eq "Y") {

        try {
            # Get all items including hidden/system
            $items = Get-ChildItem -Path $backupRoot -Force

            if ($items.Count -gt 0) {
                foreach ($item in $items) {
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                    Log "Deleted: $($item.FullName)"
                }
                Write-Host "All files/folders in $backupRoot have been deleted." -ForegroundColor Green
                Log "All files/folders in $backupRoot have been deleted."
            }
            else {
                Write-Host "No files/folders found in $backupRoot to delete." -ForegroundColor Cyan
                Log "No files/folders found in $backupRoot to delete."
            }
        }
        catch {
            Log "Error deleting files/folders in $backupRoot $_"
            Write-Host "Failed to delete some items in $backupRoot." -ForegroundColor Red
        }

    } else {
        Log "User chose not to delete existing files/folders in $backupRoot."
        Write-Host "Skipping deletion of existing backup files/folders." -ForegroundColor Yellow
    }

} else {
    Log "$backupRoot does not exist. No cleanup needed."
    Write-Host "$backupRoot does not exist. Skipping pre-cleanup." -ForegroundColor Cyan
}

Log "================ PRE-CLEANUP COMPLETED ================"

# ========================
# Task-4 : Source & Destination Setup
# ========================

Log ""
Log "================ PATH SETUP STARTED ================"

# Get Hostname
$hostname = $env:COMPUTERNAME

# Backup Root
$backupRoot = "D:\Backup"

if ($backupType -eq "FileSplitter") {

    # Source & Destination
    $sourcePath = "D:\DBBSetup"
    $destinationPath = Join-Path $backupRoot "$hostname\DBBSetup"

    # Create destination
    if (!(Test-Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    }

    # Logging
    Log "Backup Type      : FileSplitter"
    Log "Hostname         : $hostname"
    Log "Environment      : $envName"
    Log "Source Path      : $sourcePath"
    Log "Destination Path : $destinationPath"
}

elseif ($backupType -eq "APIHUB") {

    # Source & Destination
    $sourcePath = "D:\ApiHub"
    $destinationPath = Join-Path $backupRoot "$hostname\ApiHub"

    # Create destination
    if (!(Test-Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    }

    # Logging
    Log "Backup Type      : API HUB"
    Log "Hostname         : $hostname"
    Log "Environment      : $envName"
    Log "Source Path      : $sourcePath"
    Log "Destination Path : $destinationPath"
}

Log "================ PATH SETUP COMPLETED ================"

# ========================
# REGION DETECTION
# ========================

Log ""
Log "================ REGION DETECTION STARTED ================"

try {
    $region = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/placement/region" -TimeoutSec 2
    Log "Detected Region from EC2 Metadata: $region"
}
catch {
    Log "EC2 metadata failed, trying AWS CLI..."

    try {
        $region = (aws configure get region).Trim()
        Log "Detected Region from AWS CLI: $region"
    }
    catch {
        $region = "unknown"
        Log "Failed to detect region"
    }
}

if ($region -eq "unknown" -or -not $region) {

    Log "Auto region detection failed. Asking user..."

    Write-Host ""
    Write-Host "Select Region:" -ForegroundColor Cyan
    Write-Host "1. us-east-1"
    Write-Host "2. us-west-2"

    $regionChoice = Read-Host "Enter your choice (1 or 2)"

    switch ($regionChoice) {
        "1" { $region = "us-east-1" }
        "2" { $region = "us-west-2" }
        default {
            Write-Host "Invalid region selection. Exiting..." -ForegroundColor Red
            Log "Invalid region selection"
            exit
        }
    }

    Log "User selected region: $region"
}

Log "================ REGION DETECTION COMPLETED ================"

# ========================
# Task-5 : S3 Path Setup
# ========================

Log ""
Log "================ S3 PATH SETUP STARTED ================"

# Date for S3
$CurrentDate = Get-Date -Format "yyyyMMdd"

# Initialize array
$s3Paths = @()

switch ($envName) {

    "PATUAT" {
        $s3Paths += "s3://corecard-sharedservices-patuat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }

    "PATQA" {
        $s3Paths += "s3://corecard-sharedservices-patqa-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }

    "GS-QA" {
        $s3Paths += "s3://corecard-sharedservices-qa-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }

    "GS-DEV" {
        $s3Paths += "s3://corecard-sharedservices-dev-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }

    "GS-UAT" {
    if ($region -eq "us-east-1") {
        $s3Paths += "s3://corecard-sharedservices-uat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }
    elseif ($region -eq "us-west-2") {
        $s3Paths += "s3://corecard-sharedservices-uat-us-west-2-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }
}

    "PERF" {
        $s3Paths += "s3://corecard-sharedservices-perf-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }

    "PROD" {
    if ($region -eq "us-east-1") {
        $s3Paths += "s3://corecard-sharedservices-prod-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }
    elseif ($region -eq "us-west-2") {
        $s3Paths += "s3://corecard-sharedservices-prod-us-west-2-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    }
}

    default {
        Log "No S3 mapping found for environment: $envName"
        Write-Host "S3 mapping not defined. Exiting..." -ForegroundColor Red
        exit
    }
}

# Logging all S3 paths
foreach ($path in $s3Paths) {
    Log "S3 Upload Path: $path"
}

Log "================ S3 PATH SETUP COMPLETED ================"


# ========================
# Task-5 : Exclusion Rules (FileSplitter Only)
# ========================

Log ""
Log "================ EXCLUSION RULES SETUP ================"

if ($backupType -eq "FileSplitter") {

    # Function to check if item should be excluded
    function Test-Excluded {
        param ($item)

        return (
            $item.Extension -in @(".log",".zip",".pdf",".gpg",".pgp",".ipm",".A001",".A004",".A005",".A006",".Xlsx",".out") -or
            $item.Name -match "^(ACH12|LogFileStep|BulkFileResponse_|MCI.AR.T|ACH-RET-)" -or
            ($item.Extension -eq ".csv" -and $item.Name -ne "amortizationSourceFileinfo.csv")
        )
    }

    Log "Exclusion rules applied for FileSplitter backup"
    Log "Excluded Extensions: .log, .zip, .pdf, .gpg, .pgp, .ipm, .A001, .A004, .A005, .A006, .Xlsx, .out"
    Log "Excluded File Patterns: ACH12*, LogFileStep*, BulkFileResponse_*, MCI.AR.T*, ACH-RET-*"
    Log "CSV Rule: Exclude all .csv except amortizationSourceFileinfo.csv"
}
else {
    Log "No exclusion rules applied (API HUB Backup)"
}

Log "================ EXCLUSION RULES COMPLETED ================"

# ========================
# Task-6 : Copy Data with Progress (with user prompt)
# ========================

Log ""
Log "================ COPY PROCESS STARTED ================"

# Ask user
$skipCopy = $false
$doCopy = Read-Host "Do you want to copy data from source to destination? (Y/N)"

if ($doCopy.Trim().ToUpper() -ne "Y") {
    Log "User chose not to copy data. Skipping copy process."
    Write-Host "Copy process skipped by user." -ForegroundColor Yellow
    $skipCopy = $true
}

if (-not $skipCopy) {

    # Validate source
    if (!(Test-Path $sourcePath)) {
        Log "Source path not found: $sourcePath"
        Write-Host "Source path does not exist. Exiting..." -ForegroundColor Red
        exit
    }

    # ========================
    # STEP 1: Get Source Items
    # ========================

    $allItems = Get-ChildItem -Path $sourcePath -Recurse -Force

    if ($backupType -eq "FileSplitter") {
        $filesToCopy = $allItems | Where-Object { 
            -not $_.PSIsContainer -and -not (Test-Excluded $_)
        }
    } else {
        $filesToCopy = $allItems | Where-Object { -not $_.PSIsContainer }
    }

    $foldersToCreate = $allItems | Where-Object { $_.PSIsContainer }

    # ========================
    # STEP 2: Create ALL folders
    # ========================

    foreach ($folder in $foldersToCreate) {
        $relativePath = $folder.FullName.Substring($sourcePath.Length)
        $targetFolder = Join-Path $destinationPath $relativePath

        if (!(Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
        }
    }

    # ========================
    # STEP 3: Copy Files with Progress
    # ========================

    $totalFiles = $filesToCopy.Count
    $currentFile = 0

    foreach ($file in $filesToCopy) {

        $currentFile++

        $percent = if ($totalFiles -gt 0) {
            [math]::Round(($currentFile / $totalFiles) * 100, 2)
        } else { 100 }

        Write-Progress -Activity "Copying Files..." `
                       -Status "$percent% - $($file.Name)" `
                       -PercentComplete $percent

        $relativePath = $file.FullName.Substring($sourcePath.Length)
        $targetFile = Join-Path $destinationPath $relativePath

        $parent = Split-Path $targetFile
        if (!(Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Copy-Item -Path $file.FullName -Destination $targetFile -Force
    }

    Write-Progress -Activity "Copying Files..." -Completed

    # ========================
    # STEP 4: COUNT ONLY
    # ========================

    $srcFiles   = $filesToCopy.Count
    $srcFolders = $foldersToCreate.Count

    $destFiles   = (Get-ChildItem -Path $destinationPath -Recurse -File).Count
    $destFolders = (Get-ChildItem -Path $destinationPath -Recurse -Directory).Count

    Write-Host ""
    Write-Host "Source  -> Files: $srcFiles | Folders: $srcFolders" -ForegroundColor Cyan
    Write-Host "Dest    -> Files: $destFiles | Folders: $destFolders" -ForegroundColor Cyan

    Log "Source  -> Files: $srcFiles | Folders: $srcFolders"
    Log "Dest    -> Files: $destFiles | Folders: $destFolders"

} else {
    Log "Copy process fully skipped."
}

Log "================ COPY PROCESS COMPLETED ================"

# ========================
# Task-7 : ZIP BACKUP
# ========================

Log ""
Log "================ ZIP PROCESS STARTED ================"

# 7-Zip Path
$sevenZipBase = "D:\CC_Scripts\Powershell_MD\Others\7-Zip"
$sevenZipExe  = Join-Path $sevenZipBase "7z.exe"

if (!(Test-Path $sevenZipExe)) {
    Log "7-Zip not found at: $sevenZipExe"
    Write-Host "7-Zip not found. Exiting..." -ForegroundColor Red
    exit
}

# Ask user
function Get-YesNoResponse($message) {
    $response = Read-Host "$message (Y/N)"
    return $response.Trim().ToLower() -in @("y","yes")
}

# Task- 8 ZIP Function
function Compress-FolderWith7Zip {
    param ($folderPath)

    $zipPath = "$folderPath.zip"
    $tempFile = Join-Path $folderPath "__temp__.txt"

    $isEmpty = -not (Get-ChildItem -Path $folderPath -Recurse -Force)

    if ($isEmpty) {
        New-Item -Path $tempFile -ItemType File | Out-Null
    }

    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    try {
        Log "Zipping: $(Split-Path $folderPath -Leaf)"

        Push-Location $folderPath
        & $sevenZipExe a -tzip $zipPath * -mx=5 | Out-Null
        Pop-Location

        Log "ZIP Created: $zipPath"
    }
    catch {
        Log "ZIP Failed: $folderPath"
    }

    if ($isEmpty -and (Test-Path $tempFile)) {
        Remove-Item $tempFile -Force
    }

    # Validation
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
        Log "Validated: $zipPath"
    }
    catch {
        Log "Invalid ZIP: $zipPath"
    }
}

# ========================
# Task- 9 EXECUTION
# ========================

# ========================
# TASK: ZIP FIRST-LEVEL FOLDERS INSIDE FileSplitter
# ========================

Log ""
Log "================ FILESPLITTER ZIP STARTED ================"

$fileSplitterPath = "D:\Backup\$hostname\DBBSetup\MonitoringScript\FileSplitter"
Log "FileSplitter Backup Path: $fileSplitterPath"

$doZipFS = Get-YesNoResponse "Zip folders inside FileSplitter backup path?"

if ($doZipFS) {

    if (Test-Path $fileSplitterPath) {

        # Get only first-level folders (no recursion)
        $folders = Get-ChildItem -Path $fileSplitterPath -Directory -ErrorAction SilentlyContinue |
                   Sort-Object Name

        if ($folders -and $folders.Count -gt 0) {

            $total = $folders.Count
            $current = 0

            foreach ($folder in $folders) {

                $current++
                $percent = [math]::Round(($current / $total) * 100, 2)

                Write-Progress -Activity "Zipping FileSplitter Folders" `
                               -Status "Processing: $($folder.Name) ($current of $total)" `
                               -PercentComplete $percent

                try {
                    Log "Zipping: $($folder.Name)"
                    Compress-FolderWith7Zip $folder.FullName
                    Log "Completed: $($folder.Name)"
                }
                catch {
                    Log "ERROR: $($folder.FullName) - $_"
                }
            }

            Write-Progress -Activity "Zipping FileSplitter Folders" -Completed
            Log "All FileSplitter folders zipped successfully"

        } else {
            Log "No folders found inside FileSplitter"
        }

        # Optional deletion
        $deleteChoice = Get-YesNoResponse "Delete original folders after zip?"

        if ($deleteChoice -and $folders) {

            $current = 0
            foreach ($folder in $folders) {
                $current++
                $percent = [math]::Round(($current / $total) * 100, 2)

                Write-Progress -Activity "Deleting Original Folders" `
                               -Status "Deleting: $($folder.Name)" `
                               -PercentComplete $percent

                try {
                    Remove-Item $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Log "Deleted: $($folder.Name)"
                }
                catch {
                    Log "Failed to delete: $($folder.FullName)"
                }
            }

            Write-Progress -Activity "Deleting Original Folders" -Completed
        }
        else {
            Log "Skipping deletion of original folders"
        }

    } else {
        Log "FileSplitter path not found: $fileSplitterPath"
    }

} else {
    Log "User skipped FileSplitter zipping."
}

Log "================ FILESPLITTER ZIP COMPLETED ================"

# ========================
# Task-12 : ZIP Main Folder
# ========================

Log ""
Log "================ MAIN ZIP STARTED ================"

$zipMainChoice = Get-YesNoResponse "Do you want to create main backup ZIP?"

if ($zipMainChoice) {

    $hostname = $env:COMPUTERNAME
    $basePath = "D:\Backup\$hostname"
    $mainZip  = "D:\Backup\$hostname.zip"

    # Remove existing zip
    if (Test-Path $mainZip) {
        Remove-Item $mainZip -Force
    }

    try {
        Log "Creating main ZIP..."

        Write-Progress -Activity "Creating main backup ZIP" `
                       -Status "Processing..." `
                       -PercentComplete 30

        Push-Location $basePath
        & $sevenZipExe a -tzip $mainZip * -mx=5 | Out-Null
        Pop-Location

        Write-Progress -Activity "Creating main backup ZIP" `
                       -Status "Finalizing..." `
                       -PercentComplete 90

        Start-Sleep -Milliseconds 500
        Write-Progress -Activity "Creating main backup ZIP" -Completed

        Log "Main ZIP created: $mainZip"
    }
    catch {
        Log "Main ZIP failed: $_"
        return
    }

    # Validation
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($mainZip).Dispose()
        Log "Main ZIP validation successful"
    }
    catch {
        Log "Main ZIP validation failed"
    }

} else {
    Log "Skipped main folder zipping."
}

Log "================ MAIN ZIP COMPLETED ================"


# ========================
# TASK 11: Upload Main Backup ZIP to S3 (SAFE)
# ========================

Log ""
Log "================ S3 UPLOAD STARTED ================"

$mainZip = "D:\Backup\$hostname.zip"

$uploadChoice = Get-YesNoResponse "Do you want to upload the main backup ZIP to S3?"

if ($uploadChoice) {

    if (!(Test-Path $mainZip)) {
        Log "Main backup ZIP not found: $mainZip"
        Write-Host "ZIP file not found: $mainZip" -ForegroundColor Red
    }
    else {
        foreach ($s3 in $s3Paths) {

            $zipFileName = Split-Path $mainZip -Leaf
            $fullS3Path = if ($s3[-1] -ne "/") { "$s3/$zipFileName" } else { "$s3$zipFileName" }

            Write-Host "Uploading $mainZip to $fullS3Path"
            Log "Uploading $mainZip to $fullS3Path"

            try {
                aws s3 cp "$mainZip" "$fullS3Path" --only-show-errors
                Log "Upload completed: $fullS3Path"
                Write-Host "Uploaded to: $fullS3Path" -ForegroundColor Green
            }
            catch {
                Log "Upload failed: $fullS3Path - $_"
                Write-Host "Upload failed: $fullS3Path" -ForegroundColor Red
            }
        }

        Log "Main backup ZIP uploaded successfully."
    }

} else {
    Log "User skipped S3 upload."
    Write-Host "S3 upload skipped by user." -ForegroundColor Yellow
}
Log "Uploading based on detected region: $region"
Log "================ S3 UPLOAD COMPLETED ================"


# ========================
# TASK-12 DOWNLOAD ONLY
# ========================

function Get-Package {

    Log "`n=== DOWNLOAD STARTED ==="

    $choice = Read-Host "Do you want to download the ZIP from S3? (y/n)"
    if ($choice.Trim().ToLower() -ne "y") {
        Log "Download skipped"
        Write-Host "Download skipped" -ForegroundColor Yellow
        return
    }

    $s3Path = Read-Host "Enter full S3 path (including .zip)"
    $downloadDir = "D:\Backup"

    if (!(Test-Path $downloadDir)) {
        New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
    }

    $zipFileName = Split-Path $s3Path -Leaf
    $zipFileLocal = Join-Path $downloadDir $zipFileName

    try {
        Log "Downloading from S3: $s3Path"
        Write-Host "Downloading $zipFileName..." -ForegroundColor Cyan

        aws s3 cp "$s3Path" "$zipFileLocal" --only-show-errors

        Log "Download completed: $zipFileLocal"
        Write-Host "Downloaded to: $zipFileLocal" -ForegroundColor Green

        # Store for unzip
        $global:LastDownloadedZip = $zipFileLocal
    }
    catch {
        Log "ERROR: Download failed - $_"
        Write-Host "Download failed" -ForegroundColor Red
        return
    }

    Log "=== DOWNLOAD COMPLETED ==="
}


# ========================
# TASK-13 UNZIP PACKAGE (AUTO PICK)
# ========================

function Expand-Package {

    Log "`n=== UNZIP STARTED ==="

    $choice = Read-Host "Do you want to unzip the downloaded package? (y/n)"
    if ($choice.Trim().ToLower() -ne "y") {
        Log "Unzip skipped"
        Write-Host "Unzip skipped" -ForegroundColor Yellow
        return
    }

    $zipFile = $global:LastDownloadedZip

    if (!$zipFile -or !(Test-Path $zipFile)) {
        Log "No downloaded ZIP found. Please run download first."
        Write-Host "No downloaded ZIP found. Run download first." -ForegroundColor Red
        return
    }

    $unzipPath = "D:\Backup\Pakcage_Unzip"

    if (!(Test-Path $unzipPath)) {
        New-Item -Path $unzipPath -ItemType Directory -Force | Out-Null
    }

    try {
        Log "Extracting $zipFile to $unzipPath"
        Write-Host "Extracting files..." -ForegroundColor Cyan

        Expand-Archive -Path $zipFile -DestinationPath $unzipPath -Force

        Log "Unzip completed: $unzipPath"
        Write-Host "Unzip completed successfully" -ForegroundColor Green
    }
    catch {
        Log "ERROR: Unzip failed - $_"
        Write-Host "Unzip failed" -ForegroundColor Red
    }

    Log "=== UNZIP COMPLETED ==="
}


# ========================
# EXECUTION FLOW (IMPORTANT)
# ========================

Write-Host ""
Write-Host "================ NEXT STEPS ================" -ForegroundColor Cyan

Get-Package
Expand-Package

# ========================
# TASK-14 UNZIP FILESPLITTER INNER ZIPS
# ========================

function Expand-FileSplitterZips {

    Log "`n=== FILESPLITTER UNZIP STARTED ==="

    $choice = Read-Host "Do you want to unzip all ZIPs inside FileSplitter? (y/n)"
    if ($choice.Trim().ToLower() -ne "y") {
        Log "FileSplitter unzip skipped"
        Write-Host "FileSplitter unzip skipped" -ForegroundColor Yellow
        return
    }

    $fsPath = "D:\Backup\Pakcage_Unzip\DBBSetup\MonitoringScript\FileSplitter"

    if (!(Test-Path $fsPath)) {
        Log "FileSplitter path not found: $fsPath"
        Write-Host "FileSplitter path not found" -ForegroundColor Red
        return
    }

    # Get all ZIP files
    $zipFiles = Get-ChildItem -Path $fsPath -Filter *.zip -File -ErrorAction SilentlyContinue

    if (!$zipFiles -or $zipFiles.Count -eq 0) {
        Log "No ZIP files found in FileSplitter folder"
        Write-Host "No ZIP files found" -ForegroundColor Yellow
        return
    }

    $total = $zipFiles.Count
    $current = 0

    foreach ($zip in $zipFiles) {

        $current++
        $percent = [math]::Round(($current / $total) * 100, 2)

        Write-Progress -Activity "Unzipping FileSplitter ZIPs" `
                       -Status "Processing: $($zip.Name)" `
                       -PercentComplete $percent

        # Extract into folder with same name
        $destFolder = Join-Path $fsPath ($zip.BaseName)

        if (!(Test-Path $destFolder)) {
            New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
        }

        try {
            Log "Extracting: $($zip.FullName) to $destFolder"

            Expand-Archive -Path $zip.FullName -DestinationPath $destFolder -Force

            Log "Completed: $($zip.Name)"
        }
        catch {
            Log "ERROR extracting $($zip.Name): $_"
        }
    }

    Write-Progress -Activity "Unzipping FileSplitter ZIPs" -Completed

    Write-Host "All FileSplitter ZIPs extracted" -ForegroundColor Green
    Log "All FileSplitter ZIPs extracted successfully"

    Log "=== FILESPLITTER UNZIP COMPLETED ==="
}

Expand-FileSplitterZips

# ========================
# TASK-15 DEPLOY CODE (WITH PROGRESS)
# ========================

function Invoke-Deployment {

    Log "`n=== DEPLOYMENT STARTED ==="

    $choice = Read-Host "Do you want to deploy code to D:\DBBSetup? (y/n)"
    if ($choice.Trim().ToLower() -ne "y") {
        Log "Deployment skipped"
        Write-Host "Deployment skipped" -ForegroundColor Yellow
        return
    }

    $sourcePath = "D:\Backup\Pakcage_Unzip\DBBSetup"
    $destinationPath = "D:\DBBSetup"

    # Validate source
    if (!(Test-Path $sourcePath)) {
        Log "Source path not found: $sourcePath"
        Write-Host "Source path not found" -ForegroundColor Red
        return
    }

    # Create destination if not exists
    if (!(Test-Path $destinationPath)) {
        New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
    }

    try {
        Log "Deploying from $sourcePath to $destinationPath"
        Write-Host "Deploying files..." -ForegroundColor Cyan

        # Get all items
        $allItems = Get-ChildItem -Path $sourcePath -Recurse -Force

        $files = $allItems | Where-Object { -not $_.PSIsContainer }
        $folders = $allItems | Where-Object { $_.PSIsContainer }

        # Create folders first
        foreach ($folder in $folders) {
            $relativePath = $folder.FullName.Substring($sourcePath.Length)
            $targetFolder = Join-Path $destinationPath $relativePath

            if (!(Test-Path $targetFolder)) {
                New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
            }
        }

        # Copy files with progress
        $totalFiles = $files.Count
        $current = 0

        foreach ($file in $files) {

            $current++

            $percent = if ($totalFiles -gt 0) {
                [math]::Round(($current / $totalFiles) * 100, 2)
            } else { 100 }

            Write-Progress -Activity "Deploying Files..." `
                           -Status "$percent% - $($file.Name)" `
                           -PercentComplete $percent

            $relativePath = $file.FullName.Substring($sourcePath.Length)
            $targetFile = Join-Path $destinationPath $relativePath

            $parent = Split-Path $targetFile
            if (!(Test-Path $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            Copy-Item -Path $file.FullName -Destination $targetFile -Force
        }

        Write-Progress -Activity "Deploying Files..." -Completed

        Log "Deployment completed successfully"
        Write-Host "Deployment completed successfully" -ForegroundColor Green
    }
    catch {
        Log "ERROR: Deployment failed - $_"
        Write-Host "Deployment failed" -ForegroundColor Red
    }

    Log "=== DEPLOYMENT COMPLETED ==="
}

Invoke-Deployment

# ========================
# TASK-16 CLEANUP + VALIDATION
# ========================

function Clear-AndValidateDeployment {

    Log "`n=== CLEANUP & VALIDATION STARTED ==="

    $choice = Read-Host "Do you want to cleanup ZIP files and validate deployment? (y/n)"
    if ($choice.Trim().ToLower() -ne "y") {
        Log "Cleanup & validation skipped"
        Write-Host "Cleanup & validation skipped" -ForegroundColor Yellow
        return
    }

    $sourcePath = "D:\Backup\Pakcage_Unzip\DBBSetup"
    $destinationPath = "D:\DBBSetup"

    # ========================
    # STEP 1: DELETE ZIP FILES
    # ========================

    try {
        Log "Removing ZIP files from $destinationPath"

        $zipFiles = Get-ChildItem -Path $destinationPath -Recurse -Filter *.zip -ErrorAction SilentlyContinue

        if ($zipFiles.Count -gt 0) {
            foreach ($zip in $zipFiles) {
                Remove-Item $zip.FullName -Force -ErrorAction SilentlyContinue
                Log "Deleted ZIP: $($zip.FullName)"
            }
            Write-Host "ZIP files removed from destination" -ForegroundColor Green
        } else {
            Log "No ZIP files found in destination"
            Write-Host "No ZIP files found to delete" -ForegroundColor Cyan
        }
    }
    catch {
        Log "ERROR deleting ZIP files: $_"
        Write-Host "Error during ZIP cleanup" -ForegroundColor Red
    }

    # ========================
    # STEP 2: COMPARE COUNTS
    # ========================

    try {
        Log "Comparing source and destination counts"

        $srcFiles   = (Get-ChildItem -Path $sourcePath -Recurse -File).Count
        $srcFolders = (Get-ChildItem -Path $sourcePath -Recurse -Directory).Count

        $destFiles   = (Get-ChildItem -Path $destinationPath -Recurse -File).Count
        $destFolders = (Get-ChildItem -Path $destinationPath -Recurse -Directory).Count

        Write-Host ""
        Write-Host "===== DEPLOYMENT VALIDATION =====" -ForegroundColor Cyan
        Write-Host "Source      -> Files: $srcFiles | Folders: $srcFolders" -ForegroundColor Yellow
        Write-Host "Destination -> Files: $destFiles | Folders: $destFolders" -ForegroundColor Yellow

        Log "Source      -> Files: $srcFiles | Folders: $srcFolders"
        Log "Destination -> Files: $destFiles | Folders: $destFolders"

        # Result check
        if ($srcFiles -eq $destFiles -and $srcFolders -eq $destFolders) {
            Write-Host "VALIDATION SUCCESS: Counts match" -ForegroundColor Green
            Log "VALIDATION SUCCESS: Source and Destination match"
        } else {
            Write-Host "VALIDATION WARNING: Counts do NOT match" -ForegroundColor Red
            Log "VALIDATION WARNING: Mismatch detected"
        }

    }
    catch {
        Log "ERROR during validation: $_"
        Write-Host "Validation failed" -ForegroundColor Red
    }

    Log "=== CLEANUP & VALIDATION COMPLETED ==="
}

Clear-AndValidateDeployment