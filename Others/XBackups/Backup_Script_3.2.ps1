############################################################################################################
# Backup Script | DEVELOPED BY:: Mahendra Dwivedi
# Version 3.2 | Auto Server Detection + Folder Backup + Counts
############################################################################################################

Clear-Host
$ErrorActionPreference = "Stop"

# ========================
# VARIABLES
# ========================

$hostname = $env:COMPUTERNAME
$currentdate = Get-Date -Format "yyyyMMdd"

$destinationRoot = "D:\Backup\$hostname"
$zipFile = "D:\Backup\$hostname.zip"

$logPath = "C:\TEMP\BackupCopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# ========================
# LOG FUNCTION
# ========================

function Log {
param([string]$msg)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logPath -Value "[$timestamp] $msg"
}

# ========================
# AUTO DETECT SERVER TYPE
# ========================

Write-Host "Detecting Server Type..." -ForegroundColor Cyan
$hostnameLower = $hostname.ToLower()

if ($hostnameLower -match "ccsvc|ccsrc|ccsnk") {

$ServerType = "Application"
$sources = @("D:\DBBSetup")
$singleFile = ""

}

elseif ($hostnameLower -match "ccweb") {

$ServerType = "Web"
$sources = @("D:\WebServer")
$singleFile = ""

}

elseif ($hostnameLower -match "ccew") {

$ServerType = "Web"
$sources = @("D:\WebServer")
$singleFile = ""

}

elseif ($hostnameLower -match "cckms") {

$ServerType = "Kms"
$sources = @("D:\KMS")
$singleFile = ""

}

elseif ($hostnameLower -match "ccwcf") {

$ServerType = "WCF"
$sources = @("D:\WebServer")
$singleFile = ""

}

elseif ($hostnameLower -match "ccbat") {

$ServerType = "Batch"

$sources = @(
"D:\DBBSetup",
"C:\Users\ccgs-app-rw\AppData\Roaming\gnupg"
)

$singleFile = "D:\DBBSetup\VisualCron\Backups\VC-Settings.zip"

}

elseif ($hostnameLower -match "ccrpd") {

$ServerType = "ReportDelivery"
$sources = @("D:\ReportDelivery")
$singleFile = ""

}

elseif ($hostnameLower -match "ccrps") {

$ServerType = "Report"
$sources = @("D:\Reportserver")
$singleFile = ""

}

else {

Write-Host "Server type detection failed." -ForegroundColor Red
exit

}

Write-Host "Server Type : $ServerType" -ForegroundColor Green

# ========================
# REGION DETECTION
# ========================

$ThisServer = $hostnameLower

if ($ThisServer -match "e1") {
$Region = "us-east-1"
}
elseif ($ThisServer -match "w2") {
$Region = "us-west-2"
}
else {
Write-Host "Region detection failed"
exit
}

# ========================
# POD DETECTION
# ========================

Write-Host "Fetching POD tag..."

$podOutput = aws ec2 describe-instances `
--filters "Name=tag:Name,Values=$ThisServer" `
--region $Region `
--query "Reservations[*].Instances[*].Tags[?Key=='pod'].Value" `
--output text

$pod = $podOutput.Trim().ToLower()

if (-not $pod) {
Write-Host "Failed to detect POD"
exit
}

Write-Host "POD : $pod"

# ========================
# ENV DETECTION
# ========================

if ($hostnameLower -match "patqa") { $envName="patqa" }
elseif ($hostnameLower -match "perf") { $envName="perf" }
elseif ($hostnameLower -match "uat") { $envName="uat" }
elseif ($hostnameLower -match "dev") { $envName="dev" }
elseif ($hostnameLower -match "qa") { $envName="qa" }
elseif ($hostnameLower -match "patuat") { $envName="patuat" }
elseif ($hostnameLower -match "prod") { $envName="prod" }
else {
Write-Host "Environment detection failed"
exit
}

