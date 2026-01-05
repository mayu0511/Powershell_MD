######################################################################################################################
# Report Delivery Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.1 | Report Delivery Validation | Date:: 01-July-2025
#======================================================================================================================
dir D:\ -Recurse | Unblock-File

Clear-Host
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}



# ----------------- Setup Paths and Patterns -----------------
$results = @()
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$htmlFile = "C:\Temp\Report_Delivery_Report_$timestamp.html"

# ----------------- python.exe Check -----------------
$pythonPath = "D:\CC_Python\python.exe"
$existsPython = Test-Path $pythonPath

$results += [PSCustomObject]@{
    'Check'  = "Python Check"
    'Value'  = $pythonPath
    'Status' = if ($existsPython) { "Available" } else { "Missing" }
}

# ----------------- BCP Installation Check -----------------
try {
    $bcpPath = Get-Command "bcp" -ErrorAction Stop
    $bcpVersion = & "$($bcpPath.Source)" -v
    $bcpVersionClean = ($bcpVersion | Select-String 'BCP') -join " "
    $results += [PSCustomObject]@{
        'Check'  = "BCP Installation"
        'Value'  = $bcpVersionClean
        'Status' = "BCP Installed"
    }
} catch {
    $results += [PSCustomObject]@{
        'Check'  = "BCP Installation"
        'Value'  = "BCP is not installed"
        'Status' = "FAILED"
    }
}

# ----------------- Platform Version Check -----------------
$pathPlatform = "D:\PlatformCode\appsys30.dsl"
$patternPlatform = 'Application Release\s+([\d\.]+)'

try {
    $platformVersion = Select-String -Path $pathPlatform -Pattern 'Application Release' | ForEach-Object {
        if ($_ -match $patternPlatform) { $matches[1] }
    }
    $results += [PSCustomObject]@{
        'Check'  = "Platform Version"
        'Value'  = if ($platformVersion) { $platformVersion } else { "Not found" }
        'Status' = if ($platformVersion) { "OK" } else { "Missing" }
    }
} catch {
    $results += [PSCustomObject]@{
        'Check'  = "Platform Version"
        'Value'  = "Error reading file"
        'Status' = "ERROR"
    }
}

# ----------------- ODBC Check -----------------
$DBBCDrive = Get-OdbcDriver
$ODBCDSNList = Get-OdbcDsn
$DBBCDrivecheck = if ($DBBCDrive) { "ODBC Installed" } else { $null }

$ExpectedServers = @("CCAPPLIST1", "CCAPPSQLAG1", "CCRPTLIST1", "CCRPTSQLAG1")
$OdbcResult = [PSCustomObject]@{
    Check   = "ODBC Connection Check"
    Value   = "ODBC Not Installed"
    Status  = "FAILED"
    Details = ""
}

if ($DBBCDrivecheck -eq "ODBC Installed") {
    if ($ODBCDSNList.Count -eq 0) {
        $OdbcResult.Value = "No DSNs available"
    } else {
        $ErrorMessages = @()
        foreach ($dsn in $ODBCDSNList) {
            $errors = @()
            if ($dsn.PSObject.Properties.Name -contains "Platform" -and $dsn.Platform -ne "32-bit") {
                $errors += "Platform is '$($dsn.Platform)'"
            }
            if ($dsn.DriverName -ne "ODBC Driver 17 for SQL Server") {
                $errors += "DriverName is '$($dsn.DriverName)'"
            }
            if ($dsn.Attribute.MultiSubnetFailover -ne "Yes") {
                $errors += "MultiSubnetFailover is '$($dsn.Attribute.MultiSubnetFailover)'"
            }
            if (-not ($ExpectedServers -contains $dsn.Attribute.Server)) {
                $errors += "Server is '$($dsn.Attribute.Server)'"
            }
            if (-not ($ExpectedServers -contains $dsn.Attribute.Description)) {
                $errors += "Description is '$($dsn.Attribute.Description)'"
            }
            if ($errors.Count -gt 0) {
                $ErrorMessages += "DSN '$($dsn.Name)' failed: $($errors -join ", ")"
            }
        }

        if ($ErrorMessages.Count -eq 0) {
            $OdbcResult.Value = "ODBC Connection Configured"
            $OdbcResult.Status = "PASSED"
        } else {
            $OdbcResult.Value = "Validation issues found"
            $OdbcResult.Status = "FAILED"
            $OdbcResult.Details = $ErrorMessages -join "`n"
        }
    }
} else {
    $OdbcResult.Details = "ODBC Connection not Configured"
}
$results += $OdbcResult

# ----------------- ODBC Drivers Check -----------------
$odbcDrivers = @(
    @{ Name = "ODBC Driver 17 for SQL Server"; Path = "C:\Windows\System32\msodbcsql17.dll" },
    @{ Name = "ODBC Driver 13 for SQL Server"; Path = "C:\Windows\System32\msodbcsql13.dll" },
    @{ Name = "SQL Server Native Client 11.0"; Path = "C:\Windows\System32\sqlncli11.dll" }
)

$MissingDrivers = @()
foreach ($driver in $odbcDrivers) {
    if (-not (Test-Path -PathType Leaf $driver.Path)) {
        $MissingDrivers += "$($driver.Name) not installed at expected path: $($driver.Path)"
    }
}

