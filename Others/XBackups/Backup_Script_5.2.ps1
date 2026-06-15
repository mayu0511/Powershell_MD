############################################################################################################
# Backup Script | DEVELOPED BY:: Mahendra Dwivedi
# Version 4.9 | ORIGINAL STYLE (Empty Folder Fix Added, No Minimization)
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

# ========================
# Task- 4 ROOT BACKUP CHECK
# ========================

$backupRoot = "D:\Backup"

if (Test-Path $backupRoot) {

    Log "Backup root exists: $backupRoot"

    $deleteRootChoice = Read-Host "Do you want to DELETE ALL data inside D:\Backup? (Y/N)"

    if ($deleteRootChoice.Trim().ToLower() -in @("y","yes")) {

        try {
            Get-ChildItem -Path $backupRoot -Force | Remove-Item -Recurse -Force -ErrorAction Stop
            Log "All data inside D:\Backup deleted successfully"
        }
        catch {
            Log "ERROR: Failed to clean D:\Backup - $_"
            #Stop-Transcript
            exit
        }

    } else {
        Log "User chose NOT to delete data from D:\Backup"
    }

} else {
    Log "Backup root does not exist. It will be created during backup."
}
Log "Hostname: $hostname"

# ========================
# Task- 5 SERVER TYPE DETECTION
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
        #Stop-Transcript
        exit
    }
}

Log "Server Type Detected: $ServerType"

# ========================
# Task- 6 REGION DETECTION
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
    #Stop-Transcript
    exit
}

Log "Region: $Region"

# ========================
# Task- 7 POD DETECTION
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
    #Stop-Transcript
    exit
}

# ========================
# Task- 8 ENV DETECTION
# ========================

Log "Detecting Environment..."

if ($hostnameLower -match "patqa") {
    $envName = "patqa"
}
elseif ($hostnameLower -match "patuat") {
    $envName = "patuat"
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
elseif ($hostnameLower -match "prod") {
    $envName = "prod"
}
else {
    Log "ERROR: Environment detection failed"
    exit
}

Log "Environment: $envName"

# ========================
# Task- 9 S3 PATH
# ========================

$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"

Log "S3 Bucket Path: $bucketPath"
Log "===== INITIAL TASKS COMPLETED ====="

# ========================
# Task- 10 S3 FUNCTIONS
# ========================

function Upload-S3 {

    try {
        Log "Uploading file: $zipFile"
        aws s3 cp $zipFile $bucketPath --only-show-errors

        if ($LASTEXITCODE -ne 0) {
            throw "AWS CLI upload failed"
        }

        Log "Upload command executed successfully"
    }
    catch {
        throw "Upload-S3 failed: $_"
    }
}

function Verify-S3 {

    try {
        Log "Checking file on S3..."

        $fileName = Split-Path $zipFile -Leaf

        $result = aws s3 ls $bucketPath | Select-String $fileName

        if ($result) {
            Log "File verified on S3: $fileName"
        }
        else {
            throw "File not found in S3 after upload"
        }
    }
    catch {
        throw "Verify-S3 failed: $_"
    }
}

# ========================
# Task- 11 EXCLUDE FILE PATHS
# ========================

$excludeFilePaths = @(
    "D:\DBBSetup\MonitoringScript\BaxterIPM\JSONFileParsingUtility\Log",
    "D:\Backup\CCBATE1QAB22\DBBSetup\MonitoringScript\AuthSourceSinkStatus\Log",
    "D:\Backup\CCBATE1QAB22\DBBSetup\MonitoringScript\InterPOD_Transfer\DailyFiles\2021-12-27\CoreIssue\6-6969"
)

# ========================
# Task- 12 BACKUP FUNCTION
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

        try {
            $itemsToCopy = Get-ChildItem $sourcePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Log "ERROR: Failed to read source: $sourcePath"
            continue
        }

        # =========================
        # FILTER LOGIC
        # =========================

        if ($ServerType -in @("Application","Batch","ReportDelivery","ReportServer")) {

            $itemsToCopy = $itemsToCopy | Where-Object {

                if ($_.PSIsContainer) { return $true }

                foreach ($path in $excludeTxtPaths) {
                    if ($_.FullName -like $path -and $_.Extension -eq ".txt") {
                        return $false
                    }
                }

                if ($ServerType -eq "ReportDelivery" -and $_.Extension -in @(".log",".txt")) { return $false }

                if ($_.Extension -in @(".zip",".pdf",".gpg",".pgp",".ipm",".A001",".A004",".A005",".A006",".xlsx",".out",".log",".html")) { return $false }

                if ($_.Name -match "^(ACH12|LogFileStep|BulkFileResponse_|MCI.AR.T|YTF.AR.T120|ACH-RET-)") { return $false }

                if ($_.Extension -eq ".csv" -and $_.Name -ne "amortizationSourceFileinfo.csv") { return $false }

                return $true
            }

        } else {
            Log "No exclusion applied for ServerType: $ServerType (full copy)"
        }

        # =========================
        # COPY LOGIC
        # =========================

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
                Log "Skipped file: $($item.FullName)"
            }
        }

        Write-Progress -Activity "Copying Files" -Completed

        # =========================
        # SUMMARY
        # =========================

        $sourceFileCount   = (Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue).Count
        $sourceFolderCount = (Get-ChildItem $sourcePath -Recurse -Directory -ErrorAction SilentlyContinue).Count

        $destFileCount     = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue).Count
        $destFolderCount   = (Get-ChildItem $destinationPath -Recurse -Directory -ErrorAction SilentlyContinue).Count

        $size = (Get-ChildItem $destinationPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $sizeMB = [math]::Round(($size / 1MB), 2)

        Log "Summary for ${sourcePath}:"
        Log "Source Files       : $sourceFileCount"
        Log "Source Folders     : $sourceFolderCount"
        Log "Destination Files  : $destFileCount"
        Log "Destination Folders: $destFolderCount"
        Log "Backup Size (MB)   : $sizeMB"
    }

    # =========================
    # SINGLE FILE COPY
    # =========================

    if ($singleFile -and (Test-Path $singleFile)) {
        try {
            Copy-Item $singleFile $destinationRoot -Force
            Log "Copied single file: $singleFile"
        }
        catch {
            Log "Failed to copy single file: $singleFile"
        }
    }

    Log "===== BACKUP COMPLETED SUCCESSFULLY ====="
}

