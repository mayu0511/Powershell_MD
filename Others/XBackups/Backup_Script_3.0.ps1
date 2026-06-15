############################################################################################################
# Backup Script | DEVELOPED BY:: Mahendra Dwivedi
# Version 7.0 | Stable Full Script
############################################################################################################

Clear-Host
$ErrorActionPreference = "Stop"

# ========================
# VARIABLES
# ========================

$hostname = $env:COMPUTERNAME
$currentdate = Get-Date -Format "yyyyMMdd"

$sources = @(
"D:\DBBSetup",
"C:\Users\ccgs-app-rw\AppData\Roaming\gnupg"
)

$singleFile = "D:\DBBSetup\VisualCron\Backups\VC-Settings.zip"

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
# DETECT REGION FROM HOSTNAME
# ========================

Write-Host "Detecting AWS Region from hostname..." -ForegroundColor Cyan
Log "Detecting AWS Region from hostname"

$ThisServer = (hostname).ToLower()

if ($ThisServer -match "e1") {

$Region = "us-east-1"
$ShortRegion = "e1"

}
elseif ($ThisServer -match "w2") {

$Region = "us-west-2"
$ShortRegion = "w2"

}
else {

Write-Host "Unable to detect region from hostname: $ThisServer" -ForegroundColor Red
Log "Region detection failed from hostname"

exit

}

Write-Host "Hostname     : $ThisServer"
Write-Host "Region       : $Region"
Write-Host "ShortRegion  : $ShortRegion"

Log "Hostname detected: $ThisServer"
Log "Region detected: $Region"
Log "ShortRegion detected: $ShortRegion"


# ========================
# GET POD TAG VALUE
# ========================

$ThisServer = (hostname).ToLower()

Write-Host "Fetching POD tag from AWS..." -ForegroundColor Cyan

$podOutput = aws ec2 describe-instances `--filters "Name=tag:Name,Values=$ThisServer"`
--region $Region `--query "Reservations[*].Instances[*].Tags[?Key=='pod'].Value"`
--output text

$pod = $podOutput.Trim().ToLower()

if (-not $pod) {

Write-Host "Failed to detect POD tag." -ForegroundColor Red
exit

}

Write-Host "Detected POD : $pod" -ForegroundColor Green

# ========================
# DETECT ENV
# ========================

$hostnameLower = $hostname.ToLower()

if ($hostnameLower -match "patqa") { $envName = "patqa" }
elseif ($hostnameLower -match "perf") { $envName = "perf" }
elseif ($hostnameLower -match "uat") { $envName = "uat" }
elseif ($hostnameLower -match "patuat") { $envName = "patuat" }
elseif ($hostnameLower -match "dev") { $envName = "dev" }
elseif ($hostnameLower -match "qa") { $envName = "qa" }
elseif ($hostnameLower -match "prod") { $envName = "prod" }
else {
Write-Host "Environment detection failed." -ForegroundColor Red
exit
}

# ========================
# BUILD S3 PATH
# ========================

$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"

Write-Host ""
Write-Host "Environment : $envName"
Write-Host "Region      : $Region"
Write-Host "S3 Bucket   : $bucketPath"
Write-Host ""

# ========================
# BACKUP FUNCTION (LIVE STATUS + EXCLUSIONS)
# ========================

