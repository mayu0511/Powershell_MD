######################################################################################################################
# Report Server (SSRS) Validation Script  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.1 | Report Server (SSRS) Validation Script | Date:: 02-July-2025
#======================================================================================================================
Clear-Host
Get-ChildItem D:\ -Recurse | Unblock-File
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

# ========== 2. Manage (Folder) Permissions Validation ==========

try {
    $proxy = New-WebServiceProxy -Uri $wsdlUrl -Namespace "SSRS" -Credential $cred
    $policies, [ref]$inherited = $null, $false
    $policies = $proxy.GetPolicies("/", [ref]$inherited)

    $ExpectedPermissions = @(
        @{ ShortUser = "Administrators"; Roles = @("Content Manager") },
        @{ ShortUser = "gmsa-web-svc$"; Roles = @("Browser", "Content Manager", "My Reports", "Publisher", "Report Builder") },
        @{ ShortUser = "gmsa-app-svc$"; Roles = @("Browser", "Content Manager", "My Reports", "Publisher", "Report Builder") },
        @{ ShortUser = "ccgs-app-rw"; Roles = @("Browser", "Content Manager", "My Reports", "Publisher", "Report Builder") },
        @{ ShortUser = "ccgs-sql-rw"; Roles = @("Browser", "Content Manager", "My Reports", "Publisher", "Report Builder") },
        @{ ShortUser = "ccgs-web-rw"; Roles = @("Browser", "Content Manager", "My Reports", "Publisher", "Report Builder") },
        @{ ShortUser = "ccgs-rpts-svc"; Roles = @("Browser", "Content Manager", "My Reports", "Publisher", "Report Builder") }
    )

    foreach ($expected in $ExpectedPermissions) {
        $shortUser = $expected.ShortUser
        $expectedRoles = $expected.Roles
        $matchedPolicy = $policies | Where-Object { $_.GroupUserName -like "*$shortUser" }

        if (-not $matchedPolicy) {
            $resultsItemLevel += [PSCustomObject]@{
                'User'   = $shortUser
                'Roles'  = "-"
                'Status' = "FAILED - User not found"
            }
            continue
        }

        $actualRoles = $matchedPolicy.Roles | ForEach-Object { $_.Name }
        $missingRoles = $expectedRoles | Where-Object { $_ -notin $actualRoles }

        $resultsItemLevel += [PSCustomObject]@{
            'User'   = $shortUser
            'Roles'  = ($actualRoles -join ', ')
            'Status' = if ($missingRoles.Count -eq 0) { "PASSED" } else { "FAILED - Missing: $($missingRoles -join ', ')" }
        }
    }
} catch {
    $resultsItemLevel += [PSCustomObject]@{
        'User'   = "N/A"
        'Roles'  = "N/A"
        'Status' = "ERROR - $($_.Exception.Message)"
    }
}

# ========== 3. Security Site Setting Permission Validation ==========

try {
    $systemPolicies = $proxy.GetSystemPolicies()
    $ExpectedSitePermissions = @(
        @{ ShortUser = "Administrators"; Roles = @("System Administrator") },
        @{ ShortUser = "gmsa-web-svc$"; Roles = @("System Administrator", "System User") },
        @{ ShortUser = "gmsa-app-svc$"; Roles = @("System Administrator", "System User") },
        @{ ShortUser = "ccgs-web-rw";   Roles = @("System Administrator", "System User") },
        @{ ShortUser = "ccgs-sql-rw";   Roles = @("System Administrator", "System User") },
        @{ ShortUser = "ccgs-rpts-svc";   Roles = @("System Administrator", "System User") },
        @{ ShortUser = "ccgs-app-rw";   Roles = @("System Administrator", "System User") }
    )

    foreach ($expected in $ExpectedSitePermissions) {
        $shortUser = $expected.ShortUser
        $expectedRoles = $expected.Roles
        $matched = $systemPolicies | Where-Object { $_.GroupUserName -like "*$shortUser" }

        if (-not $matched) {
            $resultsSystemLevel += [PSCustomObject]@{
                'User'   = $shortUser
                'Roles'  = "-"
                'Status' = "FAILED - User not found"
            }
            continue
        }

        $actualRoles = $matched.Roles | ForEach-Object { $_.Name }
        $missingRoles = $expectedRoles | Where-Object { $_ -notin $actualRoles }

        $resultsSystemLevel += [PSCustomObject]@{
            'User'   = $shortUser
            'Roles'  = ($actualRoles -join ', ')
            'Status' = if ($missingRoles.Count -eq 0) { "PASSED" } else { "FAILED - Missing: $($missingRoles -join ', ')" }
        }
    }
} catch {
    $resultsSystemLevel += [PSCustomObject]@{
        'User'   = "N/A"
        'Roles'  = "N/A"
        'Status' = "ERROR - $($_.Exception.Message)"
    }
}