# ========================
# task- 14 USER INPUT
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

#Stop-Transcript

# ========================
# Task- 15 TASK EXPORT
# ========================

Log "`n=== TASK EXPORT (BEFORE ZIP) ==="

$taskExportDir = "D:\Backup\$hostname\Task"

if (-not (Test-Path $taskExportDir)) {
    New-Item -Path $taskExportDir -ItemType Directory -Force | Out-Null
    Log "Created Task export directory: $taskExportDir"
}

$doExport = Read-Host "Do you want to EXPORT tasks? (y/n)"

if ($doExport.Trim().ToLower() -eq "y") {

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
# Task- 16 ZIP BACKUP
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
#----------------------
# ========================
# Task- 17 GLOBAL 7-ZIP CONFIG
# ========================
$sevenZipBase = "D:\CC_Scripts\Powershell_MD\Others\7-Zip"
$sevenZipExe  = Join-Path $sevenZipBase "7z.exe"

if (!(Test-Path $sevenZipExe)) {
    Write-Host "7-Zip not found at: $sevenZipExe" -ForegroundColor Red
    exit
}

# ========================
# Task- 18 COMMON ZIP FUNCTION
# ========================
function Zip-FolderWith7Zip {
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
        Write-Host "Zipping: $(Split-Path $folderPath -Leaf)" -ForegroundColor Cyan

        
        Push-Location $folderPath
        & $sevenZipExe a -tzip $zipPath * -mx=5 | Out-Null
        Pop-Location

        Write-Host "ZIP Created: $zipPath" -ForegroundColor Green
    }
    catch {
        Write-Host "ZIP Failed: $folderPath" -ForegroundColor Red
    }

    if ($isEmpty -and (Test-Path $tempFile)) {
        Remove-Item $tempFile -Force
    }

    
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
        Write-Host "Validated: $zipPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Invalid ZIP: $zipPath" -ForegroundColor Red
    }
}