function Run-Backup {

Write-Host ""
Write-Host "Starting Backup..." -ForegroundColor Cyan
Log "Backup started"

if (!(Test-Path $destinationRoot)) {
New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
}

foreach ($sourcePath in $sources) {

if (!(Test-Path $sourcePath)) {
Write-Host "Skipping missing source: $sourcePath" -ForegroundColor Yellow
Log "Skipping missing source: $sourcePath"
continue
}

$folderName = Split-Path $sourcePath -Leaf
$destinationPath = Join-Path $destinationRoot $folderName

if (!(Test-Path $destinationPath)) {
New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
}

Write-Host ""
Write-Host "Scanning files in $sourcePath ..."
Log "Scanning source: $sourcePath"

$scanErrors = @()

$allFiles = Get-ChildItem -Path $sourcePath -Recurse -File -Force -ErrorAction SilentlyContinue -ErrorVariable scanErrors

if ($scanErrors.Count -gt 0) {
Log "Some files skipped during scan due to access issues."
}

# ========================
# APPLY EXCLUSION RULES
# ========================

$filteredFiles = $allFiles | Where-Object {

$item = $_

if (
$item.Extension -in @(
".log",".zip",".pdf",".gpg",".pgp",".ipm",
".A001",".A004",".A005",".A006",".Xlsx",".out"
)
) { return $false }

if (
$item.Name -match "^(ACH12|LogFileStep|BulkFileResponse_|MCI.AR.T|ACH-RET-)"
) { return $false }

if (
$item.Extension -eq ".csv" -and $item.Name -ne "amortizationSourceFileinfo.csv"
) { return $false }

return $true

}

$totalFiles = $filteredFiles.Count
$currentFile = 0

Write-Host "Total files to copy: $totalFiles"
Log "Total files to copy: $totalFiles"

foreach ($file in $filteredFiles) {

$currentFile++

$percent = [math]::Round(($currentFile / $totalFiles) * 100,2)

Write-Progress -Activity "Backup in progress" `
-Status "$percent% completed | Copying: $($file.Name)" `
-PercentComplete $percent

$destFile = $file.FullName.Replace($sourcePath,$destinationPath)
$destFolder = Split-Path $destFile -Parent

if (!(Test-Path $destFolder)) {
New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
}

try {
Copy-Item $file.FullName $destFile -Force
}
catch {
Log "Failed to copy: $($file.FullName)"
}

}

Write-Progress -Activity "Backup in progress" -Completed

}

# ========================
# COPY ADDITIONAL FILE
# ========================

if (Test-Path $singleFile) {

Write-Host ""
Write-Host "Copying additional file: $singleFile"
Log "Copying additional file"

Copy-Item $singleFile $destinationRoot -Force

}

Write-Host ""
Write-Host "Backup Completed Successfully." -ForegroundColor Green
Log "Backup completed"

}

# ========================
# CREATE ZIP
# ========================

function Create-Zip {

Write-Host "Creating ZIP..." -ForegroundColor Cyan

if (Test-Path $zipFile) {
Remove-Item $zipFile -Force
}

Compress-Archive -Path $destinationRoot -DestinationPath $zipFile -Force

Write-Host "ZIP Created: $zipFile" -ForegroundColor Green
Log "ZIP created"

}

# ========================
# VALIDATE ZIP
# ========================

function Validate-Zip {

Write-Host "Validating ZIP..." -ForegroundColor Cyan

if (!(Test-Path $zipFile)) {

Write-Host "ZIP file not found." -ForegroundColor Red
return $false

}

try {

Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipFile)
$zip.Dispose()

Write-Host "ZIP file is valid." -ForegroundColor Green
Log "ZIP validation passed"

return $true

}
catch {

Write-Host "ZIP file corrupted." -ForegroundColor Red
Log "ZIP validation failed"

return $false

}

}

# ========================
# S3 UPLOAD
# ========================

function Upload-S3 {

if (!(Test-Path $zipFile)) {

Write-Host "ZIP not found. Upload skipped." -ForegroundColor Yellow
return

}

Write-Host "Uploading ZIP to S3..." -ForegroundColor Cyan

aws s3 cp $zipFile $bucketPath

Write-Host "Upload completed." -ForegroundColor Green
Log "Upload completed"

}

# ========================
# VERIFY S3
# ========================

function Verify-S3 {

Write-Host ""
Write-Host "Files in S3:" -ForegroundColor Cyan

aws s3 ls $bucketPath

Log "S3 verification completed"

}

# ========================
# USER INPUT BACKUP
# ========================

$backupChoice = Read-Host "Do you want to take backup? (yes/no)"

if ($backupChoice -eq "yes") {

Run-Backup
Create-Zip

$zipValid = Validate-Zip

if (-not $zipValid) {

Write-Host "ZIP validation failed. Upload stopped." -ForegroundColor Red
exit

}

}
elseif ($backupChoice -eq "no") {

Write-Host "Backup skipped." -ForegroundColor Yellow

}
else {

Write-Host "Invalid input." -ForegroundColor Red
exit

}

# ========================
# USER INPUT S3
# ========================

$uploadChoice = Read-Host "Do you want to upload package to S3? (yes/no)"

if ($uploadChoice -eq "yes") {

Upload-S3
Verify-S3

}
elseif ($uploadChoice -eq "no") {

Write-Host "Upload skipped." -ForegroundColor Yellow

}
else {

Write-Host "Invalid input." -ForegroundColor Red

}

Log "Script completed"
############################################################################################################