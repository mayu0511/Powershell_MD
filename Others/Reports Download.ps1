############################################################################################################
#Report Downaload | DEVELOPED BY:: Mahendra Dwivedi
#Version 1.0 Task Report Downaload | Updated by Mahendra | 02-May-26
############################################################################################################


Clear-Host
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$htmlPath = "C:\Temp\ReportServer_Validation_$timestamp.html"

$resultsURL = @()
$resultsItemLevel = @()
$resultsSystemLevel = @()
$resultsService = @()

# Resolve Host/IP
$hostname = $env:COMPUTERNAME
$ip = (Resolve-DnsName -Name $hostname -ErrorAction Stop | Where-Object { $_.Type -eq "A" }).IPAddress
$reportUrl = "http://$ip/ReportServer"
$wsdlUrl = "$reportUrl/ReportService2010.asmx?wsdl"

# Retrieve credentials
$envName = $env:USERDOMAIN.ToUpper().Split('-')[-1]
$secretId = "$envName/app-rw-secret"
$secretRaw = Get-SECSecretValue -SecretId $secretId
$secretJson = $secretRaw.SecretString | ConvertFrom-Json
$cred = New-Object PSCredential ($secretJson.username, (ConvertTo-SecureString $secretJson.password -AsPlainText -Force))

# ========== 1. Report Server URL Accessibility ==========

try {
    $response = Invoke-WebRequest -Uri $reportUrl -Credential $cred -UseBasicParsing -TimeoutSec 10
    $status = if ($response.StatusCode -eq 200 -and
        $response.RawContent -match "/ReportServer\s+-" -and
        $response.RawContent -match "CoreCreditReports" -and
        $response.RawContent -match "CoreIssueReports" -and
        $response.RawContent -match "Microsoft SQL Server Reporting Services Version") {
        "Accessible"
    } elseif ($response.StatusCode -eq 200) {
        "Content Mismatch"
    } else {
        "Unknown Status"
    }
} catch {
    $status = "URL Not Accessible: $($_.Exception.Message)"
}

$resultsURL += [PSCustomObject]@{
    'Validation Check List' = "Report Server URL Access"
    'Value'                 = $reportUrl
    'Status'                = $status
}

# ========== 5. Download RDL Backup (Final - No Duplicate Folders) ==========

try {
    Write-Host "Starting RDL backup..."

    $proxy = New-WebServiceProxy -Uri $wsdlUrl -Credential $cred

    $rootFolders = @(
        @{ SSRS = "/CoreCreditReports"; Local = "D:\Backup\$hostname\CoreCreditReports" },
        @{ SSRS = "/CoreIssueReports";  Local = "D:\Backup\$hostname\CoreIssueReports" }
    )

    foreach ($root in $rootFolders) {

        $folderPath = $root.SSRS
        $backupBase = $root.Local

        if (!(Test-Path $backupBase)) {
            New-Item -ItemType Directory -Path $backupBase -Force | Out-Null
        }

        Write-Host "`nProcessing Root: $folderPath"

        $items = $proxy.ListChildren($folderPath, $true)

        foreach ($item in $items) {

            Write-Host "Processing: $($item.Path) | Type: $($item.TypeName)"

            if ($item.TypeName -match "Report") {
                try {
                    $relativePath = $item.Path.Replace($folderPath, "").TrimStart("/")
                    $parts = $relativePath -split "/"
                    $reportName = $parts[-1]

                    if ($parts.Count -eq 1) {
                        # Root report → create its own folder
                        $reportFolder = Join-Path $backupBase $reportName
                    }
                    else {
                        # Nested → ONLY use subfolder path (no duplicate report folder)
                        $subPath = ($parts[0..($parts.Count - 2)] -join "\")
                        $reportFolder = Join-Path $backupBase $subPath
                    }

                    # File always inside final folder
                    $filePath = Join-Path $reportFolder ($reportName + ".rdl")

                    # Ensure folder exists
                    if (!(Test-Path $reportFolder)) {
                        New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null
                    }

                    # Download RDL
                    $rdlBytes = $proxy.GetItemDefinition($item.Path)

                    if ($rdlBytes -and $rdlBytes.Length -gt 0) {
                        [System.IO.File]::WriteAllBytes($filePath, $rdlBytes)
                        Write-Host "Downloaded: $filePath"
                    }
                    else {
                        Write-Host "Empty RDL: $($item.Path)"
                    }
                }
                catch {
                    Write-Host "FAILED: $($item.Path) -> $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Host "`nRDL backup completed for all folders."
}
catch {
    Write-Host "RDL Backup Failed: $($_.Exception.Message)"
}