# ========================
# Task- 19 ZIP MonitoringScript
# ========================

Log "`nSTEP 1: MonitoringScript"

$doStep1 = Ask-YesNo "Zip folders inside MonitoringScript?"

if ($doStep1) {

    if (Test-Path $monitorPath) {

        $folders = Get-ChildItem -Path $monitorPath -Directory -ErrorAction SilentlyContinue

        if ($folders -and $folders.Count -gt 0) {

            $total = $folders.Count
            $current = 0

            foreach ($folder in $folders) {

                $current++

                $percent = if ($total -gt 0) {
                    [math]::Round(($current / $total) * 100, 2)
                } else { 100 }

                Write-Progress -Activity "Zipping MonitoringScript folders" `
                               -Status "$percent% - $($folder.Name)" `
                               -PercentComplete $percent

                try {
                    Zip-FolderWith7Zip $folder.FullName
                }
                catch {
                    Log "ERROR while zipping: $($folder.FullName) - $_"
                }
            }

            Write-Progress -Activity "Zipping MonitoringScript folders" -Completed

        } else {
            Log "No folders found inside MonitoringScript"
        }

        # DELETE OPTION (SAFE)
        $deleteChoice = Ask-YesNo "Delete original folders from MonitoringScript?"

        if ($deleteChoice -and $folders) {

            foreach ($folder in $folders) {
                try {
                    Remove-Item $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Log "Deleted: $($folder.Name)"
                }
                catch {
                    Log "Failed to delete: $($folder.FullName)"
                }
            }

        } else {
            Log "Skipping deletion for MonitoringScript"
        }

    } else {

        Log "MonitoringScript path not found: $monitorPath"
        Log "Skipping MonitoringScript step and continuing..."

    }

} else {

    Log "User skipped MonitoringScript processing."

}

# ========================
# Task- 20 ZIP DBBSetup
# ========================

Log "`nProceeding to DBBSetup..."

$continueStep2 = Ask-YesNo "Do you want to continue and zip folders inside DBBSetup?"

if ($continueStep2) {

    Log "`nSTEP 2: DBBSetup"

    if (Test-Path $dbbPath) {

        $folders = Get-ChildItem -Path $dbbPath -Directory -ErrorAction SilentlyContinue

        if ($folders -and $folders.Count -gt 0) {

            $total = $folders.Count
            $current = 0

            foreach ($folder in $folders) {

                $current++

                $percent = if ($total -gt 0) {
                    [math]::Round(($current / $total) * 100, 2)
                } else { 100 }

                Write-Progress -Activity "Zipping DBBSetup folders" `
                               -Status "$percent% - $($folder.Name)" `
                               -PercentComplete $percent

                try {
                    Zip-FolderWith7Zip $folder.FullName
                }
                catch {
                    Log "ERROR while zipping: $($folder.FullName) - $_"
                }
            }

            Write-Progress -Activity "Zipping DBBSetup folders" -Completed

        } else {
            Log "No folders found inside DBBSetup"
        }

        # DELETE OPTION (SAFE)
        $deleteChoice = Ask-YesNo "Delete original folders from DBBSetup?"

        if ($deleteChoice -and $folders) {

            foreach ($folder in $folders) {
                try {
                    Remove-Item $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Log "Deleted: $($folder.Name)"
                }
                catch {
                    Log "Failed to delete: $($folder.FullName)"
                }
            }

        } else {
            Log "Skipping deletion for DBBSetup"
        }

    } else {

        Log "DBBSetup path not found: $dbbPath"
        Log "Skipping DBBSetup step and continuing script..."

    }

} else {

    Log "User skipped DBBSetup processing."

}

# ========================
# Task- 21 ZIP Main Folder
# ========================

Write-Host "`nSTEP 3: Main Folder" -ForegroundColor Cyan

$zipMainChoice = Read-Host "Do you want to create main backup ZIP? (y/n)"

