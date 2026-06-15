############################################################################################################
# Backup Script | DEVELOPED BY:: Mahendra Dwivedi
# Version 4.0 | ORIGINAL STYLE (Empty Folder Fix Added, No Minimization)
############################################################################################################

Clear-Host
$ErrorActionPreference = "Stop"

# ========================
# Task-1 LOGGING START
# ========================

$logDir = "C:\Temp"

if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$logDir\Full_Backup_Task_$timestamp.log"

Start-Transcript -Path $logFile -Append

# ========================
# Task- 2 VARIABLES
# ========================

$hostname = $env:COMPUTERNAME
$hostnameLower = $hostname.ToLower()
$currentdate = Get-Date -Format "yyyyMMdd"

$destinationRoot = "D:\Backup\$hostname"
$zipFile = "D:\Backup\$hostname.zip"

# ========================
# Task- 3 LOG FUNCTION
# ========================

function Log {
    param([string]$msg)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $msg"
}

Log "===== BACKUP SCRIPT STARTED ====="
Log "Hostname: $hostname"

# ========================
# Task- 4 SERVER TYPE DETECTION
# ========================

Log "Detecting Server Type..."

switch -Regex ($hostnameLower) {

    "ccsvc|ccsrc|ccsnk" {
        $ServerType = "Application"
        $sources = @("D:\DBBSetup")
        $singleFile = ""
    }

    "ccweb|ccew" {
        $ServerType = "Web"
        $sources = @("D:\WebServer")
        $singleFile = ""
    }

    "cckms" {
        $ServerType = "Kms"
        $sources = @("D:\KMS")
        $singleFile = ""
    }

    "ccwcf" {
        $ServerType = "WCF"
        $sources = @("D:\WebServer")
        $singleFile = ""
    }

    "ccbat" {
        $ServerType = "Batch"
        $sources = @(
            "D:\DBBSetup",
            "C:\Users\ccgs-app-rw\AppData\Roaming\gnupg"
        )
        $singleFile = "D:\DBBSetup\VisualCron\Backups\VC-Settings.zip"
    }

    "ccrpd" {
        $ServerType = "ReportDelivery"
        $sources = @("D:\ReportDelivery")
        $singleFile = ""
    }

    "ccrps" {
        $ServerType = "ReportServer"
        $sources = @("D:\Reportserver")
        $singleFile = ""
    }

    default {
        Log "ERROR: Server type detection failed."
        Stop-Transcript
        exit
    }
}

Log "Server Type Detected: $ServerType"

# ========================
# Task- 5 REGION DETECTION
# ========================

Log "Detecting Region..."

if ($hostnameLower -match "e1") {
    $Region = "us-east-1"
}
elseif ($hostnameLower -match "w2") {
    $Region = "us-west-2"
}
else {
    Log "ERROR: Region detection failed"
    Stop-Transcript
    exit
}

Log "Region: $Region"

# ========================
# Task- 6 POD DETECTION
# ========================

Log "Fetching POD tag from AWS..."

try {
    $pod = (aws ec2 describe-instances `
        --filters "Name=tag:Name,Values=$hostnameLower" `
        --region $Region `
        --query "Reservations[*].Instances[*].Tags[?Key=='pod'].Value" `
        --output text).Trim().ToLower()

    if (-not $pod) {
        throw "POD value is empty"
    }

    Log "POD: $pod"
}
catch {
    Log "ERROR: Failed to detect POD - $_"
    Stop-Transcript
    exit
}

# ========================
# Task- 7 ENV DETECTION
# ========================

Log "Detecting Environment..."

if ($hostnameLower -match "patqa") {
    $envName = "patqa"
}
elseif ($hostnameLower -match "perf") {
    $envName = "perf"
}
elseif ($hostnameLower -match "uat") {
    $envName = "uat"
}
elseif ($hostnameLower -match "dev") {
    $envName = "dev"
}
elseif ($hostnameLower -match "qa") {
    $envName = "qa"
}
elseif ($hostnameLower -match "patuat") {
    $envName = "patuat"
}
elseif ($hostnameLower -match "prod") {
    $envName = "prod"
}
else {
    Log "ERROR: Environment detection failed"
    Stop-Transcript
    exit
}

