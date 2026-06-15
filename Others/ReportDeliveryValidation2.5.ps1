######################################################################################################################
# Report Delivery Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 2.3 | Enhanced with separated steps | Date:: 30-Dec-2025
# Version 2.4 | Updated the RDWF Version step:: Netra Chettri | Date:: 12-Feb-2026
# Version 2.5 | Updated the logic if miss-spelled in reportingservice.asmx and ReportExecution2005.asmx :: Netra Chettri | Date:: 1-April-2026
#=============================================================================================================================================

Clear-Host
dir D:\ -Recurse -ErrorAction SilentlyContinue | Unblock-File

# Clean variables
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS'
} | Remove-Variable -Force -ErrorAction SilentlyContinue


$results = @()
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$htmlFile = "C:\Temp\Report_Delivery_Report_$timestamp.html"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Report Delivery Validation - Started" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# ========== STEP 1: Python Check ==========
Write-Host "STEP 1: Python Installation..." -ForegroundColor Yellow
$pythonPath = "D:\CC_Python\python.exe"
if (Test-Path $pythonPath) {
    try {
        $pythonVer = & $pythonPath --version 2>&1
        $results += [PSCustomObject]@{Step="1";Check="Python";Value="$pythonPath - $pythonVer";Status="PASSED"}
        Write-Host "  ? Found: $pythonVer" -ForegroundColor Green
    } catch {
        $results += [PSCustomObject]@{Step="1";Check="Python";Value="Found but version check failed";Status="WARNING"}
        Write-Host "  ? Found but cannot check version" -ForegroundColor Yellow
    }
} else {
    $results += [PSCustomObject]@{Step="1";Check="Python";Value="Not found";Status="FAILED"}
    Write-Host "  ? Not found" -ForegroundColor Red
}

# ========== STEP 2: BCP Check ==========
Write-Host "`nSTEP 2: BCP Installation..." -ForegroundColor Yellow
try {
    $bcpPath = Get-Command "bcp" -ErrorAction Stop
    $bcpVer = (& "$($bcpPath.Source)" -v 2>&1 | Select-String 'BCP') -join " "
    $results += [PSCustomObject]@{Step="2";Check="BCP";Value=$bcpVer;Status="PASSED"}
    Write-Host "  ? Found: $bcpVer" -ForegroundColor Green
} catch {
    $results += [PSCustomObject]@{Step="2";Check="BCP";Value="Not installed";Status="FAILED"}
    Write-Host "  ? Not found" -ForegroundColor Red
}

# ========== STEP 3: RDWF Version ==========
Write-Host "`nSTEP 3: RDWF Version..." -ForegroundColor Yellow
$pathRDWF = "D:\ReportDelivery\ReportDelivery\WFRunReports.exe"

try {
    if (Test-Path $pathRDWF) {
        $productVersion = (Get-Item $pathRDWF).VersionInfo.ProductVersion
        if ($productVersion) {
            $results += [PSCustomObject]@{
                Step   = "3"
                Check  = "RDWF Version"
                Value  = $productVersion
                Status = "PASSED"
            }
            Write-Host "  ? Product Version: $productVersion" -ForegroundColor Green
        }
        else {
            $results += [PSCustomObject]@{
                Step   = "3"
                Check  = "RDWF Version"
                Value  = "Product version not found"
                Status = "FAILED"
            }
            Write-Host "  ? Product version not found" -ForegroundColor Red
        }
    }
    else {
        $results += [PSCustomObject]@{
            Step   = "3"
            Check  = "RDWF Version"
            Value  = "WFRunReports.exe not found"
            Status = "FAILED"
        }
        Write-Host "  ? File not found" -ForegroundColor Red
    }
}
catch {
    $results += [PSCustomObject]@{
        Step   = "3"
        Check  = "RDWF Version"
        Value  = "Error: $($_.Exception.Message)"
        Status = "FAILED"
    }
    Write-Host "  ? Error retrieving version" -ForegroundColor Red
}