$OdbcDriverCheckResult = [PSCustomObject]@{
    Check   = "ODBC Driver Installation"
    Value   = if ($MissingDrivers.Count -eq 0) { "All drivers installed" } else { "Missing drivers found" }
    Status  = if ($MissingDrivers.Count -eq 0) { "PASSED" } else { "FAILED" }
    Details = $MissingDrivers -join "`n"
}
$results += $OdbcDriverCheckResult

# ----------------- Check osql files -----------------
$osqlPaths = @(
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\osql.exe",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\osql.rll",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\osql.exe",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\osql.rll"
)
foreach ($path in $osqlPaths) {
    $results += [PSCustomObject]@{
        'Check'  = "Check osql file"
        'Value'  = $path
        'Status' = if (Test-Path $path) { "Available" } else { "Missing" }
    }
}

# ----------------- Translate.exe -----------------
$translatePath = "D:\PlatformCode\translate.exe"
$results += [PSCustomObject]@{
    'Check'  = "Translate.exe Check"
    'Value'  = $translatePath
    'Status' = if (Test-Path $translatePath) { "Available" } else { "Missing" }
}

# ----------------- RD WorkFlow Task -----------------
$taskName = "Task_RDWF"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$results += [PSCustomObject]@{
    'Check'  = "Scheduled Task - $taskName"
    'Value'  = $taskName
    'User'   = if ($task) { $task.Principal.UserId } else { "N/A" }
    'Status' = if ($task) { "Available" } else { "Missing" }
}

# ----------------- AWS Config/Secret/URL Checks -----------------
$envName = $env:USERDOMAIN.ToUpper().Split('-')[-1]
$secretId = "$envName/app-rw-secret"
$secretRaw = Get-SECSecretValue -SecretId $secretId
$secretJson = $secretRaw.SecretString | ConvertFrom-Json
$cred = New-Object PSCredential ($secretJson.username, (ConvertTo-SecureString $secretJson.password -AsPlainText -Force))

[xml]$xmlContent = Get-Content -Path "D:\ReportDelivery\ReportDelivery\WFRunReports.exe.config"

function Test-Url {
    param (
        [string]$url,
        [PSCredential]$cred
    )
    try {
        $response = Invoke-WebRequest -Uri $url -Credential $cred -UseBasicParsing -TimeoutSec 5
        return "HTTP $($response.StatusCode)"
    } catch {
        return "ERROR: $($_.Exception.Message)"
    }
}

foreach ($item in $xmlContent.configuration.appSettings.add) {
    $val = $item.value
    $status = if ($val -match '^https?://') { Test-Url $val $cred } else { "" }
    $results += [PSCustomObject]@{
        'Check'  = "appSettings - $($item.key)"
        'Value'  = $val
        'Status' = $status
    }
}

foreach ($conn in $xmlContent.configuration.connectionStrings.add) {
    $val = $conn.connectionString
    $status = if ($val -match '^https?://') { Test-Url $val $cred } else { "" }
    $results += [PSCustomObject]@{
        'Check'  = "connectionStrings - $($conn.name)"
        'Value'  = $val
        'Status' = $status
    }
}

foreach ($section in $xmlContent.configuration.applicationSettings.ChildNodes) {
    foreach ($setting in $section.setting) {
        $val = $setting.SelectSingleNode("value").InnerText
        $status = if ($val -match '^https?://') { Test-Url $val $cred } else { "" }
        $results += [PSCustomObject]@{
            'Check'  = "applicationSettings - $($setting.name)"
            'Value'  = $val
            'Status' = $status
        }
    }
}

# ----------------- HTML Report -----------------
$style = @"
<style>
    body { font-family: Segoe UI, sans-serif; background-color: #f4f4f4; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #999; padding: 8px; text-align: left; }
    th { background-color: #333; color: white; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .status-ok { background-color: #d4edda; color: #155724; font-weight: bold; }       /* Green */
    .status-failed { background-color: #f8d7da; color: #721c24; font-weight: bold; }   /* Red */
</style>
"@

$summaryStatus = if ($results.Status -contains 'FAILED' -or $results.Status -contains 'Missing' -or $results.Status -contains 'ERROR' -or $results.Status -contains 'Not found') {
    "<h3 style='color: red;'>Some checks failed. Please review the details below.</h3>"
} else {
    "<h3 style='color: green;'>All checks passed successfully.</h3>"
}

$htmlRows = foreach ($r in $results) {
    $status = $r.Status
    $statusClass = if ([string]::IsNullOrWhiteSpace($status) -or $status -match '^(Missing|FAILED|ERROR|Not found)') {
        "status-failed"
    } else {
        "status-ok"
    }

    "<tr><td>$($r.Check)</td><td>$($r.Value)</td><td class='$statusClass'>$status</td></tr>"
}

$html = @"
<html>
<head><title>Report Delivery Validation - $timestamp</title>
$style
</head>
<body>
<h2>Report Delivery Validation</h2>
$summaryStatus
<table>
<tr><th>Check</th><th>Value</th><th>Status</th></tr>
$htmlRows
</table>
</body>
</html>
"@

# Save and open HTML
$html | Out-File -FilePath $htmlFile -Encoding UTF8
Invoke-Item $htmlFile
