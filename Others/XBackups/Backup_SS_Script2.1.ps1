######################################################################################################################
# Backup Script: FileSplitter & API HUB  | DEVELOPED BY :: Mahendra Dwivedi
# Version 2.0 | Fixed & Enhanced
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

Write-Host ""
Write-Host "Select Environment"
Write-Host "1. PATUAT"
Write-Host "2. PROD"

$choice = Read-Host "Enter option"

$CurrentDate = Get-Date -Format "yyyyMMdd"
$sourcePath = "D:\DBBSetup"
$backupRoot = "D:\Backup"

# ========================
# STEP 1.1: EXCLUDE PATHS (NEW)
# ========================
$excludePaths = @(
"D:\DBBSetup\MonitoringScript\BaxterIPM\JSONFileParsingUtility\Log"
)

switch ($choice) {

"1" {
    $environment = "PATUAT"
    $destinationPath = "$backupRoot\CCFSE1PATUATB1\DBBSetup"
    $zipPath = "$backupRoot\CCFSE1PATUATB1.zip"

    $s3Locations = @(
    "s3://corecard-sharedservices-patuat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/"
    )
}

"2" {
    $environment = "PROD"
    $destinationPath = "$backupRoot\CCFSE1PRODB1\DBBSetup"
    $zipPath = "$backupRoot\CCFSE1PRODB1.zip"

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
    Log "Scan warnings detected"
}

$itemsToCopy = @()

foreach ($item in $allItems) {

# ?? EXCLUDE PATH LOGIC (NEW)
if ($excludePaths | Where-Object { $item.FullName -like "$_*" }) {
    continue
}

if ($item.PSIsContainer -and $item.Name -in @()) {
    continue
}
elseif (-not $item.PSIsContainer -and (
    $item.Extension -in @(".log",".zip",".pdf",".gpg",".pgp",".ipm",".A001",".A004",".A005",".A006",".Xlsx",".out") -or
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
    Remove-Item "$destinationPath\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
}

# ========================
# STEP 5: Copy Items
# ========================
foreach ($item in $itemsToCopy) {

$currentItem++
$percent = [math]::Round(($currentItem / $totalItems) * 100, 2)

Write-Progress -Activity "Copying Files" -Status "$percent%" -PercentComplete $percent

$destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)
$destFolder = Split-Path $destItemPath -Parent

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
    Log "Copy failed: $($item.FullName)"
}
}

Write-Host "Backup copy completed."

# ========================
# STEP 6: Validation
# ========================

Write-Host ""
Write-Host "Validating Backup Counts..." -ForegroundColor Cyan

# Source counts
$sourceFiles   = (Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue).Count
$sourceFolders = (Get-ChildItem $sourcePath -Recurse -Directory -ErrorAction SilentlyContinue).Count

# Destination counts
$destFiles     = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue).Count
$destFolders   = (Get-ChildItem $destinationPath -Recurse -Directory -ErrorAction SilentlyContinue).Count

Write-Host ""
Write-Host "=========== Backup Validation ===========" -ForegroundColor Cyan

Write-Host "Source Files        : $sourceFiles"
Write-Host "Destination Files   : $destFiles"
Write-Host "Source Folders      : $sourceFolders"
Write-Host "Destination Folders : $destFolders"

# Detailed comparison
if ($sourceFiles -eq $destFiles -and $sourceFolders -eq $destFolders) {

    Write-Host ""
    Write-Host "Validation PASSED: Files and folders count match." -ForegroundColor Green
    Log "Validation PASSED: Files=$sourceFiles Folders=$sourceFolders"

}
else {

    Write-Host ""
    Write-Host "WARNING: Count mismatch detected!" -ForegroundColor Yellow

    if ($sourceFiles -ne $destFiles) {
        Write-Host "File count mismatch: Source=$sourceFiles Destination=$destFiles" -ForegroundColor Yellow
        Log "File mismatch: Source=$sourceFiles Destination=$destFiles"
    }

    if ($sourceFolders -ne $destFolders) {
        Write-Host "Folder count mismatch: Source=$sourceFolders Destination=$destFolders" -ForegroundColor Yellow
        Log "Folder mismatch: Source=$sourceFolders Destination=$destFolders"
    }

}

# ========================
# STEP 7: Create ZIP
# ========================
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path $destinationPath -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host "ZIP Created: $zipPath"

}
# ========================
# STEP 8: Validate ZIP
# ========================

Write-Host ""
Write-Host "Validating ZIP file..." -ForegroundColor Cyan