# ========== STEP 4: Platform Version ==========
Write-Host "`nSTEP 4: Platform Version..." -ForegroundColor Yellow
$pathPlatform = "D:\PlatformCode\appsys30.dsl"
try {
    if (Test-Path $pathPlatform) {
        $platVer = Select-String -Path $pathPlatform -Pattern 'Application Release\s+([\d\.]+)' | 
                   ForEach-Object { if ($_ -match 'Application Release\s+([\d\.]+)') { $matches[1] } }
        if ($platVer) {
            $results += [PSCustomObject]@{Step="3";Check="Platform Version";Value=$platVer;Status="PASSED"}
            Write-Host "  ? Version: $platVer" -ForegroundColor Green
        } else {
            $results += [PSCustomObject]@{Step="3";Check="Platform Version";Value="Not found in file";Status="FAILED"}
            Write-Host "  ? Version not found" -ForegroundColor Red
        }
    } else {
        $results += [PSCustomObject]@{Step="3";Check="Platform Version";Value="File not found";Status="FAILED"}
        Write-Host "  ? File not found" -ForegroundColor Red
    }
} catch {
    $results += [PSCustomObject]@{Step="3";Check="Platform Version";Value="Error: $($_.Exception.Message)";Status="FAILED"}
    Write-Host "  ? Error" -ForegroundColor Red
}

# ========== STEP 5: ODBC DSN Configuration ==========
Write-Host "`nSTEP 5: ODBC DSN Configuration..." -ForegroundColor Yellow
$ExpectedServers = @("CCAPPLIST1","CCAPPSQLAG1","CCRPTLIST1","CCRPTSQLAG1")
$ODBCDSNList = Get-OdbcDsn
$errors = @()
foreach ($dsn in $ODBCDSNList) {
    $err = @()
    if ($dsn.DriverName -ne "ODBC Driver 17 for SQL Server") { $err += "Driver: $($dsn.DriverName)" }
    if ($dsn.Attribute.MultiSubnetFailover -ne "Yes") { $err += "MultiSubnetFailover: $($dsn.Attribute.MultiSubnetFailover)" }
    if (-not ($ExpectedServers -contains $dsn.Attribute.Server)) { $err += "Server: $($dsn.Attribute.Server)" }
    if ($err) { $errors += "DSN '$($dsn.Name)': $($err -join '; ')" }
}
$results += [PSCustomObject]@{Step="4";Check="ODBC DSN";Value=$(if($errors){"Issues: "+($errors -join "`n")}else{"OK"});Status=$(if($errors){"FAILED"}else{"PASSED"})}
Write-Host "  $(if($errors){'? Issues found'}else{'? OK'})" -ForegroundColor $(if($errors){'Red'}else{'Green'})

# ========== STEP 6: ODBC Drivers ==========
Write-Host "`nSTEP 6: ODBC Driver Files..." -ForegroundColor Yellow
$odbcDrivers = @(
    @{Name="ODBC Driver 17";Path="C:\Windows\System32\msodbcsql17.dll"},
    @{Name="ODBC Driver 13";Path="C:\Windows\System32\msodbcsql13.dll"},
    @{Name="SQL Native Client 11.0";Path="C:\Windows\System32\sqlncli11.dll"}
)
$missing = @()
foreach ($d in $odbcDrivers) {
    if (Test-Path $d.Path) {
        Write-Host "  ? $($d.Name)" -ForegroundColor Green
    } else {
        $missing += $d.Name
        Write-Host "  ? $($d.Name)" -ForegroundColor Red
    }
}
$results += [PSCustomObject]@{Step="5";Check="ODBC Drivers";Value=$(if($missing){"Missing: "+($missing -join ', ')}else{"All installed"});Status=$(if($missing){"FAILED"}else{"PASSED"})}

# ========== STEP 7: OSQL Files ==========
Write-Host "`nSTEP 7: OSQL Files..." -ForegroundColor Yellow
$osqlPaths = @(
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\osql.exe",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\osql.rll",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\osql.exe",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\osql.rll"
)
foreach ($path in $osqlPaths) {
    $exists = Test-Path $path
    $file = Split-Path $path -Leaf
    $results += [PSCustomObject]@{Step="6";Check="OSQL - $file";Value=$(if($exists){$path}else{"Missing"});Status=$(if($exists){"PASSED"}else{"FAILED"})}
    Write-Host "  $(if($exists){'?'}else{'?'}) $file" -ForegroundColor $(if($exists){'Green'}else{'Red'})
}

