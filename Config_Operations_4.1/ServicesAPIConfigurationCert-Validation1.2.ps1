######################################################################################################################
# WebServer API Validation Cert Name | Created BY:: Rahul Bajpai
# Version 1.2 | Added POD1 Logic | Enhance By Mahendra 
######################################################################################################################

try {

# ================================
# TLS + CERT BYPASS
# ================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not ("TrustAllCertsPolicy" -as [type])) {
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int problem) {
        return true;
    }
}
"@
}
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


# ================================
# ENV DETECTION
# ================================

$EnvironmentDomain = $env:USERDOMAIN.ToUpper()

$envName = $null
$pod = $null
$isProd = $false

switch ($EnvironmentDomain)
{
    # POD1 Lower Environments
    "CC-POD1-PATUAT" { $envName = "patuat"; $pod = "cc-pod1"; break }
    "CC-POD1-PATQA"  { $envName = "patqa";  $pod = "cc-pod1"; break }
    "CC-POD1-DEV"    { $envName = "dev";    $pod = "cc-pod1"; break }
    "CC-POD1-QA"     { $envName = "qa";     $pod = "cc-pod1"; break }
    "CC-POD1-UAT"    { $envName = "uat";    $pod = "cc-pod1"; break }
    "CC-POD1-PERF"   { $envName = "perf";   $pod = "cc-pod1"; break }

    # POD2 Lower Environments
    "CC-POD2-PATUAT" { $envName = "patuat"; $pod = "cc-pod2"; break }
    "CC-POD2-PATQA"  { $envName = "patqa";  $pod = "cc-pod2"; break }
    "CC-POD2-DEV"    { $envName = "dev";    $pod = "cc-pod2"; break }
    "CC-POD2-QA"     { $envName = "qa";     $pod = "cc-pod2"; break }
    "CC-POD2-UAT"    { $envName = "uat";    $pod = "cc-pod2"; break }
    "CC-POD2-PERF"   { $envName = "perf";   $pod = "cc-pod2"; break }

    # Production Environments
    "CC-POD1-PROD"
    {
        $isProd = $true
        $pod = "cc-pod1"
        break
    }

    "CC-POD2-PROD"
    {
        $isProd = $true
        $pod = "cc-pod2"
        break
    }

    "CC-POD4-PROD"
    {
        $isProd = $true
        $pod = "cc-pod4"
        break
    }

    default
    {
        Write-Output "FAILED - Unknown Environment Domain: $EnvironmentDomain"
        return
    }
}

# Validate
if (-not $envName -and -not $isProd)
{
    Write-Output "FAILED - Unable to determine environment."
    return
}

if (-not $pod)
{
    Write-Output "FAILED - Unable to determine POD for domain: $EnvironmentDomain"
    return
}

# Debug (Optional)
Write-Host "Domain     : $EnvironmentDomain"
Write-Host "Environment: $envName"
Write-Host "POD        : $pod"
Write-Host "Production : $isProd"
# ================================
# BASE URL
# ================================
if ($isProd) {
    $baseUrl = "https://services.api.$pod.infra.marcus.com"
}
else {
    $baseUrl = "https://services.$envName.api.$pod.infra.marcus.com"
}

Write-Host "Base URL   : $baseUrl"

# ================================
# READ WEB.CONFIG
# ================================
$configPath = "D:\WebServer\Services\Web.config"

if (-not (Test-Path $configPath)) {
    Write-Output "FAILED - Web.config not found"
    return
}

[xml]$config = Get-Content $configPath

$locations = $config.configuration.location | Where-Object {
    $_.path -like "CoreCardServices/CoreCardServices.svc/*"
}

if (-not $locations) {
    Write-Output "FAILED - No service paths found"
    return
}

# ================================
# SERVICE VALIDATION (CONTENT CHECK)
# ================================
$serviceResults = @()

foreach ($loc in $locations) {

    $path = $loc.path
    $url = "$baseUrl/$path`?getservletversion=1"

    $status = "NOT WORKING"
    $errorDetail = ""

    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing

        if ($response.StatusCode -ne 200) {
            $errorDetail = "HTTP Status: $($response.StatusCode)"
        }
        else {
            $body = $response.Content

            # ================================
            # CORE VALIDATION RULE
            # ================================
            if (
                $body -match "virtloc" -and
                $body -match "appName" -and
                $body -match "serverIp" -and
                $body -match "serverPort"
            ) {
                $status = "WORKING"
            }
            else {
                $errorDetail = "Response body missing expected fields"
            }
        }

    }
    catch {
        $errorDetail = $_.Exception.Message
    }

    $serviceResults += [PSCustomObject]@{
        Service = $path
        URL     = $url
        Status  = $status
        #Detail  = $errorDetail
    }
}

# ================================
# SUMMARY
# ================================
$total = $serviceResults.Count
$ok = ($serviceResults | Where-Object { $_.Status -eq "WORKING" }).Count
$fail = $total - $ok

$final = if ($fail -eq 0) { "ALL WORKING" } else { "ISSUES FOUND" }

# ================================
# HTML REPORT GENERATION
# ================================
$reportPath = "D:\WebServer\Services\ServiceReport.html"

$style = @"
<style>
body { font-family: Arial; }
h1 { color: #2E86C1; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 8px; }
th { background-color: #2E86C1; color: white; }
.ok { background-color: #d4edda; }
.fail { background-color: #f8d7da; }
</style>
"@

$htmlHeader = @"
<h1>CoreCard Service Validation Report</h1>
<p><b>Environment:</b> $EnvironmentDomain</p>
<p><b>POD:</b> $pod</p>
<p><b>Base URL:</b> $baseUrl</p>
<p><b>Total Services:</b> $total</p>
<p><b>Working:</b> $ok</p>
<p><b>Failed:</b> $fail</p>
<p><b>Final Status:</b> $final</p>
<p><b>Generated:</b> $(Get-Date)</p>
<hr/>
"@

$rows = foreach ($r in $serviceResults) {
    $class = if ($r.Status -eq "WORKING") { "ok" } else { "fail" }
    "<tr class='$class'><td>$($r.Service)</td><td>$($r.URL)</td><td>$($r.Status)</td><td>$($r.Detail)</td></tr>"
}

$htmlTable = @"
<table>
<tr>
<th>Service</th>
<th>URL</th>
<th>Status</th>
</tr>
$($rows -join "`n")
</table>
"@

$html = "<html><head>$style</head><body>$htmlHeader$htmlTable</body></html>"

$html | Out-File $reportPath -Encoding utf8

# Open report automatically
Start-Process $reportPath

Write-Output "Report Generated: $reportPath"

}
catch {
    Write-Output "FAILED - $($_.Exception.Message)"
}
