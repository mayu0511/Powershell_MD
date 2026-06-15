############################################################################################################
# Backup Script | DEVELOPED BY:: Mahendra Dwivedi
# Version 3.5 | ORIGINAL STYLE (Empty Folder Fix Added, No Minimization)
############################################################################################################

Clear-Host
$ErrorActionPreference = "Stop"

# ========================
# LOGGING START
# ========================
$logDir = "C:\Temp"

if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$logDir\Full_Backup_Task_$timestamp.log"

Start-Transcript -Path $logFile -Append

# ========================
# VARIABLES
# ========================

$hostname = $env:COMPUTERNAME

$hostnameLower = $hostname.ToLower()

$currentdate = Get-Date -Format "yyyyMMdd"

$destinationRoot = "D:\Backup\$hostname"

$zipFile = "D:\Backup\$hostname.zip"

$logPath = "C:\TEMP\BackupCopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# ========================
# LOG FUNCTION
# ========================

function Log {

    param(
        [string]$msg
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content -Path $logPath -Value "[$timestamp] $msg"
}

# ========================
# SERVER TYPE DETECTION
# ========================

Write-Host ""
Write-Host "Detecting Server Type..." -ForegroundColor Cyan
Write-Host ""

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
        $ServerType = "Report Server"
        $sources = @("D:\Reportserver")
        $singleFile = ""
    }

    default {
        Write-Host "Server type detection failed." -ForegroundColor Red
        exit
    }
}

Write-Host "Server Type : $ServerType" -ForegroundColor Green

# ========================
# REGION DETECTION
# ========================

Write-Host ""
Write-Host "Detecting Region..." -ForegroundColor Cyan

if ($hostnameLower -match "e1") {
    $Region = "us-east-1"
}
elseif ($hostnameLower -match "w2") {
    $Region = "us-west-2"
}
else {
    Write-Host "Region detection failed" -ForegroundColor Red
    exit
}

Write-Host "Region : $Region" -ForegroundColor Green

# ========================
# POD DETECTION
# ========================

Write-Host ""
Write-Host "Fetching POD tag..." -ForegroundColor Cyan

$pod = (aws ec2 describe-instances `
--filters "Name=tag:Name,Values=$hostnameLower" `
--region $Region `
--query "Reservations[*].Instances[*].Tags[?Key=='pod'].Value" `
--output text).Trim().ToLower()

if (-not $pod) {
    Write-Host "Failed to detect POD" -ForegroundColor Red
    exit
}

Write-Host "POD : $pod" -ForegroundColor Green

# ========================
# ENV DETECTION
# ========================

Write-Host ""
Write-Host "Detecting Environment..." -ForegroundColor Cyan

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
    Write-Host "Environment detection failed" -ForegroundColor Red
    exit
}

Write-Host "Environment : $envName" -ForegroundColor Green

# ========================
# S3 PATH
# ========================

$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"

Write-Host ""
Write-Host "S3 Bucket : $bucketPath"
Write-Host ""

# ========================
# EXCLUDE FILE PATHS (KEEP FOLDER ONLY)
# ========================
$excludeFilePaths = @(
    "D:\DBBSetup\MonitoringScript\BaxterIPM\JSONFileParsingUtility\Log",
    "D:\Backup\CCBATE1QAB22\DBBSetup\MonitoringScript\AuthSourceSinkStatus\Log",
    "D:\Backup\CCBATE1QAB22\DBBSetup\MonitoringScript\InterPOD_Transfer\DailyFiles\2021-12-27\CoreIssue\6-6969"
)

# ========================
# BACKUP FUNCTION
# ========================