# ========== 4. ReportServer Service Validation ==========

$serviceName = "SQL Server Reporting Services (REPORTSERVER)"
$Domain = $Env:USERDOMAIN
$accountName = "$Domain\ccgs-rpts-svc"

try {
    $service = Get-Service -Name $serviceName -ErrorAction Stop
    $status = $service.Status
    $serviceAccount = (Get-WmiObject -Class Win32_Service -Filter "Name='$($service.Name)'" -ErrorAction Stop).StartName

    if ($status -eq "Running" -and $serviceAccount -eq $accountName) {
        $resultsService += [PSCustomObject]@{
            'Check'  = $serviceName
            'Value'  = $accountName
            'Status' = "PASSED"
        }
    } elseif ($status -eq "Running") {
        $resultsService += [PSCustomObject]@{
            'Check'  = $serviceName
            'Value'  = $serviceAccount
            'Status' = "FAILED - Wrong account"
        }
    } else {
        $resultsService += [PSCustomObject]@{
            'Check'  = $serviceName
            'Value'  = $status
            'Status' = "FAILED - Not running"
        }
    }
} catch {
    $resultsService += [PSCustomObject]@{
        'Check'  = $serviceName
        'Value'  = "-"
        'Status' = "ERROR - $($_.Exception.Message)"
    }
}

# ========== Generate HTML Report ==========

$html = @"
<html>
<head>
    <meta charset='UTF-8'>
    <meta http-equiv='X-UA-Compatible' content='IE=edge' />
    <title>ReportServer Validation</title>
    <style>
        body { font-family: Arial, sans-serif; font-size: 14px; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 30px; table-layout: fixed; word-wrap: break-word; }
        th, td { border: 1px solid #ccc; padding: 10px; text-align: left; vertical-align: middle; }
        th { background-color: #007ACC; color: white; font-weight: bold; }
        th:nth-child(1), td:nth-child(1) { width: 30%; }
        th:nth-child(2), td:nth-child(2) { width: 45%; }
        th:nth-child(3), td:nth-child(3) { width: 25%; }
        .PASSED, .Accessible { background-color: #d4edda; color: #155724; font-weight: bold; }
        .FAILED, .ContentMismatch, .URLNotAccessible, .ERROR { background-color: #f8d7da; color: #721c24; font-weight: bold; }
    </style>
</head>
<body>

    <h3>1. Report Server URL Validation</h3>
    <table>
        <tr><th>Validation Check List</th><th>Value</th><th>Status</th></tr>
"@

foreach ($r in $resultsURL) {
    $css = if ($r.Status -like "Accessible") { "Accessible" } elseif ($r.Status -like "Content Mismatch") { "ContentMismatch" } else { "URLNotAccessible" }
    $html += "<tr><td>$($r.'Validation Check List')</td><td>$($r.Value)</td><td class='$css'>$($r.Status)</td></tr>`n"
}

$html += @"
    </table>

    <h3>2. Manage Folder Permission Validation</h3>
    <table>
        <tr><th>User</th><th>Roles</th><th>Status</th></tr>
"@

foreach ($r in $resultsItemLevel) {
    $css = if ($r.Status -like "PASSED*") { "PASSED" } else { "FAILED" }
    $html += "<tr><td>$($r.User)</td><td>$($r.Roles)</td><td class='$css'>$($r.Status)</td></tr>`n"
}

$html += @"
    </table>

    <h3>3. Security Site Setting Permission Validation</h3>
    <table>
        <tr><th>User</th><th>Roles</th><th>Status</th></tr>
"@

foreach ($r in $resultsSystemLevel) {
    $css = if ($r.Status -like "PASSED*") { "PASSED" } else { "FAILED" }
    $html += "<tr><td>$($r.User)</td><td>$($r.Roles)</td><td class='$css'>$($r.Status)</td></tr>`n"
}

$html += @"
    </table>

    <h3>4. ReportServer Windows Service Validation</h3>
    <table>
        <tr><th>Service</th><th>Account / Value</th><th>Status</th></tr>
"@

foreach ($r in $resultsService) {
    $css = if ($r.Status -like "PASSED") { "PASSED" } else { "FAILED" }
    $html += "<tr><td>$($r.Check)</td><td>$($r.Value)</td><td class='$css'>$($r.Status)</td></tr>`n"
}

$html += @"
    </table>
</body>
</html>
"@

# Save and open
$html | Out-File -FilePath $htmlPath -Encoding UTF8
Start-Process $htmlPath