# ========== STEP 8: Translate.exe ==========
Write-Host "`nSTEP 8: Translate.exe..." -ForegroundColor Yellow
$translatePath = "D:\PlatformCode\translate.exe"
$existsTrans = Test-Path $translatePath
$results += [PSCustomObject]@{Step="7";Check="Translate.exe";Value=$(if($existsTrans){$translatePath}else{"Not found"});Status=$(if($existsTrans){"PASSED"}else{"FAILED"})}
Write-Host "  $(if($existsTrans){'?'}else{'?'}) Translate.exe" -ForegroundColor $(if($existsTrans){'Green'}else{'Red'})

# ========== STEP 9: Scheduled Task ==========
Write-Host "`nSTEP 9: Scheduled Task..." -ForegroundColor Yellow
$taskName = "Task_RDWF"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    $results += [PSCustomObject]@{Step="8";Check="Scheduled Task";Value="User: $($task.Principal.UserId), State: $($task.State)";Status="PASSED"}
    Write-Host "  ? Task found" -ForegroundColor Green
} else {
    $results += [PSCustomObject]@{Step="8";Check="Scheduled Task";Value="Not found";Status="FAILED"}
    Write-Host "  ? Task not found" -ForegroundColor Red
}


# ========== STEP 10: AppSettings ==========
Write-Host "`nSTEP 10: AppSettings Validation..." -ForegroundColor Yellow
$configPath = "D:\ReportDelivery\ReportDelivery\WFRunReports.exe.config"