if ($zipMainChoice -eq "y") {

    $hostname = $env:COMPUTERNAME
    $basePath = "D:\Backup\$hostname"
    $mainZip = "D:\Backup\$hostname.zip"

    # ========================
    # CHECK ONLY FOR BATCH SERVER
    # ========================

    if ($ServerType -eq "Batch") {

        $vcSettingsPath = Get-ChildItem -Path $basePath -Recurse -Filter "VC-Settings.zip" -ErrorAction SilentlyContinue | Select-Object -First 1

        if (-not $vcSettingsPath) {
            Write-Host "VC-Settings.zip is NOT available in backup." -ForegroundColor Red
            Write-Host "Please copy VC-Settings.zip first, then re-run script." -ForegroundColor Yellow
            Log "VC-Settings.zip missing. Aborting main ZIP creation."

            return
        }

        Write-Host "VC-Settings.zip found: $($vcSettingsPath.FullName)" -ForegroundColor Green
    }

    # ========================
    # PROCEED WITH ZIP
    # ========================

    if (Test-Path $mainZip) {
        Remove-Item $mainZip -Force
    }

    try {
        Write-Host "Zipping main folder using 7-Zip..." -ForegroundColor Cyan

        Write-Progress -Activity "Creating main backup ZIP" `
                       -Status "Starting..." `
                       -PercentComplete 10

        Push-Location $basePath
        & $sevenZipExe a -tzip $mainZip * -mx=5 | Out-Null
        Pop-Location

        Write-Progress -Activity "Creating main backup ZIP" `
                       -Status "Finalizing..." `
                       -PercentComplete 90

        Start-Sleep -Milliseconds 500

        Write-Progress -Activity "Creating main backup ZIP" -Completed

        Write-Host "ZIP created: $mainZip" -ForegroundColor Green
    }
    catch {
        Write-Host "ZIP failed: $_" -ForegroundColor Red
        return
    }

    # ========================
    # VALIDATION
    # ========================

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($mainZip).Dispose()
        Write-Host "ZIP validation successful" -ForegroundColor Green
    }
    catch {
        Write-Host "ZIP validation failed" -ForegroundColor Red
    }

} else {
    Write-Host "Skipped main folder zipping." -ForegroundColor Yellow
}

Log "`nProcess completed."

# ========================
# Task- 22: UPLOAD TO S3 (INDEPENDENT)
# ========================

Log "`n=== Task 22: UPLOAD TO S3 ==="

$uploadChoice = Read-Host "Upload to S3? (y/n)"