Log "Environment: $envName"

# ========================
# Task- 8 S3 PATH
# ========================

$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"

Log "S3 Bucket Path: $bucketPath"
Log "===== INITIAL TASKS COMPLETED ====="

# ========================
# Task- 9 EXCLUDE FILE PATHS
# ========================

$excludeFilePaths = @(
    "D:\DBBSetup\MonitoringScript\BaxterIPM\JSONFileParsingUtility\Log",
    "D:\Backup\CCBATE1QAB22\DBBSetup\MonitoringScript\AuthSourceSinkStatus\Log",
    "D:\Backup\CCBATE1QAB22\DBBSetup\MonitoringScript\InterPOD_Transfer\DailyFiles\2021-12-27\CoreIssue\6-6969"
)

# ========================
# Task- 10 BACKUP FUNCTION
# ========================

# ========================
# EXCLUDE RULES (MULTIPLE PATHS)
# ========================

$excludeTxtPaths = @(
    "D:\DBBSetup\MonitoringScript\PlatStatementAudit\*",
    "D:\DBBSetup\MonitoringScript\Audit\*",
    "D:\DBBSetup\MonitoringScript\MidMonth"
)

function Run-Backup {

    Log "===== BACKUP STARTED ====="

    if (!(Test-Path $destinationRoot)) {
        New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
        Log "Created destination root: $destinationRoot"
    }

    foreach ($sourcePath in $sources) {

        Log "Processing Source: $sourcePath"

        if (!(Test-Path $sourcePath)) {
            Log "WARNING: Source not found: $sourcePath"
            continue
        }

        $destinationPath = Join-Path $destinationRoot (Split-Path $sourcePath -Leaf)

        if (!(Test-Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        }

        $itemsToCopy = Get-ChildItem $sourcePath -Recurse -Force -ErrorAction SilentlyContinue

        $itemsToCopy = $itemsToCopy | Where-Object {

            if ($_.PSIsContainer) { return $true }

            # Exclude .txt from multiple paths
        foreach ($path in $excludeTxtPaths) {
        if ($_.FullName -like $path -and $_.Extension -eq ".txt") {
        return $false
     }
    }

            if ($ServerType -eq "ReportDelivery" -and $_.Extension -in @(".log",".txt")) { return $false }

            if ($_.Extension -in @(".zip",".pdf",".gpg",".pgp",".ipm",".A001",".A004",".A005",".A006",".xlsx",".out",".log",".html")) { return $false }

            if ($_.Name -match "^(ACH12|LogFileStep|BulkFileResponse_|MCI.AR.T|YTF.AR.T120|IPM_|ACHProcessStep_|ACH-RET-)") { return $false }

            if ($_.Extension -eq ".csv" -and $_.Name -ne "amortizationSourceFileinfo.csv") { return $false }

            return $true
        }

        $totalItems = $itemsToCopy.Count
        $currentItem = 0

        foreach ($item in $itemsToCopy) {

            $currentItem++

            $percent = if ($totalItems -gt 0) {
                [math]::Round(($currentItem / $totalItems) * 100, 2)
            } else { 100 }

            Write-Progress -Activity "Copying Files" `
                           -Status "$percent% - $($item.FullName)" `
                           -PercentComplete $percent

            $destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)
            $destFolder = Split-Path $destItemPath -Parent

            if (!(Test-Path $destFolder)) {
                New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
            }

            # Empty folder handling
            if ($item.PSIsContainer) {

                if (!(Test-Path $destItemPath)) {
                    New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null
                }

                continue
            }

            # File copy
            try {
                Copy-Item $item.FullName $destItemPath -Force -ErrorAction Stop
            }
            catch {
                Log "Skipped file: $($item.FullName)"
            }
        }

        Write-Progress -Activity "Copying Files" -Completed

        # ========================
        # Task- 13 COUNTS
        # ========================

        $sourceFileCount   = (Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue).Count
        $sourceFolderCount = (Get-ChildItem $sourcePath -Recurse -Directory -ErrorAction SilentlyContinue).Count

        $destFileCount     = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue).Count
        $destFolderCount   = (Get-ChildItem $destinationPath -Recurse -Directory -ErrorAction SilentlyContinue).Count

        $size = (Get-ChildItem $destinationPath -Recurse -File | Measure-Object Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)

        Log "Summary for ${sourcePath}:"
        Log "Source Files       : $sourceFileCount"
        Log "Source Folders     : $sourceFolderCount"
        Log "Destination Files  : $destFileCount"
        Log "Destination Folders: $destFolderCount"
        Log "Backup Size (MB)   : $sizeMB"
    }

    if ($singleFile -and (Test-Path $singleFile)) {
        Copy-Item $singleFile $destinationRoot -Force
        Log "Copied single file: $singleFile"
    }

    Log "===== BACKUP COMPLETED SUCCESSFULLY ====="
}

