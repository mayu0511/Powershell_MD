############################################################################################################
# Backup Script | DEVELOPED BY:: Mahendra Dwivedi
# Version 3.7 | FULL (Logging + Backup + Counts + ZIP + Validation)
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

$transcriptLog = "$logDir\Full_Backup_Task_$timestamp.log"
Start-Transcript -Path $transcriptLog -Append

$logPath = "$logDir\Backup_Steps_$timestamp.log"

function Log {
    param([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$time] $msg"
    Write-Host $msg
    Add-Content -Path $logPath -Value $entry
}

Log "Script Started"

# ========================
# VARIABLES
# ========================
$hostname = $env:COMPUTERNAME
$hostnameLower = $hostname.ToLower()
$currentdate = Get-Date -Format "yyyyMMdd"

$destinationRoot = "D:\Backup\$hostname"
$zipFile = "D:\Backup\$hostname.zip"

Log "Hostname: $hostname"

# ========================
# SERVER TYPE DETECTION
# ========================
Log "Detecting Server Type"

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
        Log "Server type detection failed"
        Stop-Transcript
        exit
    }
}

Log "Server Type: $ServerType"

# ========================
# REGION
# ========================
Log "Detecting Region"

if ($hostnameLower -match "e1") {
    $Region = "us-east-1"
}
elseif ($hostnameLower -match "w2") {
    $Region = "us-west-2"
}
else {
    Log "Region detection failed"
    Stop-Transcript
    exit
}

Log "Region: $Region"

# ========================
# POD
# ========================
Log "Fetching POD"

try {
    $pod = (aws ec2 describe-instances `
    --filters "Name=tag:Name,Values=$hostnameLower" `
    --region $Region `
    --query "Reservations[*].Instances[*].Tags[?Key=='pod'].Value" `
    --output text).Trim().ToLower()
}
catch {
    Log "AWS command failed"
    Stop-Transcript
    exit
}

if (-not $pod) {
    Log "POD detection failed"
    Stop-Transcript
    exit
}

Log "POD: $pod"

# ========================
# ENV
# ========================
Log "Detecting Environment"

if ($hostnameLower -match "patqa") { $envName = "patqa" }
elseif ($hostnameLower -match "perf") { $envName = "perf" }
elseif ($hostnameLower -match "uat") { $envName = "uat" }
elseif ($hostnameLower -match "dev") { $envName = "dev" }
elseif ($hostnameLower -match "qa") { $envName = "qa" }
elseif ($hostnameLower -match "patuat") { $envName = "patuat" }
elseif ($hostnameLower -match "prod") { $envName = "prod" }
else {
    Log "Environment detection failed"
    Stop-Transcript
    exit
}

Log "Environment: $envName"

# ========================
# S3 PATH
# ========================
$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"
Log "S3 Path: $bucketPath"

# ========================
# EXCLUDE PATHS
# ========================
$excludeFilePaths = @(
    "D:\DBBSetup\MonitoringScript\BaxterIPM\JSONFileParsingUtility\Log"
)

# ========================
# BACKUP FUNCTION
# ========================
function Run-Backup {

    Log "Backup Started"

    if (Test-Path $destinationRoot) {
        Remove-Item $destinationRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $destinationRoot | Out-Null

    foreach ($sourcePath in $sources) {

        Log "Processing: $sourcePath"

        if (!(Test-Path $sourcePath)) {
            Log "Source not found"
            continue
        }

        $destinationPath = Join-Path $destinationRoot (Split-Path $sourcePath -Leaf)
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

        $items = Get-ChildItem $sourcePath -Recurse -Force

        foreach ($item in $items) {

            foreach ($exclude in $excludeFilePaths) {
                if ($item.FullName -like "$exclude*") { continue }
            }

            $dest = $item.FullName.Replace($sourcePath, $destinationPath)

            if ($item.PSIsContainer) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
            }
            else {
                try {
                    Copy-Item $item.FullName $dest -Force
                }
                catch {
                    Log "Skipped: $($item.FullName)"
                }
            }
        }

        # COUNTS
        $srcF = (Get-ChildItem $sourcePath -Recurse -File).Count
        $dstF = (Get-ChildItem $destinationPath -Recurse -File).Count

        Log "Source Files: $srcF | Destination Files: $dstF"
    }

    # ZIP
    Log "Creating ZIP"

    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }

    Compress-Archive -Path "$destinationRoot\*" -DestinationPath $zipFile

    # VALIDATION
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
        Log "ZIP Valid"
    }
    catch {
        Log "ZIP Invalid"
        exit
    }

    Log "Backup Completed"
}

# ========================
# EXECUTION
# ========================
Run-Backup

Log "Script Completed"
Stop-Transcript

# ========================
# S3
# ========================