function Run-Backup {

    if (!(Test-Path $destinationRoot)) {
        New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
    }

    foreach ($sourcePath in $sources) {

        Write-Host ""
        Write-Host "Processing Source : $sourcePath" -ForegroundColor Cyan
        Write-Host ""

        if (!(Test-Path $sourcePath)) {
            Write-Host "Source not found: $sourcePath" -ForegroundColor Yellow
            continue
        }

        $destinationPath = Join-Path $destinationRoot (Split-Path $sourcePath -Leaf)

        # Ensure root folder exists
        if (!(Test-Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        }

        $itemsToCopy = Get-ChildItem $sourcePath -Recurse -Force -ErrorAction SilentlyContinue

        $itemsToCopy = $itemsToCopy | Where-Object {

    # Always allow folders (so empty folder gets created)
    if ($_.PSIsContainer) { return $true }

    # Exclude files inside specific paths
    foreach ($path in $excludeFilePaths) {
        if ($_.FullName -like "$path*") {
            return $false
        }
    }

    # Existing conditions
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

            if ($totalItems -gt 0) {
                $percent = [math]::Round(($currentItem / $totalItems) * 100, 2)
            }
            else {
                $percent = 100
            }

            Write-Progress -Activity "Copying Files" `
                           -Status "$percent% - $($item.FullName)" `
                           -PercentComplete $percent

            $destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)

            $destFolder = Split-Path $destItemPath -Parent

            if (!(Test-Path $destFolder)) {
                New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
            }

            # ========================
            # EMPTY FOLDER FIX (ADDED)
            # ========================

            if ($item.PSIsContainer) {

                if (!(Test-Path $destItemPath)) {
                    New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null
                }

                continue
            }

            # ========================
            # FILE COPY
            # ========================

            try {
                Copy-Item $item.FullName $destItemPath -Force -ErrorAction Stop
            }
            catch {
                Log "Skipped: $($item.FullName)"
            }
        }

        Write-Progress -Activity "Copying Files" -Completed

        # ========================
        # COUNTS
        # ========================

        $sourceFileCount   = (Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue).Count
        $sourceFolderCount = (Get-ChildItem $sourcePath -Recurse -Directory -ErrorAction SilentlyContinue).Count

        $destFileCount     = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue).Count
        $destFolderCount   = (Get-ChildItem $destinationPath -Recurse -Directory -ErrorAction SilentlyContinue).Count

        $size = (Get-ChildItem $destinationPath -Recurse -File | Measure-Object Length -Sum).Sum

        $sizeMB = [math]::Round($size / 1MB, 2)

        Write-Host ""
        Write-Host "Backup Summary for $sourcePath" -ForegroundColor Cyan
        Write-Host "Source Files       : $sourceFileCount"
        Write-Host "Source Folders     : $sourceFolderCount"
        Write-Host "Destination Files  : $destFileCount"
        Write-Host "Destination Folders: $destFolderCount"
        Write-Host "Backup Size        : $sizeMB MB"
        Write-Host ""
    }

    if ($singleFile -and (Test-Path $singleFile)) {
        Copy-Item $singleFile $destinationRoot -Force
    }

    Write-Host ""
    Write-Host "Backup Completed Successfully" -ForegroundColor Green
    Write-Host ""
}


# ========================
# ZIP
# ========================

function Create-Zip {

    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }

    Compress-Archive -Path $destinationRoot -DestinationPath $zipFile -Force
}

