######################################################################################################################
# FileSplitter Validation | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.4 | FileSplitter Validation | Date:: 15-Aug-2025
#======================================================================================================================

dir D:\ -Recurse | Unblock-File

Clear-Host

# Clear all user-defined variables (excluding PowerShell internal ones)
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$htmlPath = "C:\Temp\FileSplitterValidation_$timestamp.html"

$resultsScheduledTask = @()
$resultsServiceDetails = @()
$resultsSecretValidation = @()

# ----------------- Scheduled Tasks -----------------
$TaskMappings = @(
    @{ Name = "ACHDownloaderSplitter";            Dir = "D:\DBBSetup\MonitoringScript\FileSplitter\ACHDownloaderSplitter\" },
    @{ Name = "BillPayPaymentDownloaderSplitter"; Dir = "D:\DBBSetup\MonitoringScript\FileSplitter\BillPayDownloaderSplitter\" },
    @{ Name = "EmbossingDownloaderSplitter";      Dir = "D:\DBBSetup\MonitoringScript\FileSplitter\EmbossingDownloaderSplitter\" },
    @{ Name = "LockBoxDownloaderSplitter";        Dir = "D:\DBBSetup\MonitoringScript\FileSplitter\LockBoxDownloaderSplitter\" },
    @{ Name = "MCCustomFeedDownloaderSplitter";   Dir = "D:\DBBSetup\MonitoringScript\FileSplitter\MCCustomFeedDownloaderSplitter\" },
    @{ Name = "NACKFileDownloaderSplitter";       Dir = "D:\DBBSetup\MonitoringScript\FileSplitter\NACKFileDownloaderSplitter\" },
    @{ Name = "T284DownloaderSplitter";           Dir = "D:\DBBSetup\MonitoringScript\FileSplitter\T284DownloaderSplitter\" }
)

foreach ($taskInfo in $TaskMappings) {
    $taskName = $taskInfo.Name
    $expectedDir = $taskInfo.Dir

    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($task) {
        # Trigger time (HTML-friendly)
        $triggerTime = "N/A"
        if ($task.Triggers) {
            $triggerTime = ($task.Triggers |
                Sort-Object { [datetime]$_.StartBoundary } |
                ForEach-Object {
                    "at " + (Get-Date $_.StartBoundary -Format "hh:mm tt") + " every day"
                }) -join "<br>"  # HTML line breaks
        }

        # Action details
        $action = ($task.Actions | Where-Object { $_.Execute }) | Select-Object -First 1
        $program = if ($action) { $action.Execute } else { "N/A" }
        $arguments = if ($action) { $action.Arguments } else { "N/A" }
        $workingDirectory = if ($action) { $action.WorkingDirectory } else { "N/A" }

        # User check
        $actualUser = $task.Principal.UserId
        if ($actualUser -ne "ccgs-app-service") {
            $actualUser = "<span style='color:red;'>$actualUser</span>"
        } else {
            $actualUser = "<span style='color:green;'>$actualUser</span>"
        }

        # Working directory check
        if ($workingDirectory -eq $expectedDir) {
            $workingDirectory = "<span style='color:green;'>$workingDirectory</span>"
        } else {
            $workingDirectory = "<span style='color:red;'>$workingDirectory</span>"
        }

        # Add result
        $resultsScheduledTask += [PSCustomObject]@{
            'Task Name'       = $taskName
            'Status'          = "Available"
            'User'            = $actualUser
            'Trigger Time'    = $triggerTime
            'Program/Script'  = $program
            'Start In'        = $workingDirectory
        }
    }
    else {
        $resultsScheduledTask += [PSCustomObject]@{
            'Task Name'       = $taskName
            'Status'          = "Missing"
            'User'            = "N/A"
            'Trigger Time'    = "N/A"
            'Program/Script'  = "N/A"
            'Start In'        = "N/A"
        }
    }
}

# ----------------- FileSplitter Services -----------------
$ServiceMappings = @(
    @{ Name = "PlatAmortizationFileSplitterService"; Path = "D:\DBBSetup\MonitoringScript\FileSplitter\AmortizationFileSplitter" },
    @{ Name = "PlatChargebackFileSplitterService";   Path = "D:\DBBSetup\MonitoringScript\FileSplitter\TQRFileSplitter" },
    @{ Name = "PlatEnrollmentFileSplitterService";   Path = "D:\DBBSetup\MonitoringScript\FileSplitter\EnrollmentFileSplitter" },
    @{ Name = "PlatIPMFileSplitterService";          Path = "D:\DBBSetup\MonitoringScript\FileSplitter\IPMFileSplitter" },
    @{ Name = "PlatT140FileSplitterService";         Path = "D:\DBBSetup\MonitoringScript\FileSplitter\T140FileSplitter" }
)

foreach ($svc in $ServiceMappings) {
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue

    if ($service) {
        # User check
        $expectedUser = ".\ccgs-app-service"
        $actualUser = if ($service.StartName -eq $expectedUser) { "<span style='color:green;'>$($service.StartName)</span>" } else { "<span style='color:red;'>$($service.StartName)</span>" }

        # Path check
        $actualPath = $service.PathName.Trim('"')
        if ($actualPath -like "$($svc.Path)*") { $actualPath = "<span style='color:green;'>$actualPath</span>" } else { $actualPath = "<span style='color:red;'>$actualPath</span>" }

        $resultsServiceDetails += [PSCustomObject]@{
            ServiceName    = $service.Name
            DisplayName    = $service.DisplayName
            Status         = $service.State
            LogOnAs        = $actualUser
            ExecutablePath = $actualPath
        }
    } else {
        $resultsServiceDetails += [PSCustomObject]@{
            ServiceName    = $svc.Name
            DisplayName    = "Service Not Found"
            Status         = "Not Found"
            LogOnAs        = "N/A"
            ExecutablePath = "N/A"
        }
    }
}

#--------File Splitter Secrets Validation -----

$Module = "File-Splitter"
$ServerType = 'fs'
$resultsSecretValidation = @()

# ----------------- Step 1: Get EC2 Metadata -----------------
try {
    $token = Invoke-RestMethod -Method PUT -Uri "http://169.254.169.254/latest/api/token" `
        -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }

    $identity = Invoke-RestMethod -Uri "http://169.254.169.254/latest/dynamic/instance-identity/document" `
        -Headers @{ "X-aws-ec2-metadata-token" = $token }

    $Region = $identity.region
    $InstanceId = $identity.instanceId
} catch {
    Write-Error "Error fetching EC2 metadata: $_"
    return
}

# ----------------- Step 2: Get Instance Environment -----------------
try {
    $AWSVariables = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        --query "Reservations[*].Instances[*].{InstanceId:InstanceId,Environment:Tags[?Key=='environment']|[0].Value}" | ConvertFrom-Json
} catch {
    Write-Error "Error describing instance: $_"
    return
}

$Instance = $AWSVariables[0][0]
$EnvironmentName = if ($Instance.Environment) { $Instance.Environment.ToUpper() } else { "QA" }

# ----------------- Step 3: Map Secrets per Environment -----------------
$SecretsMap = @{
    "PATUAT" = @(
       @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "chargeback-patuat-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "chargeback-patuat-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "chargeback-patuat-corecardpassphrase" },
        @{ VariableName = "AuthorizationUserIdAWSKey"; KeyName = "patuat-AuthorizationUserId" },
        @{ VariableName = "AuthorizationPwdAWSKey"; KeyName = "patuat-AuthorizationPwd" },
        @{ VariableName = "SMTPConfigurationAWSKey"; KeyName = "ses-smtp-patuat-secret" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "ach-patuat-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "ach-patuat-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "ach-patuat-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "ach-patuat-incoming-sshprivatekey" },
        @{ VariableName = "ClientFilePublicAWSKey"; KeyName = "ach-patuat-corecardpublickey" },
        @{ VariableName = "SFTPPrivateKeyAWSKey1"; KeyName = "PATUAT/mastercard-corecard-incoming-ssh-privatekey" },
        @{ VariableName = "BinRangeSecretsKey"; KeyName = "mastercard-patuat-bin-range" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "amortization-patuat-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "amortization-patuat-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "amortization-patuat-corecardpassphrase" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "ipm-patuat-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "ipm-patuat-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "ipm-patuat-corecardpassphrase" },
        @{ VariableName = "ClientFilePassPharseAWSKey"; KeyName = "ipm-patuat-corecardpassphrase" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "PATUAT/enrollment-corecard-publickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "PATUAT/enrollment-corecard-privatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "PATUAT/enrollment-corecard-passphrase" },
        @{ VariableName = "ClientFilePassPharseAWSKey"; KeyName = "PATUAT/enrollment-corecard-passphrase" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "billpay-patuat-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "billpay-patuat-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "billpay-patuat-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "billpay-patuat-incoming-sshprivatekey" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "embossing-patuat-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "embossing-patuat-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "embossing-patuat-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "embossing-patuat-incoming-sshprivatekey" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "lockbox-patuat-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "lockbox-patuat-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "lockbox-patuat-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "lockbox-patuat-incoming-sshprivatekey" },
        @{ VariableName = "ClientFilePublicAWSKey"; KeyName = "mastercard-patuat-corecardpublickey" }
        # Add all remaining PATUAT secrets here
    )
    "PROD" = @(
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "chargeback-prod-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "chargeback-prod-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "chargeback-prod-corecardpassphrase" },
        @{ VariableName = "AuthorizationUserIdAWSKey"; KeyName = "prod-AuthorizationUserId" },
        @{ VariableName = "AuthorizationPwdAWSKey"; KeyName = "prod-AuthorizationPwd" },
        @{ VariableName = "SMTPConfigurationAWSKey"; KeyName = "ses-smtp-prod-secret" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "ach-prod-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "ach-prod-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "ach-prod-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "ach-prod-incoming-sshprivatekey" },
        @{ VariableName = "ClientFilePublicAWSKey"; KeyName = "ach-prod-corecardpublickey" },
        @{ VariableName = "SFTPPrivateKeyAWSKey1"; KeyName = "PROD/mastercard-corecard-incoming-ssh-privatekey" },
        @{ VariableName = "BinRangeSecretsKey"; KeyName = "mastercard-prod-bin-range" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "amortization-prod-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "amortization-prod-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "amortization-prod-corecardpassphrase" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "ipm-prod-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "ipm-prod-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "ipm-prod-corecardpassphrase" },
        @{ VariableName = "ClientFilePassPharseAWSKey"; KeyName = "ipm-prod-corecardpassphrase" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "PROD/enrollment-corecard-publickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "PROD/enrollment-corecard-privatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "PROD/enrollment-corecard-passphrase" },
        @{ VariableName = "ClientFilePassPharseAWSKey"; KeyName = "PROD/enrollment-corecard-passphrase" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "billpay-prod-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "billpay-prod-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "billpay-prod-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "billpay-prod-incoming-sshprivatekey" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "embossing-prod-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "embossing-prod-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "embossing-prod-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "embossing-prod-incoming-sshprivatekey" },
        @{ VariableName = "OrignalFileEncryptionAWSKey"; KeyName = "lockbox-prod-corecardpublickey" },
        @{ VariableName = "OrignalFileDecryptionAWSKey"; KeyName = "lockbox-prod-corecardprivatekey" },
        @{ VariableName = "OrignalFilePassPharseAWSKey"; KeyName = "lockbox-prod-corecardpassphrase" },
        @{ VariableName = "SFTPPrivateKeyAWSKey"; KeyName = "lockbox-prod-incoming-sshprivatekey" },
        @{ VariableName = "ClientFilePublicAWSKey"; KeyName = "mastercard-prod-corecardpublickey" }
        # Add all remaining PROD secrets here
    )
}

# ----------------- Step 4: Deduplicate Secrets -----------------
$DeduplicatedSecrets = @{}
if ($SecretsMap.ContainsKey($EnvironmentName)) {
    foreach ($secret in $SecretsMap[$EnvironmentName]) {
        $compositeKey = "$($secret.VariableName.ToLower())|$($secret.KeyName.ToLower())"
        if (-not $DeduplicatedSecrets.ContainsKey($compositeKey)) {
            $DeduplicatedSecrets[$compositeKey] = $secret
        }
    }
}

# ----------------- Step 5: Validate Secrets -----------------
foreach ($secret in $DeduplicatedSecrets.Values) {
    $isValid = $false
    try {
        $valueObj = Get-SECSecretValue -SecretId $secret.KeyName -Region $Region
        $isValid = ($valueObj.SecretString -or $valueObj.SecretBinary) -ne $null
    } catch {
        Write-Warning "Secret $($secret.KeyName) could not be fetched: $_"
        $isValid = $false
    }

    $resultsSecretValidation += [PSCustomObject]@{
        Environment  = $EnvironmentName
        VariableName = $secret.VariableName
        KeyName      = $secret.KeyName
        Status       = if ($isValid) { "Pass" } else { "Failed" }
        Color        = if ($isValid) { "Green" } else { "Red" }
    }
}

# ----------------- Generate HTML Report -----------------
$html = @"
<html>
<head>
    <meta charset='UTF-8'>
    <title>FileSplitter Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; font-size: 14px; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 30px; table-layout: fixed; word-wrap: break-word; }
        th, td { border: 1px solid #ccc; padding: 10px; text-align: left; vertical-align: middle; }
        th { background-color: #007ACC; color: white; font-weight: bold; }
        .PASSED { background-color: #d4edda; color: #155724; font-weight: bold; }
        .FAILED { background-color: #f8d7da; color: #721c24; font-weight: bold; }
    </style>
</head>
<body>
    <h3>1. Scheduled Task Validation</h3>
    <table>
        <tr>
            <th>Task Name</th>
            <th>Status</th>
            <th>User</th>
            <th>Trigger Time</th>
            <th>Program/Script</th>
            <th>Start In</th>
        </tr>
"@

foreach ($r in $resultsScheduledTask) {
    $css = if ($r.Status -eq "Available") { "PASSED" } else { "FAILED" }
    $html += "<tr>
                <td>$($r.'Task Name')</td>
                <td class='$css'>$($r.Status)</td>
                <td>$($r.User)</td>
                <td>$($r.'Trigger Time')</td>
                <td>$($r.'Program/Script')</td>
                <td>$($r.'Start In')</td>
              </tr>`n"
}

$html += @"
    </table>

    <h3>2. FileSplitter Services Validation</h3>
    <table>
        <tr>
            <th>Service Name</th>
            <th>Display Name</th>
            <th>Status</th>
            <th>Log On As</th>
            <th>Executable Path</th>
        </tr>
"@

foreach ($svc in $resultsServiceDetails) {
    $css = if ($svc.Status -eq "Running") { "PASSED" } else { "FAILED" }
    $html += "<tr>
                <td>$($svc.ServiceName)</td>
                <td>$($svc.DisplayName)</td>
                <td class='$css'>$($svc.Status)</td>
                <td>$($svc.LogOnAs)</td>
                <td>$($svc.ExecutablePath)</td>
              </tr>`n"
}

$html += @"
    </table>

    <h3>3. AWS Secrets Validation</h3>
    <table>
        <tr>
            <th>Variable Name</th>
            <th>Secret Key Name</th>
            <th>Status</th>
        </tr>
"@

foreach ($secret in $resultsSecretValidation) {
    $css = if ($secret.Status -eq "Pass") { "PASSED" } else { "FAILED" }
    $html += "<tr>
                <td>$($secret.VariableName)</td>
                <td>$($secret.KeyName)</td>
                <td class='$css'>$($secret.Status)</td>
              </tr>`n"
}

$html += @"
    </table>
</body>
</html>
"@

# Save and Open Report
$html | Out-File -FilePath $htmlPath -Encoding UTF8
Start-Process $htmlPath