function Upload-S3 {
    Log "Starting S3 Upload"

    try {
        aws s3 cp $zipFile $bucketPath
        Log "S3 Upload completed: $zipFile -> $bucketPath"
    }
    catch {
        Log "S3 Upload failed"
    }
}

function Verify-S3 {
    Log "Verifying S3 Upload"

    try {
        aws s3 ls $bucketPath
        Log "S3 verification completed"
    }
    catch {
        Log "S3 verification failed"
    }
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

    Log "User selected BACKUP"

    # Run file backup
    Run-Backup

    #####################################################################
    # TASK EXPORT (BEFORE ZIP)
    #####################################################################

    Log "Starting Task Export"

    $taskExportDir = "D:\Backup\$hostname\Task"

    if (-not (Test-Path $taskExportDir)) {
        New-Item -Path $taskExportDir -ItemType Directory -Force | Out-Null
        Log "Created Task Export Directory: $taskExportDir"
    }

    $doExport = Read-Host "Do you want to EXPORT tasks? (yes/no)"

    if ($doExport -eq "yes") {

        Log "User selected TASK EXPORT"

        $tasks = Get-ScheduledTask | Where-Object {
            $_.TaskPath -eq "\" -and $_.TaskName -like "Task_*"
        }

        if (-not $tasks) {
            Write-Host "No tasks found"
            Log "No scheduled tasks found"
        }
        else {
            foreach ($task in $tasks) {
                try {
                    $xml = Export-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
                    $filePath = Join-Path $taskExportDir "$($task.TaskName).xml"

                    $xml | Out-File -FilePath $filePath -Encoding UTF8

                    Write-Host "Exported: $($task.TaskName)"
                    Log "Exported task: $($task.TaskName)"
                }
                catch {
                    Write-Host "FAILED: $($task.TaskName)"
                    Log "FAILED to export task: $($task.TaskName)"
                }
            }
        }
    }
    else {
        Write-Host "Skipping TASK EXPORT..."
        Log "Task export skipped by user"
    }

    #####################################################################
    # ZIP CREATION
    #####################################################################

    Log "Starting ZIP creation"

    Create-Zip

    if (Validate-Zip) {
        Write-Host "ZIP validation successful" -ForegroundColor Green
        Log "ZIP validation successful"
    }
    else {
        Write-Host "ZIP validation failed" -ForegroundColor Red
        Log "ZIP validation failed"
    }
}
else {
    Log "User skipped BACKUP step"
}

# ------------------------
# STEP 2: UPLOAD (INDEPENDENT)
# ------------------------

Write-Host ""

$uploadChoice = Read-Host "Upload to S3? (yes/no)"

if ($uploadChoice -eq "yes") {

    Log "User selected S3 UPLOAD"

    if (Test-Path $zipFile) {

        Log "ZIP file found: $zipFile"

        if (Validate-Zip) {

            Log "ZIP validation passed before upload"

            Upload-S3
            Verify-S3
        }
        else {
            Write-Host "ZIP file is invalid. Cannot upload." -ForegroundColor Red
            Log "ZIP validation failed before upload"
        }
    }
    else {
        Write-Host "ZIP file not found. Please run backup first." -ForegroundColor Yellow
        Log "ZIP file not found for upload"
    }
}
else {
    Log "User skipped S3 upload"
}

Log "Script completed"

# ========================
# DOWNLOAD & DEPLOY
# ========================

function Download-And-Deploy-Package {

    Log "Download & Deploy step started"

    $downloadChoice = Read-Host "Download package? (yes/no)"
    if ($downloadChoice -ne "yes") {
        Log "User skipped download step"
        return
    }

    $s3Path = Read-Host "Enter S3 path"
    Log "S3 Path entered: $s3Path"

    $downloadDir = "D:\Backup"
    if (!(Test-Path $downloadDir)) {
        New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
        Log "Created download directory: $downloadDir"
    }

    $zipFileLocal = Join-Path $downloadDir (Split-Path $s3Path -Leaf)

    # ------------------------
    # DOWNLOAD
    # ------------------------
    Log "Starting download from S3"

    try {
        aws s3 cp $s3Path $zipFileLocal
        Log "Download completed: $zipFileLocal"
    }
    catch {
        Log "Download failed"
        return
    }

    # ------------------------
    # UNZIP
    # ------------------------
    $unzipFolder = "D:\Backup\Package_Unzip"

    if (Test-Path $unzipFolder) {
        Remove-Item $unzipFolder -Recurse -Force
        Log "Old unzip folder removed"
    }

    Log "Extracting ZIP"

    try {
        Expand-Archive $zipFileLocal $unzipFolder -Force
        Log "Unzip completed: $unzipFolder"
    }
    catch {
        Log "Unzip failed"
        return
    }

    # ------------------------
    # DEPLOY CONFIRMATION
    # ------------------------
    $deployChoice = Read-Host "Deploy files? (yes/no)"
    if ($deployChoice -ne "yes") {
        Log "User skipped deployment step"
        return
    }

    Log "Deployment started"

    # ------------------------
    # FIND DBBSetup
    # ------------------------
    $dbbFolder = Get-ChildItem $unzipFolder -Recurse -Directory |
                 Where-Object { $_.Name -eq "DBBSetup" } |
                 Select-Object -First 1

    if (-not $dbbFolder) {
        Write-Host "DBBSetup not found"
        Log "DBBSetup folder not found in package"
        return
    }

    Log "DBBSetup found: $($dbbFolder.FullName)"

    # ------------------------
    # COPY FILES
    # ------------------------
    $target = "D:\DBBSetup"
    $folders = "MonitoringScript","Dump","Keys","VisualCron"

    foreach ($f in $folders) {

        $src = Join-Path $dbbFolder.FullName $f
        $dst = Join-Path $target $f

        if (Test-Path $src) {
            try {
                Copy-Item $src $dst -Recurse -Force
                Write-Host "$f copied"
                Log "$f copied successfully"
            }
            catch {
                Write-Host "Failed to copy $f"
                Log "Failed to copy folder: $f"
            }
        }
        else {
            Log "Source folder not found in package: $f"
        }
    }

    Write-Host "Deployment Completed"
    Log "Deployment completed successfully"
}

