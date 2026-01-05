######################################################################################################################
# Report Delivery Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Report Delivery Validation | Date:: 19-Aug-2025
#======================================================================================================================
dir D:\ -Recurse | Unblock-File

Clear-Host
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}

# ----------------- Setup -----------------
$results = @()
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$htmlFile = "C:\Temp\Report_Delivery_Report_$timestamp.html"

# ----------------- Python Check -----------------
$pythonPath = "D:\CC_Python\python.exe"
$existsPython = Test-Path $pythonPath
$results += [PSCustomObject]@{
    'Check'  = "Python Check"
    'Value'  = if ($existsPython) { "Found at $pythonPath" } else { "Not found" }
    'Status' = if ($existsPython) { "PASSED" } else { "FAILED" }
}

# ----------------- BCP Installation -----------------
try {
    $bcpPath = Get-Command "bcp" -ErrorAction Stop
    $bcpVersion = & "$($bcpPath.Source)" -v
    $bcpVersionClean = ($bcpVersion | Select-String 'BCP') -join " "
    $results += [PSCustomObject]@{
        'Check'  = "BCP Installation"
        'Value'  = $bcpVersionClean
        'Status' = "PASSED"
    }
} catch {
    $results += [PSCustomObject]@{
        'Check'  = "BCP Installation"
        'Value'  = "BCP not installed"
        'Status' = "FAILED"
    }
}

# ----------------- Platform Version -----------------
$pathPlatform = "D:\PlatformCode\appsys30.dsl"
$patternPlatform = 'Application Release\s+([\d\.]+)'

try {
    $platformVersion = Select-String -Path $pathPlatform -Pattern 'Application Release' | ForEach-Object {
        if ($_ -match $patternPlatform) { $matches[1] }
    }
    $results += [PSCustomObject]@{
        'Check'  = "Platform Version"
        'Value'  = if ($platformVersion) { $platformVersion } else { "Not found" }
        'Status' = if ($platformVersion) { "PASSED" } else { "FAILED" }
    }
} catch {
    $results += [PSCustomObject]@{
        'Check'  = "Platform Version"
        'Value'  = "Error reading file"
        'Status' = "FAILED"
    }
}

# ----------------- ODBC DSN Check -----------------
$DBBCDrive = Get-OdbcDriver
$ODBCDSNList = Get-OdbcDsn
$ExpectedServers = @("CCAPPLIST1", "CCAPPSQLAG1", "CCRPTLIST1", "CCRPTSQLAG1")

$ErrorMessages = @()
if ($DBBCDrive) {
    foreach ($dsn in $ODBCDSNList) {
        $errors = @()
        if ($dsn.DriverName -ne "ODBC Driver 17 for SQL Server") {
            $errors += "DriverName is '$($dsn.DriverName)'"
        }
        if ($dsn.Attribute.MultiSubnetFailover -ne "Yes") {
            $errors += "MultiSubnetFailover is '$($dsn.Attribute.MultiSubnetFailover)'"
        }
        if (-not ($ExpectedServers -contains $dsn.Attribute.Server)) {
            $errors += "Server is '$($dsn.Attribute.Server)'"
        }
        if ($errors.Count -gt 0) {
            $ErrorMessages += "DSN '$($dsn.Name)' failed: $($errors -join ", ")"
        }
    }
}
$results += [PSCustomObject]@{
    Check   = "ODBC Connection Check"
    Value   = if ($ErrorMessages.Count -eq 0) { "ODBC Connections OK" } else { $ErrorMessages -join "`n" }
    Status  = if ($ErrorMessages.Count -eq 0 -and $DBBCDrive) { "PASSED" } else { "FAILED" }
}

# ----------------- ODBC Drivers -----------------
$odbcDrivers = @(
    @{ Name = "ODBC Driver 17 for SQL Server"; Path = "C:\Windows\System32\msodbcsql17.dll" },
    @{ Name = "ODBC Driver 13 for SQL Server"; Path = "C:\Windows\System32\msodbcsql13.dll" },
    @{ Name = "SQL Server Native Client 11.0"; Path = "C:\Windows\System32\sqlncli11.dll" }
)
$MissingDrivers = @()
foreach ($driver in $odbcDrivers) {
    if (-not (Test-Path -PathType Leaf $driver.Path)) {
        $MissingDrivers += "$($driver.Name) missing ($($driver.Path))"
    }
}
$results += [PSCustomObject]@{
    Check   = "ODBC Driver Installation"
    Value   = if ($MissingDrivers.Count -eq 0) { "All drivers installed" } else { $MissingDrivers -join "`n" }
    Status  = if ($MissingDrivers.Count -eq 0) { "PASSED" } else { "FAILED" }
}