if ($uploadChoice.Trim().ToLower() -eq "y") {

    if (Test-Path $zipFile) {

        $fileName = Split-Path $zipFile -Leaf
        $fullS3Path = "$bucketPath$fileName"

        try {
            [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
            Log "ZIP validation passed. Uploading to S3..."

            Upload-S3

            Log "Upload complete"
            Log "S3 File Path: $fullS3Path"

            Log "Verifying S3..."
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
# Task-23 DOWNLOAD & DEPLOY
# ========================

function Download-And-Deploy-Package {

    Log "`n=== DOWNLOAD & DEPLOY STARTED ==="

    if ((Read-Host "Download package? (y/n)").Trim().ToLower() -ne "y") {
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
    # Task- 24 UNZIP FLOW
    # ========================

    $unzipChoice = Read-Host "`nDo you want to unzip and process backup? (y/n)"

    if ($unzipChoice.Trim().ToLower() -ne "y") {
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

    $folders = Get-ChildItem -Path $rootPath -Directory -Recurse

    foreach ($folder in $folders) {

        $duplicatePath = Join-Path $folder.FullName $folder.Name

        
        if (Test-Path $duplicatePath) {

            Write-Host "Duplicate found: $duplicatePath" -ForegroundColor Cyan

            
            Get-ChildItem -Path $duplicatePath | ForEach-Object {

                $dest = Join-Path $folder.FullName $_.Name

                if (!(Test-Path $dest)) {
                    try {
                        Move-Item $_.FullName $folder.FullName -Force
                        Write-Host "Moved: $($_.Name)"
                    }
                    catch {
                        Write-Host "Skipped (move failed): $($_.Name)" -ForegroundColor Yellow
                    }
                }
                else {
                    
                    Write-Host "Skipped (already exists): $($_.Name)" -ForegroundColor DarkYellow
                }
            }

            
            if ((Get-ChildItem $duplicatePath -Force | Measure-Object).Count -eq 0) {
                Remove-Item $duplicatePath -Recurse -Force
                Write-Host "Removed empty duplicate folder" -ForegroundColor Green
            }
            else {
                Write-Host "Duplicate not removed (still contains data)" -ForegroundColor Yellow
            }
        }
    }
}

    # ========================
    # Task-25 PATHS
    # ========================

    $hostname = $env:COMPUTERNAME
    $mainZip = $zipFileLocal
    $unzipRoot = "D:\Backup\Package_Unzip\$hostname"

    # ========================
    # Task- 26 UNZIP MAIN
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
    # Task- 27 FIND DBBSetup
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
    # Task-28 UNZIP INTERNAL
    # ========================

    Log "Extracting all internal zip files..."
    Expand-ZipRecursively -folderPath $dbbPath

    # ========================
# Task- 29 DEPLOY Code
# ========================

if ((Read-Host "Deploy files? (y/n)").Trim().ToLower() -ne "y") {
    Log "Deployment skipped"
    return
}

$target = "D:\DBBSetup"
$folders = "MonitoringScript","Dump","Keys","VisualCron"

$total = $folders.Count
$current = 0

foreach ($f in $folders) {

    $current++
    $percent = [int](($current / $total) * 100)

    Write-Progress -Activity "Deploying Files" `
                   -Status "Copying $f ($current of $total)" `
                   -PercentComplete $percent

    $src = Join-Path $dbbPath $f
    $dst = Join-Path $target $f

    if (Test-Path $src) {
        Copy-Item $src $dst -Recurse -Force
        Log "$f copied to $target"
    }
    else {
        Log "WARNING: $f not found in source"
    }
}

# Complete the progress bar
Write-Progress -Activity "Deploying Files" -Completed

Log "Deployment Completed"
Log "=== DOWNLOAD & DEPLOY COMPLETED ==="
}

Download-And-Deploy-Package

# ========================
# Task- 29.1 CLEANUP ZIP FILES
# ========================

$cleanupChoice = Read-Host "`nDo you want to DELETE all .zip files from D:\DBBSetup\MonitoringScript? (y/n)"

if ($cleanupChoice.Trim().ToLower() -eq "y") {

    $zipFiles = Get-ChildItem "D:\DBBSetup\MonitoringScript" -Recurse -Filter *.zip -File -ErrorAction SilentlyContinue

    if ($zipFiles.Count -eq 0) {
        Log "No ZIP files found in MonitoringScript"
    }
    else {

        $total = $zipFiles.Count
        $count = 0

        foreach ($file in $zipFiles) {

            $count++

            $percent = [math]::Round(($count / $total) * 100, 2)

            Write-Progress -Activity "Deleting ZIP files" `
                           -Status "$percent% - $($file.Name)" `
                           -PercentComplete $percent

            try {
                Remove-Item $file.FullName -Force -ErrorAction Stop
            }
            catch {
                Log "Failed to delete: $($file.FullName)"
            }
        }

        Write-Progress -Activity "Deleting ZIP files" -Completed
        Log "All ZIP files deleted from MonitoringScript"
    }

} else {
    Log "ZIP cleanup skipped"
}

# ========================
# TASK- 29.2 VERIFY FILE COUNT After Deployment
# ========================

$compareChoice = Read-Host "`nDo you want to compare source and deployed folders? (y/n)"

if ($compareChoice.Trim().ToLower() -eq "y") {

    # Source paths
    $srcMonitoring = "D:\Backup\Package_Unzip\$hostname\DBBSetup\MonitoringScript"
    $srcKeys       = "D:\Backup\Package_Unzip\$hostname\DBBSetup\Keys"
    $srcDump       = "D:\Backup\Package_Unzip\$hostname\DBBSetup\Dump"

    # Target paths
    $dstMonitoring = "D:\DBBSetup\MonitoringScript"
    $dstKeys       = "D:\DBBSetup\Keys"
    $dstDump       = "D:\DBBSetup\Dump"

    function Get-FolderStats($path) {

        if (!(Test-Path $path)) {
            return @{
                Path = $path
                Files = 0
                Folders = 0
                Exists = $false
            }
        }

        # ?? Exclude ZIP files from count
        $files = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue |
                  Where-Object { $_.Extension -ne ".zip" }).Count

        $folders = (Get-ChildItem $path -Recurse -Directory -ErrorAction SilentlyContinue).Count

        return @{
            Path = $path
            Files = $files
            Folders = $folders
            Exists = $true
        }
    }

    # ------------------------
    # Get stats
    # ------------------------
    $srcMonStats = Get-FolderStats $srcMonitoring
    $dstMonStats = Get-FolderStats $dstMonitoring

    $srcKeyStats = Get-FolderStats $srcKeys
    $dstKeyStats = Get-FolderStats $dstKeys

     $srcDumpStats = Get-FolderStats $srcDump
    $dstDumpStats = Get-FolderStats $dstDump

    # ------------------------
    # MonitoringScript Compare
    # ------------------------
    Log "`n=== MonitoringScript Comparison ==="

    Log "Source Path : $($srcMonStats.Path)"
    Log "Target Path : $($dstMonStats.Path)"

    Log "Source: Files=$($srcMonStats.Files), Folders=$($srcMonStats.Folders)"
    Log "Target: Files=$($dstMonStats.Files), Folders=$($dstMonStats.Folders)"

    if ($srcMonStats.Files -eq $dstMonStats.Files -and $srcMonStats.Folders -eq $dstMonStats.Folders) {
        Log "MonitoringScript: MATCH ?"
    } else {
        Log "MonitoringScript: MISMATCH ?"
    }

    # ------------------------
    # Keys Compare
    # ------------------------
    Log "`n=== Keys Comparison ==="

    Log "Source Path : $($srcKeyStats.Path)"
    Log "Target Path : $($dstKeyStats.Path)"

    Log "Source: Files=$($srcKeyStats.Files), Folders=$($srcKeyStats.Folders)"
    Log "Target: Files=$($dstKeyStats.Files), Folders=$($dstKeyStats.Folders)"

    if ($srcKeyStats.Files -eq $dstKeyStats.Files -and $srcKeyStats.Folders -eq $dstKeyStats.Folders) {
        Log "Keys: MATCH ?"
    } else {
        Log "Keys: MISMATCH ?"
    }

    # ------------------------
    # Dump Compare
    # ------------------------
    Log "`n=== Dump Comparison ==="

    Log "Source Path : $($srcDumpStats.Path)"
    Log "Target Path : $($dstDumpStats.Path)"

    Log "Source: Files=$($srcDumpStats.Files), Folders=$($srcDumpStats.Folders)"
    Log "Target: Files=$($dstDumpStats.Files), Folders=$($dstDumpStats.Folders)"

    if ($srcDumpStats.Files -eq $dstDumpStats.Files -and $srcDumpStats.Folders -eq $dstDumpStats.Folders) {
        Log "Dumps: MATCH ?"
    } else {
        Log "Dumps: MISMATCH ?"
    }

}
else {
    Log "Comparison skipped"
}

# ========================
# Task- 30 ASK FOR IMPORT
# ========================

$doImport = Read-Host "`nDo you want to IMPORT tasks? (y/n)"

if ($doImport.Trim().ToLower() -ne "y") {
    Log "Skipping TASK IMPORT..."
    return
}

Log "`n=== TASK IMPORT STARTED ==="

# ========================
# Task- 31 CONFIGURATION
# ========================

$hostname = $env:COMPUTERNAME
$importDir = "D:\Backup\Package_Unzip\$hostname\Task"

$domain = $env:USERDOMAIN
$gmsaAccount = "$domain\gmsa-batch-svc$"

# ========================
# Task- 32 CHECK DIRECTORY
# ========================

if (-not (Test-Path $importDir)) {
    Log "Import directory not found: $importDir"
    return
}

# ========================
# Task- 33 IMPORT TASKS
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
# Task- 34 VALIDATION
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

Stop-Transcript