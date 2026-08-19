######################################################################################################################
# Services API Configuration and URL Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.1 | Date:: 1-May-2026
#======================================================================================================================

Clear-Host

# SERVER + REGION
# ========================
$ThisServer = (Hostname).ToLower()

$Region = $null
$ShortRegion = $null

switch -Regex ($ThisServer) {
    'e1' { $Region = "us-east-1"; $ShortRegion = 'e1' }
    'w2' { $Region = "us-west-2"; $ShortRegion = 'w2' }
    default {
        Write-Host "Unable to determine region from hostname '$ThisServer'" -ForegroundColor Red
        exit
    }
}

# ========================
# INSTANCE INFO
# ========================
$instanceData = aws ec2 describe-instances `
    --query "Reservations[*].Instances[*].{
        Name:Tags[?Key=='Name']|[0].Value,
        Env:Tags[?Key=='environment']|[0].Value,
        Stack:Tags[?Key=='stack']|[0].Value
    }" `
    --filters "Name=instance-state-name,Values=running" `
              "Name=tag:Name,Values=$ThisServer" `
    --region $Region | ConvertFrom-Json

if (-not $instanceData -or $instanceData.Count -eq 0) {
    Write-Host "No running EC2 instance found matching Name '$ThisServer' in region $Region" -ForegroundColor Red
    exit
}

$instance = $instanceData[0]

if (-not $instance.Env -or -not $instance.Stack) {
    Write-Host "Instance '$ThisServer' is missing required 'environment' or 'stack' tag" -ForegroundColor Red
    exit
}

$TagEnvironmentName = $instance.Env.ToLower()
$EnvironmentStack   = $instance.Stack.ToLower()[0]