# ========================
# S3 PATH
# ========================

$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"

Write-Host ""
Write-Host "Environment : $envName"
Write-Host "Region      : $Region"
Write-Host "S3 Bucket   : $bucketPath"
Write-Host ""

# ========================
# BACKUP FUNCTION
# ========================

function Run-Backup {

Write-Host "Starting Backup..." -ForegroundColor Cyan

if (!(Test-Path $destinationRoot)) {
New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
}

foreach ($sourcePath in $sources) {

if (!(Test-Path $sourcePath)) {
Write-Host "Skipping missing source $sourcePath"
continue
}

$folderName = Split-Path $sourcePath -Leaf
$destinationPath = Join-Path $destinationRoot $folderName

if (!(Test-Path $destinationPath)) {
New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
}

Write-Host "Scanning $sourcePath"

# ========================
# COPY EMPTY FOLDERS
# ========================

$allFolders = Get-ChildItem $sourcePath -Recurse -Directory -Force -ErrorAction SilentlyContinue

foreach ($folder in $allFolders) {

$destFolder = $folder.FullName.Replace($sourcePath,$destinationPath)

if (!(Test-Path $destFolder)) {
New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
}

}

# ========================
# FILE FILTER
# ========================

$allFiles = Get-ChildItem $sourcePath -Recurse -File -Force -ErrorAction SilentlyContinue

$filteredFiles = $allFiles | Where-Object {

$item = $_

if ($ServerType -eq "ReportDelivery") {
if ($item.Extension -in @(".log",".txt")) { return $false }
}

if ($item.Extension -in @(
".zip",".pdf",".gpg",".pgp",".ipm",
".A001",".A004",".A005",".A006",".xlsx",".out"
)) { return $false }

if ($item.Name -match "^(ACH12|LogFileStep|BulkFileResponse_|MCI.AR.T||ACHProcessStep_|ACH-RET-)") { return $false }

if ($item.Extension -eq ".csv" -and $item.Name -ne "amortizationSourceFileinfo.csv") { return $false }

return $true
}

$totalFiles = $filteredFiles.Count
$currentFile = 0

foreach ($file in $filteredFiles) {

$currentFile++

$percent = [math]::Round(($currentFile / $totalFiles) * 100,2)

Write-Progress -Activity "Backup in progress" `
-Status "$percent% completed | Copying $($file.Name)" `
-PercentComplete $percent

$destFile = $file.FullName.Replace($sourcePath,$destinationPath)
$destFolder = Split-Path $destFile -Parent

if (!(Test-Path $destFolder)) {
New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
}

Copy-Item $file.FullName $destFile -Force

}

Write-Progress -Activity "Backup in progress" -Completed

# ========================
# PRINT COUNTS
# ========================

$sourceFileCount = (Get-ChildItem $sourcePath -Recurse -File -ErrorAction SilentlyContinue).Count
$sourceFolderCount = (Get-ChildItem $sourcePath -Recurse -Directory -ErrorAction SilentlyContinue).Count

$destFileCount = (Get-ChildItem $destinationPath -Recurse -File).Count
$destFolderCount = (Get-ChildItem $destinationPath -Recurse -Directory).Count

$size = (Get-ChildItem $destinationPath -Recurse -File | Measure-Object Length -Sum).Sum
$sizeMB = [math]::Round($size / 1MB,2)

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

Write-Host "Backup Completed Successfully" -ForegroundColor Green
}

# ========================
# CREATE ZIP
# ========================

function Create-Zip {

if (Test-Path $zipFile) {
Remove-Item $zipFile -Force
}

Compress-Archive -Path $destinationRoot -DestinationPath $zipFile -Force

Write-Host "ZIP Created : $zipFile" -ForegroundColor Green

}

# ========================
# ZIP VALIDATION
# ========================

function Validate-Zip {

Add-Type -AssemblyName System.IO.Compression.FileSystem

try {

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipFile)
$zip.Dispose()

Write-Host "ZIP file valid" -ForegroundColor Green
return $true

}
catch {

Write-Host "ZIP corrupted" -ForegroundColor Red
return $false

}

}