# ========================
# FINAL STEP - USER INPUT
# ========================

Log "Waiting for user input to start backup..."

$userInput = Read-Host "Do you want to take backup? (Y/N)"

if ($userInput -match "^[Yy]$") {
    Log "User confirmed backup"
    Run-Backup
}
else {
    Log "User skipped backup"
}

Stop-Transcript

# ========================
# TASK EXPORT (BEFORE ZIP)
# ========================

Log "`n=== TASK EXPORT (BEFORE ZIP) ==="

$taskExportDir = "D:\Backup\$hostname\Task"

if (-not (Test-Path $taskExportDir)) {
    New-Item -Path $taskExportDir -ItemType Directory -Force | Out-Null
    Log "Created Task export directory: $taskExportDir"
}

$doExport = Read-Host "Do you want to EXPORT tasks? (yes/no)"

if ($doExport.Trim().ToLower() -eq "yes") {

    $tasks = Get-ScheduledTask | Where-Object {
        $_.TaskPath -eq "\" -and $_.TaskName -like "Task_*"
    }

    if (-not $tasks) {
        Log "No tasks found to export"
    }
    else {
        foreach ($task in $tasks) {
            try {
                $xml = Export-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
                $filePath = Join-Path $taskExportDir "$($task.TaskName).xml"
                $xml | Out-File -FilePath $filePath -Encoding UTF8
                Log "Exported Task: $($task.TaskName)"
            }
            catch {
                Log "FAILED to export Task: $($task.TaskName) - $_"
            }
        }
    }
}
else {
    Log "Skipping TASK EXPORT..."
}

# ========================
# Task- 14 ZIP BACKUP WITH USER INPUT
# ========================

$basePath = "D:\Backup\$hostname"
$dbbPath = Join-Path $basePath "DBBSetup"
$monitorPath = Join-Path $dbbPath "MonitoringScript"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Ask-YesNo($message) {
    $response = Read-Host "$message (Y/N)"
    return $response.Trim().ToLower() -in @("y","yes")
}