# ----------------- osql Files -----------------
$osqlPaths = @(
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\osql.exe",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\osql.rll",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\osql.exe",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\osql.rll"
)
foreach ($path in $osqlPaths) {
    $exists = Test-Path $path
    $results += [PSCustomObject]@{
        'Check'  = "Check osql file"
        'Value'  = if ($exists) { "Found $path" } else { "Missing $path" }
        'Status' = if ($exists) { "PASSED" } else { "FAILED" }
    }
}

# ----------------- Translate.exe -----------------
$translatePath = "D:\PlatformCode\translate.exe"
$existsTrans = Test-Path $translatePath
$results += [PSCustomObject]@{
    'Check'  = "Translate.exe Check"
    'Value'  = if ($existsTrans) { "Found $translatePath" } else { "Not found" }
    'Status' = if ($existsTrans) { "PASSED" } else { "FAILED" }
}

# ----------------- Scheduled Task -----------------
$taskName = "Task_RDWF"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$results += [PSCustomObject]@{
    'Check'  = "Scheduled Task - $taskName"
    'Value'  = if ($task) { "Task exists (User: $($task.Principal.UserId))" } else { "Task not found" }
    'Status' = if ($task) { "PASSED" } else { "FAILED" }
}

# ----------------- AWS Secret + URL Checks -----------------
$envName = $env:USERDOMAIN.ToUpper().Split('-')[-1]
$secretId = "$envName/app-rw-secret"
$secretRaw = Get-SECSecretValue -SecretId $secretId
$secretJson = $secretRaw.SecretString | ConvertFrom-Json
$cred = New-Object PSCredential ($secretJson.username, (ConvertTo-SecureString $secretJson.password -AsPlainText -Force))

[xml]$xmlContent = Get-Content -Path "D:\ReportDelivery\ReportDelivery\WFRunReports.exe.config"

function Test-Url {
    param ([string]$url, [PSCredential]$cred)
    try {
        $response = Invoke-WebRequest -Uri $url -Credential $cred -UseBasicParsing -TimeoutSec 5
        return "PASSED", "HTTP $($response.StatusCode)"
    } catch {
        return "FAILED", "ERROR: $($_.Exception.Message)"
    }
}



# --- appSettings ---
foreach ($item in $xmlContent.configuration.appSettings.add) {
    $val = $item.value
    $results += [PSCustomObject]@{
        'Check'  = "appSettings - $($item.key)"
        'Value'  = $val
        'Status' = "Need To Validate"
    }
}

# --- connectionStrings ---
foreach ($conn in $xmlContent.configuration.connectionStrings.add) {
    $val = $conn.connectionString
    $results += [PSCustomObject]@{
        'Check'  = "connectionStrings - $($conn.name)"
        'Value'  = $val
        'Status' = "Need To Validate"
    }
}

# --- applicationSettings ---
foreach ($section in $xmlContent.configuration.applicationSettings.ChildNodes) {
    foreach ($setting in $section.setting) {
        $val = $setting.SelectSingleNode("value").InnerText

        if ($val -match '^https?://') {
            # Test actual URL
            try {
                $response = Invoke-WebRequest -Uri $val -Credential $cred -UseBasicParsing -TimeoutSec 5
                $status = "PASSED"
                $detail = "HTTP $($response.StatusCode)"
            } catch {
                $status = "FAILED"
                $detail = "ERROR: $($_.Exception.Message)"
            }
        } else {
            # If not a URL, just mark as PASSED (since no test needed)
            $status = "PASSED"
            $detail = ""
        }

        $results += [PSCustomObject]@{
            'Check'  = "applicationSettings - $($setting.name)"
            'Value'  = $val
            'Status' = $status
            'Detail' = $detail
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
    .status-ok { background-color: #d4edda; color: #155724; font-weight: bold; }
    .status-failed { background-color: #f8d7da; color: #721c24; font-weight: bold; }
</style>
"@

$summaryStatus = if ($results.Status -contains 'FAILED') {
    "<h3 style='color: red;'>Some checks FAILED. Please review the details below.</h3>"
} else {
    "<h3 style='color: green;'>All checks PASSED successfully.</h3>"
}

$htmlRows = foreach ($r in $results) {
    $statusClass = if ($r.Status -eq "PASSED") { "status-ok" } else { "status-failed" }
    "<tr><td>$($r.Check)</td><td>$($r.Value)</td><td class='$statusClass'>$($r.Status)</td></tr>"
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
