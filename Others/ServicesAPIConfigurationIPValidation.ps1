############################################################################################################
#Services API Configuration Validation | DEVELOPED BY:: Mahendra Dwivedi
#Version 1.1 API Validation | Updated by Mahendra | 05-May-26
############################################################################################################

Clear-Host

# ========================
# CONFIG
# ========================
$filePath   = "D:\WebServer\Services\Web.config"
$reportPath = "C:\Temp\ServiceValidationReport.html"

$results = @()

# ========================
# TLS BYPASS
# ========================
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ========================
# LOAD IIS MODULE
# ========================
Import-Module WebAdministration -ErrorAction Stop

# ========================
# GET API PATHS (SAFE)
# ========================
$content = Get-Content $filePath -Raw

$apiPaths = @()

foreach ($match in [regex]::Matches($content, '<location\s+path="([^"]+)"')) {

    $path = $match.Groups[1].Value.Trim()

    if ($path -like "*CoreCardServices/CoreCardServices.svc*") {
        $apiPaths += $path
    }
}

$apiPaths = $apiPaths | Sort-Object -Unique

Write-Host "`nVALID API PATHS:" -ForegroundColor Cyan
$apiPaths | ForEach-Object { Write-Host $_ }

if ($apiPaths.Count -eq 0) {
    Write-Host "FAILED - No valid API paths found" -ForegroundColor Red
    exit 1
}

# ========================
# GET IIS TARGETS
# ========================
$targets = @()
$site = Get-Item "IIS:\Sites\Services"

foreach ($binding in $site.Bindings.Collection) {

    $parts = $binding.bindingInformation -split ':'

    $ip       = $parts[0]
    $hostName = $parts[2]

    if ($ip -eq "*") { $ip = "localhost" }
    if (-not $hostName) { $hostName = $ip }

    $targets += [PSCustomObject]@{
        IP       = $ip
        HostName = $hostName
    }
}

if ($targets.Count -eq 0) {
    Write-Host "FAILED - No IIS targets found" -ForegroundColor Red
    exit 1
}

# ========================
# TEST FUNCTION
# ========================
function Test-Url {
    param (
        [string]$ip,
        [string]$hostName,
        [string]$api
    )

    $url = "https://{0}/{1}?getservletversion=1" -f $ip, $api

    try {
        Write-Host "Testing => $url" -ForegroundColor Yellow

        $res = Invoke-WebRequest `
            -Uri $url `
            -Headers @{ Host = $hostName } `
            -UseBasicParsing `
            -TimeoutSec 20 `
            -ErrorAction Stop

        $c = $res.Content

        if ($c -notmatch "virtloc=$api") { return "FAILED - virtloc mismatch" }
        if ($c -notmatch "appName=appServices") { return "FAILED - appName missing" }
        if ($c -notmatch "serverPort=") { return "FAILED - serverPort missing" }

        return "PASSED"
    }
    catch {
        return "FAILED - $($_.Exception.Message)"
    }
}

# ========================
# EXECUTION
# ========================
foreach ($t in $targets) {
    foreach ($api in $apiPaths) {

        if (-not $api) { continue }

        $url = "https://{0}/{1}?getservletversion=1" -f $t.IP, $api

        Write-Host "FINAL URL => $url" -ForegroundColor Cyan

        $status = Test-Url -ip $t.IP -hostName $t.HostName -api $api

        $results += [PSCustomObject]@{
            Server = $t.IP
            URL    = $url
            Status = $status
        }
    }
}

# ========================
# VALIDATE RESULTS
# ========================
if ($results.Count -eq 0) {
    Write-Host "FAILED - No results generated" -ForegroundColor Red
    exit 1
}

# ========================
# HTML REPORT
# ========================
$style = "<style>
table{border-collapse:collapse;width:100%}
th,td{border:1px solid black;padding:6px}
.passed{background:#c6efce}
.failed{background:#ffc7ce}
</style>"

$html = "<html><head>$style</head><body>"
$html += "<h3>Service Validation Report</h3>"
$html += "<table>"
$html += "<tr><th>Server</th><th>URL</th><th>Status</th></tr>"

foreach ($r in $results) {
    $cls = if ($r.Status -eq "PASSED") { "passed" } else { "failed" }

    $html += "<tr class='$cls'>"
    $html += "<td>$($r.Server)</td>"
    $html += "<td><a href='$($r.URL)' target='_blank'>$($r.URL)</a></td>"
    $html += "<td>$($r.Status)</td></tr>"
}

$html += "</table></body></html>"

# ========================
# SAVE + OPEN REPORT
# ========================
if (!(Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

$html | Out-File $reportPath -Encoding utf8
Start-Process $reportPath

# ========================
# FINAL STATUS
# ========================
if ($results.Status -match "FAILED") {
    exit 1
} else {
    exit 0
}