function Zip-FolderWithEmptySupport {
    param ($folderPath)

    $zipPath = "$folderPath.zip"
    $tempFile = Join-Path $folderPath "__temp__.txt"
    $isEmpty = -not (Get-ChildItem -Path $folderPath -Recurse -Force)

    if ($isEmpty) {
        New-Item -Path $tempFile -ItemType File | Out-Null
    }

    Log "Zipping: $(Split-Path $folderPath -Leaf)"
    Compress-Archive -Path $folderPath -DestinationPath $zipPath -Force

    if ($isEmpty -and (Test-Path $tempFile)) {
        Remove-Item $tempFile -Force
    }

    try {
        [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
        Log "Validated: $zipPath"
    } catch {
        Log "Invalid ZIP: $zipPath"
    }
}

# ---------------- STEP 1 ----------------
Log "`nSTEP 1: MonitoringScript"

if (Ask-YesNo "Zip folders inside MonitoringScript?") {

    $folders = Get-ChildItem -Path $monitorPath -Directory

    foreach ($folder in $folders) {
        Zip-FolderWithEmptySupport $folder.FullName
    }

    if (Ask-YesNo "Delete original folders from MonitoringScript?") {
        foreach ($folder in $folders) {
            Remove-Item $folder.FullName -Recurse -Force
            Log "Deleted: $($folder.Name)"
        }
    }
}

# -------- STEP 2 --------
Log "`nProceeding to DBBSetup..."
$continueStep2 = Ask-YesNo "Do you want to continue and zip folders inside DBBSetup?"

if ($continueStep2) {

    Log "`nSTEP 2: DBBSetup"

    $folders = Get-ChildItem -Path $dbbPath -Directory

    foreach ($folder in $folders) {
        Zip-FolderWithEmptySupport $folder.FullName
    }

    if (Ask-YesNo "Delete original folders from DBBSetup?") {
        foreach ($folder in $folders) {
            Remove-Item $folder.FullName -Recurse -Force
            Log "Deleted: $($folder.Name)"
        }
    }
} else {
    Log "Skipped DBBSetup processing."
}

# ---------------- STEP 3 ----------------
Write-Host "`nSTEP 3: Main Folder" -ForegroundColor Cyan

$zipMainChoice = Read-Host "Do you want to create main backup ZIP? (yes/no)"

if ($zipMainChoice -eq "yes") {

    $hostname = $env:COMPUTERNAME
    $basePath = "D:\Backup\$hostname"
    $mainZip = "D:\Backup\$hostname.zip"

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    function Create-ZipSafe {
        param (
            [string]$sourcePath,
            [string]$zipPath
        )

        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }

        try {
            Write-Host "Zipping main folder..." -ForegroundColor Cyan

            [System.IO.Compression.ZipFile]::CreateFromDirectory(
                $sourcePath,
                $zipPath,
                [System.IO.Compression.CompressionLevel]::Optimal,
                $false
            )

            Write-Host "ZIP created successfully: $zipPath" -ForegroundColor Green
        }
        catch {
            Write-Host "ZIP failed: $_" -ForegroundColor Red
            return
        }

        # ? Validate ZIP
        try {
            [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
            Write-Host "ZIP validation successful" -ForegroundColor Green
        }
        catch {
            Write-Host "ZIP validation failed" -ForegroundColor Red
        }
    }

    # ?? Call function
    Create-ZipSafe -sourcePath $basePath -zipPath $mainZip

}
else {
    Write-Host "Skipped main folder zipping." -ForegroundColor Yellow

}
Log "`nProcess completed."

# ========================
# STEP 2: UPLOAD TO S3 (INDEPENDENT)
# ========================

Log "`n=== STEP 2: UPLOAD TO S3 ==="

$uploadChoice = Read-Host "Upload to S3? (yes/no)"

if ($uploadChoice.Trim().ToLower() -eq "yes") {

    if (Test-Path $zipFile) {

        try {
            [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
            Log "ZIP validation passed. Uploading to S3..."
            Upload-S3
            Log "Upload complete. Verifying S3..."
            Verify-S3
        }
        catch {
            Log "ZIP file is invalid. Cannot upload."
        }

    } else {
        Log "ZIP file not found. Please run backup first."
    }

} else {
    Log "S3 upload skipped by user."
}

Log "Script completed"

# ========================
# DOWNLOAD & DEPLOY
# ========================

function Download-And-Deploy-Package {

    Log "`n=== DOWNLOAD & DEPLOY STARTED ==="

    if ((Read-Host "Download package? (yes/no)").Trim().ToLower() -ne "yes") {
        Log "Download skipped"
        return
    }

    $s3Path = Read-Host "Enter S3 path"
    $downloadDir = "D:\Backup"

    if (!(Test-Path $downloadDir)) {
        New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
    }

    $zipFileLocal = Join-Path $downloadDir (Split-Path $s3Path -Leaf)

    try {
        Log "Downloading from S3: $s3Path"
        aws s3 cp $s3Path $zipFileLocal
        Log "Download completed: $zipFileLocal"
    }
    catch {
        Log "ERROR: Download failed - $_"
        return
    }

    # ========================
    # UNZIP FLOW
    # ========================

    $unzipChoice = Read-Host "`nDo you want to unzip and process backup? (yes/no)"

    if ($unzipChoice.Trim().ToLower() -ne "yes") {
        Log "Skipping unzip process"
        return
    }

    $deleteZipAfterExtract = $false
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    function Expand-ZipRecursively {
        param ($folderPath)

        if (!(Test-Path $folderPath)) { return }

        $processedZips = @()

        do {
            $zipFiles = Get-ChildItem -Path $folderPath -Filter *.zip -File -Recurse |
                        Where-Object { $_.FullName -notin $processedZips }

            if ($zipFiles.Count -eq 0) { break }

            foreach ($zip in $zipFiles) {

                $destination = Join-Path $zip.DirectoryName ([System.IO.Path]::GetFileNameWithoutExtension($zip.Name))

                if (!(Test-Path $destination)) {
                    New-Item -ItemType Directory -Path $destination | Out-Null
                }

                try {
                    Expand-Archive -Path $zip.FullName -DestinationPath $destination -Force
                    Log "Unzipped: $($zip.FullName)"
                }
                catch {
                    Log "Failed to unzip: $($zip.FullName)"
                }

                $processedZips += $zip.FullName

                if ($deleteZipAfterExtract) {
                    Remove-Item $zip.FullName -Force
                }
            }

        } while ($true)
    }

    function Remove-AllDuplicateFolders {
        param ($rootPath)

        if (!(Test-Path $rootPath)) { return }

        do {
            $fixed = $false

            $folders = @()
            $folders += Get-Item $rootPath
            $folders += Get-ChildItem -Path $rootPath -Directory -Recurse

            foreach ($folder in $folders) {

                $name = $folder.Name
                $duplicatePath = Join-Path $folder.FullName $name

                if (Test-Path $duplicatePath) {

                    Log "Fixing duplicate: $($folder.FullName)"

                    Get-ChildItem $duplicatePath | ForEach-Object {

                        $dest = Join-Path $folder.FullName $_.Name

                        try {
                            if (Test-Path $dest) {
                                Copy-Item $_.FullName $dest -Recurse -Force
                                Remove-Item $_.FullName -Recurse -Force
                            } else {
                                Move-Item $_.FullName $folder.FullName -Force
                            }
                        }
                        catch {
                            Log "Skipped: $($_.FullName)"
                        }
                    }

                    Remove-Item $duplicatePath -Recurse -Force
                    $fixed = $true
                }
            }

        } while ($fixed)
    }

    # ========================
    # PATHS
    # ========================

    $hostname = $env:COMPUTERNAME
    $mainZip = $zipFileLocal   # ? FIXED
    $unzipRoot = "D:\Backup\Package_Unzip\$hostname"

    # ========================
    # STEP 1: UNZIP MAIN
    # ========================

    if (Test-Path $mainZip) {

        if (Test-Path $unzipRoot) {
            Remove-Item $unzipRoot -Recurse -Force
        }

        New-Item -ItemType Directory -Path $unzipRoot -Force | Out-Null

        try {
            Expand-Archive -Path $mainZip -DestinationPath $unzipRoot -Force
            Log "Main backup extracted"
        }
        catch {
            Log "Failed to unzip main backup"
            return
        }

        $inner = Join-Path $unzipRoot $hostname

        if (Test-Path $inner) {
            Log "Fixing nested hostname folder"

            Get-ChildItem $inner | ForEach-Object {
                Move-Item $_.FullName $unzipRoot -Force
            }

            Remove-Item $inner -Recurse -Force
        }

    } else {
        Log "Main zip not found"
        return
    }

    # ========================
    # STEP 2: FIND DBBSetup
    # ========================

    $dbbFolder = Get-ChildItem $unzipRoot -Recurse -Directory |
                 Where-Object { $_.Name -eq "DBBSetup" } |
                 Select-Object -First 1

    if (-not $dbbFolder) {
        Log "DBBSetup not found"
        return
    }

    $dbbPath = $dbbFolder.FullName

    # ========================
    # STEP 3: UNZIP INTERNAL
    # ========================

    Log "Extracting all internal zip files..."
    Expand-ZipRecursively -folderPath $dbbPath

    # ========================
    # STEP 4: FIX DUPLICATES
    # ========================

    Log "Cleaning duplicate folders..."
    Remove-AllDuplicateFolders -rootPath $dbbPath

    Log "Unzip + cleanup completed"

    # ========================
    # STEP 5: DEPLOY
    # ========================

    if ((Read-Host "Deploy files? (yes/no)").Trim().ToLower() -ne "yes") {
        Log "Deployment skipped"
        return
    }

    $target = "D:\DBBSetup"
    $folders = "MonitoringScript","Dump","Keys","VisualCron"

    foreach ($f in $folders) {
        $src = Join-Path $dbbPath $f
        $dst = Join-Path $target $f

        if (Test-Path $src) {
            Copy-Item $src $dst -Recurse -Force
            Log "$f copied to $target"
        }
    }

    Log "Deployment Completed"
    Log "=== DOWNLOAD & DEPLOY COMPLETED ==="
}

Download-And-Deploy-Package

# ========================
# ASK FOR IMPORT
# ========================

$doImport = Read-Host "`nDo you want to IMPORT tasks? (yes/no)"

if ($doImport.Trim().ToLower() -ne "yes") {
    Log "Skipping TASK IMPORT..."
    return
}

Log "`n=== TASK IMPORT STARTED ==="

# ========================
# CONFIGURATION
# ========================

$hostname = $env:COMPUTERNAME
$importDir = "D:\Backup\Package_Unzip\$hostname\Task"

$domain = $env:USERDOMAIN
$gmsaAccount = "$domain\gmsa-batch-svc$"

# ========================
# STEP 1: CHECK DIRECTORY
# ========================

if (-not (Test-Path $importDir)) {
    Log "Import directory not found: $importDir"
    return
}

# ========================
# STEP 2: IMPORT TASKS
# ========================

Log "`n=== IMPORTING TASKS ==="

$taskFiles = Get-ChildItem -Path $importDir -Filter *.xml

if (-not $taskFiles) {
    Log "No XML files found in $importDir"
}
else {
    foreach ($file in $taskFiles) {

        $taskName = $file.BaseName

        try {
            $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

            if ($existingTask) {
                Log "SKIPPED: $taskName (already exists)"
                continue
            }

            $xmlContent = Get-Content $file.FullName -Raw

            Register-ScheduledTask `
                -Xml $xmlContent `
                -TaskName $taskName `
                -TaskPath "\"

            schtasks /change /tn $taskName /ru $gmsaAccount /rp "" 2>$null | Out-Null

            Log "IMPORTED: $taskName (gMSA assigned)"
        }
        catch {
            Log "FAILED: $taskName - $_"
        }
    }
}

# ========================
# STEP 3: VALIDATION
# ========================

Log "`n=== VALIDATING TASKS ==="

foreach ($file in $taskFiles) {

    $taskName = $file.BaseName

    try {
        $result = schtasks /query /tn $taskName /v /fo list 2>$null

        if ($result) {

            $isGmsa = $result -match [regex]::Escape($gmsaAccount)

            if ($isGmsa) {
                Log "VALID: $taskName (gMSA assigned)"
            }
            else {
                Log "CHECK: $taskName (gMSA NOT set)"
            }
        }
        else {
            Log "MISSING: $taskName"
        }
    }
    catch {
        Log "Validation failed: $taskName"
    }
}

Log "`n=== TASK IMPORT COMPLETED ==="