# ========================
# S3 UPLOAD
# ========================

function Upload-S3 {

Write-Host "Uploading ZIP to S3..."
aws s3 cp $zipFile $bucketPath

}

function Verify-S3 {

aws s3 ls $bucketPath

}

# ========================
# USER INPUT
# ========================

$backupChoice = Read-Host "Do you want to take backup? (yes/no)"

if ($backupChoice -eq "yes") {

Run-Backup
Create-Zip

if (Validate-Zip) {

$uploadChoice = Read-Host "Upload ZIP to S3? (yes/no)"

if ($uploadChoice -eq "yes") {

Upload-S3
Verify-S3

}

}

}

Log "Script completed"

#################################################################
# DOWNLOAD AND DEPLOY PACKAGE
#################################################################

function Download-And-Deploy-Package {

$downloadChoice = Read-Host "Do you want to download package from S3? (yes/no)"

if ($downloadChoice -ne "yes") {
Write-Host "Skipping package download."
return
}

# ========================
# GET S3 PATH
# ========================

$s3Path = Read-Host "Enter S3 package location"

$downloadDir = "D:\Backup"
$zipName = Split-Path $s3Path -Leaf
$downloadFile = Join-Path $downloadDir $zipName

if (!(Test-Path $downloadDir)) {
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
}

Write-Host ""
Write-Host "Downloading package..." -ForegroundColor Cyan

aws s3 cp $s3Path $downloadFile

if (!(Test-Path $downloadFile)) {

Write-Host "Download failed." -ForegroundColor Red
return

}

Write-Host "Download completed : $downloadFile" -ForegroundColor Green

# ========================
# UNZIP PACKAGE
# ========================

$unzipFolder = "D:\Backup\Package_Unzip"

if (Test-Path $unzipFolder) {
Remove-Item $unzipFolder -Recurse -Force
}

Write-Host "Unzipping package..."

Expand-Archive $downloadFile $unzipFolder -Force

Write-Host "Unzip completed." -ForegroundColor Green

# ========================
# ASK USER TO COPY FILES
# ========================

$copyChoice = Read-Host "Do you want to copy MonitoringScript, Dump, Keys, VisualCron to D:\DBBSetup ? (yes/no)"

if ($copyChoice -ne "yes") {

Write-Host "Copy skipped."
return

}

# ========================
# FIND DBBSetup FOLDER
# ========================

$dbbFolder = Get-ChildItem $unzipFolder -Recurse -Directory |
Where-Object { $_.Name -eq "DBBSetup" } |
Select-Object -First 1

if (-not $dbbFolder) {

Write-Host "DBBSetup folder not found in package." -ForegroundColor Red
return

}

$sourceRoot = $dbbFolder.FullName
$targetRoot = "D:\DBBSetup"

Write-Host ""
Write-Host "Source      : $sourceRoot"
Write-Host "Destination : $targetRoot"
Write-Host ""

# ========================
# COPY REQUIRED FOLDERS
# ========================

$foldersToCopy = @(
"MonitoringScript",
"Dump",
"Keys",
"VisualCron"
)

foreach ($folder in $foldersToCopy) {

$sourceFolder = Join-Path $sourceRoot $folder
$destFolder = Join-Path $targetRoot $folder

if (Test-Path $sourceFolder) {

Write-Host "Copying $folder..." -ForegroundColor Cyan

Copy-Item $sourceFolder $destFolder -Recurse -Force

Write-Host "$folder copied." -ForegroundColor Green

}
else {

Write-Host "$folder not found in package." -ForegroundColor Yellow

}

}

Write-Host ""
Write-Host "Package deployment completed." -ForegroundColor Green

}

# CALL FUNCTION
Download-And-Deploy-Package