# ========================
# GET ALL INSTANCES
# ========================
$allInstances = aws ec2 describe-instances `
    --query "Reservations[*].Instances[*].{
        Name:Tags[?Key=='Name']|[0].Value
    }" `
    --filters "Name=instance-state-name,Values=running" `
    --region $Region | ConvertFrom-Json

$allInstances = $allInstances | ForEach-Object { $_ }

# ========================
# FILTER SERVERS
# ========================
$ServerTypeList = @('web')

$ServerList = $allInstances | Where-Object {
    $name = $_.Name.ToLower()
    ($ServerTypeList | Where-Object { $name -like "*$_$ShortRegion$TagEnvironmentName$EnvironmentStack*" })
} | Select-Object -ExpandProperty Name

if (-not $ServerList) {
    Write-Host "No servers found"
    exit
}

$ServerList | Out-Host

# ========================
# ENVIRONMENT
# ========================

$EnvironmentDomain = $env:USERDOMAIN.ToUpper()

$envName = $null
$pod = $null
$isProd = $false

switch ($EnvironmentDomain) {

    # ================= POD1 =================
    "CC-POD1-PATUAT" { $pod="cc-pod1"; $envName="patuat" }
    "CC-POD1-PATQA"  { $pod="cc-pod1"; $envName="patqa" }
    "CC-POD1-QA"     { $pod="cc-pod1"; $envName="qa" }
    "CC-POD1-DEV"    { $pod="cc-pod1"; $envName="dev" }
    "CC-POD1-UAT"    { $pod="cc-pod1"; $envName="uat" }
    "CC-POD1-PERF"   { $pod="cc-pod1"; $envName="perf" }
    "CC-POD1-PROD"   { $pod="cc-pod1"; $isProd=$true }

    # ================= POD2 =================
    "CC-POD2-PATUAT" { $pod="cc-pod2"; $envName="patuat" }
    "CC-POD2-PATQA"  { $pod="cc-pod2"; $envName="patqa" }
    "CC-POD2-QA"     { $pod="cc-pod2"; $envName="qa" }
    "CC-POD2-DEV"    { $pod="cc-pod2"; $envName="dev" }
    "CC-POD2-UAT"    { $pod="cc-pod2"; $envName="uat" }
    "CC-POD2-PERF"   { $pod="cc-pod2"; $envName="perf" }
    "CC-POD2-PROD"   { $pod="cc-pod2"; $isProd=$true }

    # ================= POD4 =================
    "CC-POD4-PROD"   { $pod="cc-pod4"; $isProd=$true }

    default {
        Write-Host "Unknown Environment Domain: $EnvironmentDomain" -ForegroundColor Red
        exit
    }
}

Write-Host "Domain      : $EnvironmentDomain"
Write-Host "POD         : $pod"
Write-Host "Environment : $envName"
Write-Host "Production  : $isProd"


# ========================
# URLS
# ========================
if ($isProd) {
    $baseUrl  = "https://services.api.$pod.infra.marcus.com"
    $greenUrl = "https://services-green.api.$pod.infra.marcus.com/"
    $blueUrl  = "https://services-blue.api.$pod.infra.marcus.com/"
}
else {
    $baseUrl  = "https://services.$envName.api.$pod.infra.marcus.com"
    $greenUrl = "https://services-green.$envName.api.$pod.infra.marcus.com/"
    $blueUrl  = "https://services-blue.$envName.api.$pod.infra.marcus.com/"
}

# ========================
# ROBUST URL CHECK (RETRY)
# ========================
$scriptBlock = {
    param($url)

    for ($i = 1; $i -le 2; $i++) {
        try {
            $r = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400) {
                return @{ Url = $url; Status = "PASSED" }
            }
        } catch {}

        try {
            $r = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400) {
                return @{ Url = $url; Status = "PASSED" }
            }
        } catch {}

        Start-Sleep -Seconds 2
    }

    return @{ Url = $url; Status = "FAILED" }
}

# ========================
# STABLE STACK DETECTION
# ========================
function Get-StackStatus {
    param($url)

    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $url
    $result = $job | Wait-Job | Receive-Job
    Remove-Job $job

    return $result.Status
}
# ========================
# ACTIVE STACK FROM EC2
# ========================

switch ($EnvironmentStack)
{
    "b" { $activeStack = "BLUE" }
    "g" { $activeStack = "GREEN" }

    default {
        $activeStack = "UNKNOWN"
    }
}

Write-Host "Active Stack (from EC2 tag) : $activeStack"

$greenStatus = Get-StackStatus $greenUrl
$blueStatus  = Get-StackStatus $blueUrl

if ($greenStatus -eq "PASSED" -and $blueStatus -ne "PASSED") {
    $activeStack = "GREEN"
}
elseif ($blueStatus -eq "PASSED" -and $greenStatus -ne "PASSED") {
    $activeStack = "BLUE"
}
elseif ($greenStatus -eq "PASSED" -and $blueStatus -eq "PASSED") {
    $activeStack = "BOTH"
}
else {
    $activeStack = "NONE"
}

Write-Host "Active Stack (detected via URL probe) : $activeStack"

# ========================
# URL SELECTION (SAFE)
# ========================

switch ($activeStack) {
    "GREEN" { $Urls = @($baseUrl, $greenUrl) }
    "BLUE"  { $Urls = @($baseUrl, $blueUrl) }
    default { $Urls = @($baseUrl, $blueUrl, $greenUrl) }
}

# ========================
# EXECUTION
# ========================
$finalResults = @()

foreach ($server in $ServerList) {

    Write-Host "Checking: $server"

    $jobs = foreach ($url in $Urls) {
        Start-Job -ScriptBlock $scriptBlock -ArgumentList $url
    }

    $jobResults = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job

    foreach ($result in $jobResults) {
        $finalResults += [PSCustomObject]@{
            "Server Name" = $server
            "URL"         = $result.Url
            "Status"      = $result.Status
            "Stack Used"  = $activeStack
        }
    }
}

# ========================
# OUTPUT
# ========================
$finalResults | Format-Table -AutoSize

# ========================
# HTML REPORT
# ========================
$ReportDir  = "C:\temp"
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}
$ReportPath = Join-Path $ReportDir "URLStatusReport.html"

$Html = @"
<html>
<head>
<style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 95%; }
th, td { border: 1px solid #ddd; padding: 8px; }
th { background-color: #f2f2f2; }
.PASSED { color: green; font-weight: bold; }
.FAILED { color: red; font-weight: bold; }
</style>
</head>
<body>

<h2>Server URL Status Report</h2>
<h3>Active Stack: $activeStack</h3>

<table>
<tr>
<th>Server Name</th>
<th>URL</th>
<th>Status</th>
<th>Stack</th>
</tr>
"@

foreach ($row in $finalResults) {
    $Html += "<tr>
<td>$($row.'Server Name')</td>
<td>$($row.URL)</td>
<td class='$($row.Status)'>$($row.Status)</td>
<td>$($row.'Stack Used')</td>
</tr>"
}

$Html += "</table></body></html>"

$Html | Out-File $ReportPath -Encoding UTF8
Start-Process $ReportPath