function Validate-Zip {

    try {
        [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
        return $true
    }
    catch {
        return $false
    }
}

# ========================
# S3
# ========================

function Upload-S3 {
    aws s3 cp $zipFile $bucketPath
}

function Verify-S3 {
    aws s3 ls $bucketPath
}

# ========================
# EXECUTION
# ========================

Write-Host ""

# ------------------------
# STEP 1: BACKUP
# ------------------------

$backupChoice = Read-Host "Take backup? (yes/no)"

if ($backupChoice -eq "yes") {

    # Run file backup
    Run-Backup

    #####################################################################
    # TASK EXPORT (BEFORE ZIP)
    #####################################################################

    Write-Host "`n=== TASK EXPORT (BEFORE ZIP) ==="

    $taskExportDir = "D:\Backup\$hostname\Task"

    if (-not (Test-Path $taskExportDir)) {
        New-Item -Path $taskExportDir -ItemType Directory -Force | Out-Null
    }

    $doExport = Read-Host "Do you want to EXPORT tasks? (yes/no)"

    if ($doExport -eq "yes") {

        $tasks = Get-ScheduledTask | Where-Object {
            $_.TaskPath -eq "\" -and $_.TaskName -like "Task_*"
        }

        if (-not $tasks) {
            Write-Host "No tasks found"
        }
        else {
            foreach ($task in $tasks) {
                try {
                    $xml = Export-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
                    $filePath = Join-Path $taskExportDir "$($task.TaskName).xml"

                    $xml | Out-File -FilePath $filePath -Encoding UTF8

                    Write-Host "Exported: $($task.TaskName)"
                }
                catch {
                    Write-Host "FAILED: $($task.TaskName) - $_"
                }
            }
        }
    }
    else {
        Write-Host "Skipping TASK EXPORT..."
    }

    #####################################################################
    # ZIP CREATION
    #####################################################################

    Create-Zip

    if (Validate-Zip) {
        Write-Host "ZIP validation successful" -ForegroundColor Green
    }
    else {
        Write-Host "ZIP validation failed" -ForegroundColor Red
    }
}

# ------------------------
# STEP 2: UPLOAD (INDEPENDENT)
# ------------------------

Write-Host ""

$uploadChoice = Read-Host "Upload to S3? (yes/no)"

if ($uploadChoice -eq "yes") {

    if (Test-Path $zipFile) {

        if (Validate-Zip) {

            Upload-S3

            Verify-S3
        }
        else {
            Write-Host "ZIP file is invalid. Cannot upload." -ForegroundColor Red
        }
    }
    else {
        Write-Host "ZIP file not found. Please run backup first." -ForegroundColor Yellow
    }
}

Log "Script completed"

# ========================
# DOWNLOAD & DEPLOY
# ========================

function Download-And-Deploy-Package {

    if ((Read-Host "Download package? (yes/no)") -ne "yes") { return }

    $s3Path = Read-Host "Enter S3 path"
    $downloadDir = "D:\Backup"
    $zipFileLocal = Join-Path $downloadDir (Split-Path $s3Path -Leaf)

    aws s3 cp $s3Path $zipFileLocal

    $unzipFolder = "D:\Backup\Package_Unzip"
    if (Test-Path $unzipFolder) { Remove-Item $unzipFolder -Recurse -Force }

    Expand-Archive $zipFileLocal $unzipFolder -Force

    if ((Read-Host "Deploy files? (yes/no)") -ne "yes") { return }

    $dbbFolder = Get-ChildItem $unzipFolder -Recurse -Directory | Where-Object { $_.Name -eq "DBBSetup" } | Select-Object -First 1

    if (-not $dbbFolder) { Write-Host "DBBSetup not found"; return }

    $target = "D:\DBBSetup"
    $folders = "MonitoringScript","Dump","Keys","VisualCron"

    foreach ($f in $folders) {
        $src = Join-Path $dbbFolder.FullName $f
        $dst = Join-Path $target $f

        if (Test-Path $src) {
            Copy-Item $src $dst -Recurse -Force
            Write-Host "$f copied"
        }
    }

    Write-Host "Deployment Completed"
}

Download-And-Deploy-Package


# ========================
# ASK FOR IMPORT
# ========================
$doImport = Read-Host "`nDo you want to IMPORT tasks? (yes/no)"

if ($doImport -ne "yes") {
    Write-Host "Skipping TASK IMPORT..."
    Stop-Transcript
    return
}

#####################################################################
# TASK IMPORT + gMSA + VALIDATION (FINAL CLEAN)
#####################################################################

# ========================
# CONFIGURATION
# ========================
$hostname = $env:COMPUTERNAME
$importDir = "D:\Backup\Package_Unzip\$hostname\Task"

# Build gMSA account
$domain = $env:USERDOMAIN
$gmsaAccount = "$domain\gmsa-batch-svc$"

# ========================
# STEP 1: CHECK DIRECTORY
# ========================
if (-not (Test-Path $importDir)) {
    Write-Host "Import directory not found: $importDir"
    return
}

# ========================
# STEP 2: IMPORT TASKS
# ========================
Write-Host "`n=== IMPORTING TASKS ==="

$taskFiles = Get-ChildItem -Path $importDir -Filter *.xml

if (-not $taskFiles) {
    Write-Host "No XML files found in $importDir"
} else {

    foreach ($file in $taskFiles) {

        # SAME NAME as file
        $taskName = $file.BaseName

        try {
            # Check if already exists
            $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

            if ($existingTask) {
                Write-Host "SKIPPED: $taskName (already exists)"
                continue
            }

            # Read XML
            $xmlContent = Get-Content $file.FullName -Raw

            # Register task
            Register-ScheduledTask `
                -Xml $xmlContent `
                -TaskName $taskName `
                -TaskPath "\"

            # Assign gMSA
            schtasks /change /tn $taskName /ru $gmsaAccount /rp "" 2>$null | Out-Null

            Write-Host "IMPORTED: $taskName (gMSA assigned)"
        }
        catch {
            Write-Host "FAILED: $taskName - $_"
        }
    }
}

# ========================
# STEP 3: VALIDATION
# ========================
Write-Host "`n=== VALIDATING TASKS ==="

foreach ($file in $taskFiles) {

    $taskName = $file.BaseName

    try {
        $result = schtasks /query /tn $taskName /v /fo list 2>$null

        if ($result) {

            $isGmsa = $result -match [regex]::Escape($gmsaAccount)

            if ($isGmsa) {
                Write-Host "VALID: $taskName (gMSA assigned)"
            }
            else {
                Write-Host "CHECK: $taskName (gMSA NOT set)"
            }
        }
        else {
            Write-Host "MISSING: $taskName"
        }
    }
    catch {
        Write-Host "Validation failed: $taskName"
    }
}

Write-Host "`n=== SCRIPT COMPLETED ==="