if (!(Test-Path $zipPath)) {
    Write-Host "ZIP file not found for validation!" -ForegroundColor Red
    Log "ZIP validation FAILED - file not found"
    exit
}

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

    $entryCount = $zip.Entries.Count
    $zip.Dispose()

    if ($entryCount -gt 0) {
        Write-Host "ZIP validation PASSED. Entries found: $entryCount" -ForegroundColor Green
        Log "ZIP validation PASSED. Entries=$entryCount"
    }
    else {
        Write-Host "ZIP validation FAILED: ZIP is empty!" -ForegroundColor Red
        Log "ZIP validation FAILED - empty zip"
    }
}
catch {
    Write-Host "ZIP validation FAILED: Corrupt or unreadable ZIP!" -ForegroundColor Red
    Log "ZIP validation FAILED - corrupt zip"
}
# ========================
# STEP 9: Upload to S3
# ========================
Write-Host ""
$uploadChoice = Read-Host "Upload to S3? (Y/N)"

if ($uploadChoice -eq "Y") {

if (!(Test-Path $zipPath)) {
    Write-Host "ZIP not found!" -ForegroundColor Red
    exit
}

foreach ($s3 in $s3Locations) {
    try {
        aws s3 cp "$zipPath" "$s3" --only-show-errors
        Write-Host "Uploaded to $s3"
    }
    catch {
        Write-Host "Upload failed: $s3" -ForegroundColor Red
    }
}
}

}
"2" {

    # ========================
    # STEP 1: ENV SELECTION
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

    # ========================
    # STEP 2: ENV CONFIG
    # ========================
    $envMap = @{
        "1" = @{ Name="PATUAT"; Source="D:\ApiHub"; Dest="CCHUBE1PATUATB1"; S3=@("s3://corecard-sharedservices-patuat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
        "2" = @{ Name="PATQA";  Source="D:\ApiHub"; Dest="CCHUBE1PATQAB1";  S3=@("s3://corecard-sharedservices-patqa-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
        "3" = @{ Name="QA";     Source="D:\ApiHub"; Dest="CCHUBE1QAB1";     S3=@("s3://corecard-sharedservices-qa-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
        "4" = @{ Name="DEV";    Source="D:\ApiHub"; Dest="CCHUBE1DEVB1";    S3=@("s3://corecard-sharedservices-dev-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
        "5" = @{ Name="PERF";   Source="D:\ApiHub"; Dest="CCHUBE1PERFB1";   S3=@("s3://corecard-sharedservices-perf-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
        "6" = @{ Name="UAT";    Source="D:\ApiHub"; Dest="CCHUBE1UATB1";    S3=@("s3://corecard-sharedservices-uat-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/","s3://corecard-sharedservices-uat-us-west-2-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
        "7" = @{ Name="PROD";   Source="D:\ApiHub"; Dest="CCHUBE1PRODB1";   S3=@("s3://corecard-sharedservices-prod-us-east-1-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/","s3://corecard-sharedservices-prod-us-west-2-config-files/Incoming/corecard/CC_BACKUP/$CurrentDate/") }
    }

    if (-not $envMap.ContainsKey($choice)) {
        Write-Host "Invalid option selected." -ForegroundColor Red
        break
    }

    $envInfo = $envMap[$choice]

    $sourcePath = $envInfo.Source
    $destinationPath = Join-Path $backupRoot $envInfo.Dest
    $zipPath = "$destinationPath.zip"
    $s3Locations = $envInfo.S3

    # ========================
    # STEP 3: CONFIRM BACKUP
    # ========================
    Write-Host ""
    if ($backupChoice -ne "Y") {
    Write-Host "Backup skipped." -ForegroundColor Yellow
}
else {

    # ========================
    # STEP 4: VALIDATE SOURCE
    # ========================
    if (!(Test-Path $sourcePath)) {
        Write-Host "Source not found: $sourcePath" -ForegroundColor Red
        return
    }

    # ========================
    # STEP 5: COPY DATA
    # ========================
    Write-Host "Copy started..."

    if (Test-Path $destinationPath) {
        Remove-Item "$destinationPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    }

    Copy-Item "$sourcePath\*" $destinationPath -Recurse -Force
    Write-Host "Copy completed."
}

    # ========================
    # STEP 4: VALIDATE SOURCE
    # ========================
    if (!(Test-Path $sourcePath)) {
        Write-Host "Source not found: $sourcePath" -ForegroundColor Red
        break
    }

    # ========================
    # STEP 5: COPY DATA
    # ========================
    Write-Host "Copy started..."

    if (Test-Path $destinationPath) {
        Remove-Item "$destinationPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    }

    Copy-Item "$sourcePath\*" $destinationPath -Recurse -Force

    Write-Host "Copy completed."

    # ========================
    # STEP 6: VALIDATE COUNT
    # ========================
    $srcFiles = (Get-ChildItem $sourcePath -Recurse -File).Count
    $srcFolders = (Get-ChildItem $sourcePath -Recurse -Directory).Count

    $destFiles = (Get-ChildItem $destinationPath -Recurse -File).Count
    $destFolders = (Get-ChildItem $destinationPath -Recurse -Directory).Count

    Write-Host "Source Files: $srcFiles | Destination Files: $destFiles"
    Write-Host "Source Folders: $srcFolders | Destination Folders: $destFolders"

    if ($srcFiles -ne $destFiles -or $srcFolders -ne $destFolders) {
        Write-Host "WARNING: Count mismatch!" -ForegroundColor Yellow
    } else {
        Write-Host "Count validation PASSED." -ForegroundColor Green
    }

    # ========================
    # STEP 7: CREATE ZIP
    # ========================
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    Compress-Archive -Path $destinationPath -DestinationPath $zipPath

    Write-Host "ZIP created: $zipPath"

    # ========================
    # STEP 8: ZIP VALIDATION
    # ========================
    if (!(Test-Path $zipPath)) {
        Write-Host "ZIP not found!" -ForegroundColor Red
        break
    }

    $zipSize = (Get-Item $zipPath).Length
    Write-Host "ZIP Size: $zipSize bytes"

    if ($zipSize -le 0) {
        Write-Host "ZIP is empty!" -ForegroundColor Red
        break
    }

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        $count = $zip.Entries.Count
        $zip.Dispose()

        Write-Host "ZIP Entries: $count"

        if ($count -eq 0) {
            Write-Host "ZIP is empty!" -ForegroundColor Red
            break
        }
    }
    catch {
        Write-Host "ZIP corrupted!" -ForegroundColor Red
        break
    }

    Write-Host "ZIP validation PASSED."

    # ========================
    # STEP 9: UPLOAD TO S3
    # ========================
    Write-Host ""
    $uploadChoice = Read-Host "Upload to S3? (Y/N)"
    if (!(Test-Path $zipPath)) {
    Write-Host "ZIP not available. Skipping upload." -ForegroundColor Yellow
}
else {

    if ($uploadChoice -eq "Y") {

        foreach ($s3 in $s3Locations) {

            $fileName = Split-Path $zipPath -Leaf
            $fullPath = "$s3$fileName"

            Write-Host "Uploading to: $fullPath"

            try {
                aws s3 cp "$zipPath" "$fullPath"
            }
            catch {
                Write-Host "Upload failed: $fullPath" -ForegroundColor Red
                continue
            }

            Write-Host "Verifying..."
            aws s3 ls "$s3" | Select-String $fileName
        }

        Write-Host "Upload completed."
    }
    }
    # ========================
    # STEP 10: DOWNLOAD & DEPLOY
    # ========================
    Write-Host ""
    if ((Read-Host "Download package? (yes/no)") -eq "yes") {

        $s3Path = Read-Host "Enter full S3 file path"
        $downloadDir = "D:\Backup"
        $zipLocal = Join-Path $downloadDir (Split-Path $s3Path -Leaf)

        try {
            aws s3 cp $s3Path $zipLocal
        }
        catch {
            Write-Host "Download failed!" -ForegroundColor Red
            break
        }

        if (!(Test-Path $zipLocal)) {
            Write-Host "ZIP not downloaded!" -ForegroundColor Red
            break
        }

        $unzipFolder = "D:\Backup\Package_Unzip"
        if (Test-Path $unzipFolder) { Remove-Item $unzipFolder -Recurse -Force }

        Expand-Archive $zipLocal $unzipFolder -Force

        if ((Read-Host "Deploy files? (yes/no)") -eq "yes") {

            $dbbFolder = Get-ChildItem $unzipFolder -Recurse -Directory |
            Where-Object { $_.Name -eq "DBBSetup" } |
            Select-Object -First 1

            if (-not $dbbFolder) {
                Write-Host "DBBSetup folder not found!" -ForegroundColor Red
                break
            }

            Copy-Item $dbbFolder.FullName "D:\DBBSetup" -Recurse -Force

            Write-Host "Deployment Completed"
        }
    }

}}