if (Test-Path $configPath) {
    try {
        [xml]$config = Get-Content $configPath
        $appSettings = @{}
        $config.configuration.appSettings.add | ForEach-Object {
            $appSettings[$_.key] = $_.value
        }

        $computerName = $env:COMPUTERNAME.ToUpper()
        $envOrder = @("PATUAT","PATQA","PERF","UAT","QA","DEV","PROD")
        $envName = $envOrder | Where-Object { $computerName -like "*$_*" } | Select-Object -First 1
        if (-not $envName) { $envName = "UNKNOWN" }

        $kmsPrefixMap = @{
            DEV    = "cckmse1dev"
            QA     = "cckmse1qa"
            UAT    = "cckmse1uat"
            PERF   = "cckmse1perf"
            PATQA  = "cckmse1patqa"
            PATUAT = "cckmse1patuat"
            PROD   = "cckmse1prod"
        }

        $expectedPrefix = $kmsPrefixMap[$envName]

        $pass = 0
        $fail = 0

        foreach ($key in $appSettings.Keys) {
            $val = $appSettings[$key]
            $status = "PASSED"

            if ($key -eq "DFENV_emKMSdefaultMachines") {
                if ($envName -eq "UNKNOWN" -or -not $expectedPrefix) {
                    $status = "FAILED"
                } else {
                    $machines = $val -split '\s+' | Where-Object { $_ }
                    foreach ($m in $machines) {
                        if (-not $m.ToLower().StartsWith($expectedPrefix)) {
                            $status = "FAILED"
                            break
                        }
                    }
                }
            }

            if ($status -eq "PASSED") { $pass++ } else { $fail++ }

            $results += [PSCustomObject]@{
                Step   = "9"
                Check  = "AppSetting-$key"
                Value  = if ($val) { $val } else { "(empty)" }
                Status = $status
            }
        }

        Write-Host "  Environment: $envName" -ForegroundColor Cyan
        Write-Host "  AppSettings: $pass passed, $fail failed" -ForegroundColor `
            $(if ($fail) { "Yellow" } else { "Green" })
    }
    catch {
        $results += [PSCustomObject]@{
            Step   = "9"
            Check  = "AppSettings"
            Value  = "Error: $($_.Exception.Message)"
            Status = "FAILED"
        }
    }
}
else {
    $results += [PSCustomObject]@{
        Step   = "9"
        Check  = "AppSettings"
        Value  = "Config not found"
        Status = "FAILED"
    }
}



# ========== STEP 11: Connection Strings ==========
Write-Host "`nSTEP 11: Connection Strings..." -ForegroundColor Yellow
if (Test-Path $configPath) {
    [xml]$config = Get-Content $configPath
    $connections = $config.configuration.connectionStrings.add
    $expected = @{
        CoreIssue=@{Server="CCrptLIST1";Databases=@("CCGS_RPT_CoreIssue","CCJAZZ_RPT_CoreIssue")}
        CoreIssue_Main=@{Server="CCAPPLIST1";Databases=@("CCGS_CoreIssue","CCJAZZ_CoreIssue")}
        CoreLibrary=@{Server="CCrptLIST1";Databases=@("CCGS_RPT_CoreLibrary")}
        CoreSales=@{Server="CCrptLIST1";Databases=@("CCGS_RPT_CoreIssue","CCJAZZ_RPT_CoreIssue")}
        CoreApp=@{Server="CCrptLIST1";Databases=@("CCGS_RPT_CoreApp","CCJAZZ_RPT_CoreApp")}
        CoreAuth=@{Server="CCrptLIST1";Databases=@("CCGS_RPT_CoreAuth","CCJAZZ_RPT_CoreAuth")}
        CoreCollect=@{Server="CCrptLIST1";Databases=@("CCGS_RPT_CoreCollect")}
    }
    $pass=0;$fail=0
    foreach ($name in $expected.Keys) {
        $conn = $connections | Where-Object {$_.name -eq $name}
        if ($conn) {
            $cs = $conn.connectionString
            $srv = ($cs -split ';' | Where-Object {$_ -like 'server=*'}) -replace 'server=',''
            $db = ($cs -split ';' | Where-Object {$_ -like 'database=*'}) -replace 'database=',''
            $stat = if($srv -eq $expected[$name].Server -and $expected[$name].Databases -contains $db){"PASSED";$pass++}else{"FAILED";$fail++}
            $results += [PSCustomObject]@{Step="10";Check="ConnString-$name";Value="Server=$srv; DB=$db";Status=$stat}
        } else {
            $results += [PSCustomObject]@{Step="10";Check="ConnString-$name";Value="Not found";Status="FAILED"}
            $fail++
        }
    }
    Write-Host "  ConnectionStrings: $pass passed, $fail failed" -ForegroundColor $(if($fail){'Yellow'}else{'Green'})
}

# ========== STEP 12: AWS Secret & URLs ==========
Write-Host "`nSTEP 12: AWS Secret & Report URLs..." -ForegroundColor Yellow
try {
    $envName = $env:USERDOMAIN.ToUpper().Split('-')[-1]
    $secretId = "$envName/app-rw-secret"
    $secretRaw = Get-SECSecretValue -SecretId $secretId
    $secretJson = $secretRaw.SecretString | ConvertFrom-Json
    $cred = New-Object PSCredential ($secretJson.username, (ConvertTo-SecureString $secretJson.password -AsPlainText -Force))
    
    $results += [PSCustomObject]@{
        Step="11";Check="AWS Secret";Value="Retrieved: $secretId";Status="PASSED"
    }
    Write-Host "  ? AWS Secret retrieved" -ForegroundColor Green
    
    if (Test-Path $configPath) {
        [xml]$xml = Get-Content $configPath
        $pass=0;$fail=0

        foreach ($sec in $xml.configuration.applicationSettings.ChildNodes) {
            foreach ($set in $sec.setting) {

                $val = $set.SelectSingleNode("value").InnerText

                if ($val -match '^https?://') {

                    $status = "PASSED"
                    $errorMsg = ""
                    $httpCode = ""

                    # ? STRICT endpoint validation
                    $expectedEndpoints = @(
                        "reportingservice.asmx",
                        "ReportExecution2005.asmx"
                    )

                    $urlLower = $val.ToLower()
                    $isValidEndpoint = $false

                    foreach ($ep in $expectedEndpoints) {
                        if ($urlLower -like "*$ep") {
                            $isValidEndpoint = $true
                            break
                        }
                    }

                    if (-not $isValidEndpoint) {
                        $status = "FAILED"
                        $errorMsg = "Invalid or misspelled endpoint"
                        $httpCode = "SKIPPED"
                    }

                    # ? Only call URL if endpoint is valid
                    if ($status -eq "PASSED") {
                        try {
                            $resp = Invoke-WebRequest -Uri $val -Credential $cred -UseBasicParsing -TimeoutSec 10
                            $httpCode = $resp.StatusCode
                        } catch {
                            $status = "FAILED"
                            $httpCode = "ERROR"
                            $errorMsg = $_.Exception.Message
                        }
                    }

                    # ? Final result logging
                    $results += [PSCustomObject]@{
                        Step   = "11"
                        Check  = "URL-$($set.name)"
                        Value  = if ($errorMsg) { "$val ($httpCode) - $errorMsg" } else { "$val (HTTP $httpCode)" }
                        Status = $status
                    }

                    if ($status -eq "PASSED") { $pass++ } else { $fail++ }
                }
            }
        }

        Write-Host "  URLs: $pass passed, $fail failed" -ForegroundColor $(if($fail){'Yellow'}else{'Green'})
    }
}
catch {
    $results += [PSCustomObject]@{
        Step="11";Check="AWS Secret & URLs";Value="Error: $($_.Exception.Message)";Status="FAILED"
    }
    Write-Host "  ? Failed" -ForegroundColor Red
}

# ========== HTML Report ==========
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Generating HTML Report..." -ForegroundColor Cyan

$style = @"
<style>
body{
    font-family: "Segoe UI", Tahoma, sans-serif;
}
.header{
    background:linear-gradient(135deg,#667eea,#764ba2);
    color:#fff;
    padding:30px;
    border-radius:10px;
    margin-bottom:20px
}
table{
    border-collapse:collapse;
    width:100%;
    background:#fff;
    border-radius:8px;
    overflow:hidden;
    box-shadow:0 2px 4px rgba(0,0,0,0.1)
}
th,td{
    border:1px solid #ddd;
    padding:12px;
    text-align:left
}
th{
    background:#333;
    color:#fff;
    font-weight:600
}
tr:nth-child(even){background:#f9f9f9}
tr:hover{background:#f0f0f0}

.PASSED{color:#155724;font-weight:bold}
.FAILED{color:#721c24;font-weight:bold}
.WARNING{color:#856404;font-weight:bold}

tr.failed-row td{
    background:#f8d7da !important;
    color:#721c24;
    font-weight:bold;
}

.summary{
    padding:20px;
    background:#fff;
    border-radius:8px;
    margin-bottom:20px;
    box-shadow:0 2px 4px rgba(0,0,0,0.1)
}
</style>
"@
$totalChecks = $results.Count
$passed  = ($results | Where-Object { $_.Status -eq "PASSED" }).Count
<!-- $failed  = ($results | Where-Object { $_.Status -eq "FAILED" }).Count -->
$failed = ($results | Where-Object { $_.Status.Trim().ToUpper() -eq "FAILED" }).Count
$warnings = ($results | Where-Object { $_.Status -eq "WARNING" }).Count

$summaryStatus = if ($failed -gt 0) {
    "<div class='summary' style='border-left:5px solid #dc3545'>
        <h3 style='color:#dc3545'>Validation Failed</h3>
        <p>$failed check(s) failed. Please review details below.</p>
     </div>"
} else {
    "<div class='summary' style='border-left:5px solid #28a745'>
        <h3 style='color:#28a745'>All Checks Passed</h3>
        <p>All $totalChecks validation checks completed successfully.</p>
     </div>"
}

$htmlRows = foreach ($r in $results) {

    $rowClass = if ($r.Status -eq "FAILED") { "failed-row" } else { "" }

    "<tr class='$rowClass'>
        <td>$($r.Step)</td>
        <td>$($r.Check)</td>
        <td>$($r.Value)</td>
        <td class='$($r.Status)'>$($r.Status)</td>
     </tr>"
}

$html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Report Delivery Validation - $timestamp</title>
$style
</head>
<body>

<div class='header'>
    <h1>Report Delivery Validation</h1>
    <p>Generated: $timestamp</p>
    <!-- <p>Total Checks: $totalChecks | Passed: $passed | Failed: $failed | Warnings: $warnings</p> -->
	<p>
    Total Checks: <strong>$totalChecks</strong> |
    Passed: <strong>$passed</strong> |
    Failed: <strong>$failed</strong> |
    Warnings: <strong>$warnings</strong>
</p>
</div>

$summaryStatus

<table>
<thead>
<tr>
    <th>Step</th>
    <th>Check</th>
    <th>Value</th>
    <th>Status</th>
</tr>
</thead>
<tbody>
$htmlRows
</tbody>
</table>

</body>
</html>
"@

$html | Out-File -FilePath $htmlFile -Encoding UTF8
Invoke-Item $htmlFile

Write-Host "`nReport saved: $htmlFile" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan