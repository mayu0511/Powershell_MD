############################################################################################################
#Report Downaload | DEVELOPED BY:: Mahendra Dwivedi
#Version 1.1 Task Report Downaload | Updated by Mahendra | 02-May-26
############################################################################################################

Clear-Host
$ErrorActionPreference = "Stop"

# ========================
# GLOBAL VARIABLES
# ========================

$hostname = $env:COMPUTERNAME
$hostnameLower = $hostname.ToLower()
$currentdate = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

$logFile = "C:\Temp\RDL_Backup_$timestamp.log"
$htmlPath = "C:\Temp\ReportServer_Validation_$timestamp.html"

# ========================
# LOG FUNCTION
# ========================

function Log {
    param([string]$msg, [string]$level = "INFO")

    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$level] : $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

# ========================
# RETRY FUNCTION
# ========================

function Invoke-WithRetry {
    param (
        [scriptblock]$Script,
        [int]$MaxRetries = 3,
        [int]$DelaySec = 5
    )

    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            return & $Script
        }
        catch {
            Log "Attempt $i failed: $($_.Exception.Message)" "WARN"
            if ($i -eq $MaxRetries) { throw }
            Start-Sleep -Seconds $DelaySec
        }
    }
}

# ========================
# ALERT FUNCTION
# ========================

function Send-Alert {
    param([string]$Message)

    Log "ALERT: $Message" "ERROR"

    # Email (configure if needed)
    try {
        Send-MailMessage `
            -To "your@email.com" `
            -From "rdl-backup@system.com" `
            -Subject "RDL Backup FAILED - $hostname" `
            -Body $Message `
            -SmtpServer "smtp.yourcompany.com"
    }
    catch {
        Log "Email alert failed: $_" "WARN"
    }

    # Optional webhook (Slack/Teams)
    # Invoke-RestMethod -Uri "<webhook-url>" -Method Post -Body (@{text=$Message} | ConvertTo-Json)
}

# ========================
# REPORT SERVER CONFIG
# ========================

$ip = (Resolve-DnsName -Name $hostname | Where-Object { $_.Type -eq "A" }).IPAddress
$reportUrl = "http://$ip/ReportServer"
$wsdlUrl = "$reportUrl/ReportService2010.asmx?wsdl"

# Credentials
$envName = $env:USERDOMAIN.ToUpper().Split('-')[-1]
$secretId = "$envName/app-rw-secret"
$secretRaw = Get-SECSecretValue -SecretId $secretId
$secretJson = $secretRaw.SecretString | ConvertFrom-Json
$cred = New-Object PSCredential ($secretJson.username, (ConvertTo-SecureString $secretJson.password -AsPlainText -Force))

# ========================
# RDL DOWNLOAD
# ========================

try {
    Log "Starting RDL backup..."

    $proxy = New-WebServiceProxy -Uri $wsdlUrl -Credential $cred

    $rootFolders = @(
        @{ SSRS = "/CoreCreditReports"; Local = "D:\Backup\$hostname\CoreCreditReports" },
        @{ SSRS = "/CoreIssueReports";  Local = "D:\Backup\$hostname\CoreIssueReports" }
    )

    foreach ($root in $rootFolders) {

        $folderPath = $root.SSRS
        $backupBase = $root.Local

        New-Item -ItemType Directory -Path $backupBase -Force | Out-Null

        Log "Processing: $folderPath"

        $items = Invoke-WithRetry { $proxy.ListChildren($folderPath, $true) }

        foreach ($item in $items) {

            if ($item.TypeName -match "Report") {

                $relativePath = $item.Path.Replace($folderPath, "").TrimStart("/")
                $parts = $relativePath -split "/"
                $reportName = $parts[-1]

                if ($parts.Count -eq 1) {
                    $reportFolder = Join-Path $backupBase $reportName
                }
                else {
                    $subPath = ($parts[0..($parts.Count - 2)] -join "\")
                    $reportFolder = Join-Path $backupBase $subPath
                }

                $filePath = Join-Path $reportFolder ($reportName + ".rdl")
                New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null

                try {
                    $rdlBytes = Invoke-WithRetry { $proxy.GetItemDefinition($item.Path) }

                    if ($rdlBytes.Length -gt 0) {
                        [System.IO.File]::WriteAllBytes($filePath, $rdlBytes)
                        Log "Downloaded: $filePath"
                    }
                }
                catch {
                    Log "FAILED: $($item.Path)" "ERROR"
                }
            }
        }
    }

    Log "RDL backup completed"
}
catch {
    Send-Alert "RDL backup failed: $_"
    exit
}

# ========================
# ZIP BACKUP
# ========================

try {
    Log "Creating ZIP..."

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $backupRoot = "D:\Backup\$hostname"
    $zipFile = "D:\Backup\$hostname.zip"

    if (!(Test-Path $backupRoot)) {
        throw "Backup folder not found: $backupRoot"
    }

    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
    }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($backupRoot, $zipFile)

    # Validate ZIP
    [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()

    Log "ZIP created successfully: $zipFile"
}
catch {
    Log "ZIP creation failed: $_" "ERROR"
    Send-Alert "ZIP creation failed on $hostname : $_"
    exit
}

# ========================
# REGION DETECTION
# ========================

if ($hostnameLower -match "e1") { $Region = "us-east-1" }
elseif ($hostnameLower -match "w2") { $Region = "us-west-2" }
else {
    Send-Alert "Region detection failed"
    exit
}

# ========================
# POD DETECTION
# ========================

try {
    $pod = Invoke-WithRetry {
        (aws ec2 describe-instances `
            --filters "Name=tag:Name,Values=$hostnameLower" `
            --region $Region `
            --query "Reservations[*].Instances[*].Tags[?Key=='pod'].Value" `
            --output text).Trim().ToLower()
    }

    if (-not $pod) { throw "Empty POD" }
}
catch {
    Send-Alert "POD detection failed: $_"
    exit
}

# ========================
# ENV DETECTION
# ========================

if ($hostnameLower -match "patqa") { $envName = "patqa" }
elseif ($hostnameLower -match "patuat") { $envName = "patuat" }
elseif ($hostnameLower -match "perf") { $envName = "perf" }
elseif ($hostnameLower -match "uat") { $envName = "uat" }
elseif ($hostnameLower -match "dev") { $envName = "dev" }
elseif ($hostnameLower -match "qa") { $envName = "qa" }
elseif ($hostnameLower -match "prod") { $envName = "prod" }
else {
    Send-Alert "Env detection failed"
    exit
}

# ========================
# S3 UPLOAD
# ========================

# Define bucket path FIRST
#$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"
$bucketPath = "s3://corecard-$pod-$envName-$Region-config-files/Incoming/corecard/CC_BACKUP/$currentdate/"

$fileName = Split-Path $zipFile -Leaf
$fullS3Path = "$bucketPath$fileName"

try {
    Log "Uploading to S3..."

    Invoke-WithRetry -ActionName "S3 Upload" -Script {
        aws s3 cp $zipFile $bucketPath --region $Region --only-show-errors
        if ($LASTEXITCODE -ne 0) { throw "AWS CLI upload failed" }
    }

    Log "Upload successful"
    Log "Full S3 Path: $fullS3Path"
    Write-Host "S3 File: $fullS3Path"
}
catch {
    Log "S3 upload failed: $_" "ERROR"
    Send-Alert "S3 upload failed on $hostname : $_"
    exit
}

Log "===== COMPLETED SUCCESSFULLY ====="