# ========================
# EXECUTION
# ========================

Download-And-Deploy-Package

# ========================
# ASK FOR IMPORT
# ========================
$doImport = Read-Host "`nDo you want to IMPORT tasks? (yes/no)"

if ($doImport -ne "yes") {
    Write-Host "Skipping TASK IMPORT..."
    Log "User skipped TASK IMPORT"
    Stop-Transcript
    return
}

Log "User selected TASK IMPORT"

#####################################################################
# TASK IMPORT + gMSA + VALIDATION
#####################################################################

# ========================
# CONFIGURATION
# ========================
$hostname = $env:COMPUTERNAME
$importDir = "D:\Backup\Package_Unzip\$hostname\Task"

$domain = $env:USERDOMAIN
$gmsaAccount = "$domain\gmsa-batch-svc$"

Log "Import directory: $importDir"
Log "gMSA Account: $gmsaAccount"

# ========================
# STEP 1: CHECK DIRECTORY
# ========================
if (-not (Test-Path $importDir)) {
    Write-Host "Import directory not found: $importDir"
    Log "Import directory not found"
    return
}

Log "Import directory found"

# ========================
# STEP 2: IMPORT TASKS
# ========================
Write-Host "`n=== IMPORTING TASKS ==="
Log "Starting task import"

$taskFiles = Get-ChildItem -Path $importDir -Filter *.xml

if (-not $taskFiles) {
    Write-Host "No XML files found in $importDir"
    Log "No XML files found for import"
}
else {

    Log "Total tasks to import: $($taskFiles.Count)"

    foreach ($file in $taskFiles) {

        $taskName = $file.BaseName

        try {
            $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

            if ($existingTask) {
                Write-Host "SKIPPED: $taskName (already exists)"
                Log "Skipped existing task: $taskName"
                continue
            }

            $xmlContent = Get-Content $file.FullName -Raw

            Register-ScheduledTask `
                -Xml $xmlContent `
                -TaskName $taskName `
                -TaskPath "\"

            schtasks /change /tn $taskName /ru $gmsaAccount /rp "" 2>$null | Out-Null

            Write-Host "IMPORTED: $taskName (gMSA assigned)"
            Log "Imported task: $taskName with gMSA"
        }
        catch {
            Write-Host "FAILED: $taskName"
            Log "FAILED to import task: $taskName"
        }
    }
}

# ========================
# STEP 3: VALIDATION
# ========================
Write-Host "`n=== VALIDATING TASKS ==="
Log "Starting task validation"

foreach ($file in $taskFiles) {

    $taskName = $file.BaseName

    try {
        $result = schtasks /query /tn $taskName /v /fo list 2>$null

        if ($result) {

            $isGmsa = $result -match [regex]::Escape($gmsaAccount)

            if ($isGmsa) {
                Write-Host "VALID: $taskName (gMSA assigned)"
                Log "VALID task: $taskName (gMSA assigned)"
            }
            else {
                Write-Host "CHECK: $taskName (gMSA NOT set)"
                Log "CHECK task: $taskName (gMSA NOT set)"
            }
        }
        else {
            Write-Host "MISSING: $taskName"
            Log "MISSING task after import: $taskName"
        }
    }
    catch {
        Write-Host "Validation failed: $taskName"
        Log "Validation failed for task: $taskName"
    }
}

Write-Host "`n=== SCRIPT COMPLETED ==="
Log "Task import and validation completed"