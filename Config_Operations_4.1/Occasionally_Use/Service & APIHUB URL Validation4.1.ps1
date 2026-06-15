######################################################################################################################
# Service & APIHUB URL Validation  | DEVELOPED BY:: Rahul Bajpai
# Version 4.0 | TLS Fix + No GOTO | Date:: 04-Dec-2025
# Latest Version 4.1 | TLS Fix + No GOTO | Date:: 10-March-2026
######################################################################################################################

Clear-Host

######################################################################################################################
# TLS Configuration + Ignore Internal SSL Certificates
######################################################################################################################
try {

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (-not ("TrustAllCertsPolicy" -as [type])) {

        Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;

public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint,
        X509Certificate certificate,
        WebRequest request,
        int certificateProblem) {
        return true;
    }
}
"@
    }

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
catch {
    Write-Host "TLS configuration failed: $($_.Exception.Message)"
}

######################################################################################################################
# Reset Variables
######################################################################################################################
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}

######################################################################################################################
# Initialize
######################################################################################################################
$results = @()
$scriptFailed = $false
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$htmlFile = "$env:TEMP\APIHUB-URL-Validation-$timestamp.html"

######################################################################################################################
# Step 1 - Get IMDSv2 Token
######################################################################################################################
try {

    $token = Invoke-RestMethod -Method PUT `
        -Uri "http://169.254.169.254/latest/api/token" `
        -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }

}
catch {

    $results += [PSCustomObject]@{
        Check="IMDS Token"
        Value="Failed to get token"
        Status="FAILED"
    }

    $scriptFailed = $true
}

######################################################################################################################
# Step 2 - Get Instance ID
######################################################################################################################
if (-not $scriptFailed) {

    try {

        $InstanceId = Invoke-RestMethod `
            -Uri "http://169.254.169.254/latest/meta-data/instance-id" `
            -Headers @{ "X-aws-ec2-metadata-token" = $token }

    }
    catch {

        $results += [PSCustomObject]@{
            Check="Instance ID"
            Value="Failed to retrieve instance id"
            Status="FAILED"
        }

        $scriptFailed = $true
    }
}

######################################################################################################################
# Step 3 - Get Environment Tag
######################################################################################################################
if (-not $scriptFailed) {

    try {

        $EnvironmentName = aws ec2 describe-tags `
            --filters "Name=resource-id,Values=$InstanceId" "Name=key,Values=environment" `
            --query "Tags[0].Value" `
            --output text

        $EnvironmentName = $EnvironmentName.ToUpper()

    }
    catch {

        $results += [PSCustomObject]@{
            Check="Environment Tag"
            Value="Failed to retrieve environment tag"
            Status="FAILED"
        }

        $scriptFailed = $true
    }
}

######################################################################################################################
# Step 4 - Map APIHUB URL
######################################################################################################################
if (-not $scriptFailed) {

    switch ($EnvironmentName) {

        "PATUAT" { $APIHUBURL = "https://apihub.patuat.cc-ss.infra.marcus.com/index.html" }
        "PATQA"  { $APIHUBURL = "https://apihub.patqa.cc-ss.infra.marcus.com/index.html" }
        "PERF"   { $APIHUBURL = "https://apihub.perf.cc-ss.infra.marcus.com/index.html" }
        "QA"     { $APIHUBURL = "https://apihub.qa.cc-ss.infra.marcus.com/index.html" }
        "DEV"    { $APIHUBURL = "https://apihub.dev.cc-ss.infra.marcus.com/index.html" }
        "UAT"    { $APIHUBURL = "https://apihub.uat.cc-ss.infra.marcus.com/index.html" }
        "PROD"   { $APIHUBURL = "https://apihub.cc-ss.infra.marcus.com/index.html" }
        default  { $APIHUBURL = "" }

    }

    if ([string]::IsNullOrWhiteSpace($APIHUBURL)) {

        $results += [PSCustomObject]@{
            Check="APIHUB URL Mapping"
            Value="Unknown Environment: $EnvironmentName"
            Status="FAILED"
        }

        $scriptFailed = $true
    }
}

######################################################################################################################
# Step 5 - Map Services URL
######################################################################################################################
$ServicesURL = $null
$EnvironmentDomain = $env:USERDOMAIN

switch ($EnvironmentDomain) {

    "CC-POD2-PATUAT" { $ServicesURL="https://services.patuat.api.cc-pod2.infra.marcus.com/" }
    "CC-POD2-PATQA"  { $ServicesURL="https://services.patqa.api.cc-pod2.infra.marcus.com/" }
    "CC-POD2-PERF"   { $ServicesURL="https://services.perf.api.cc-pod2.infra.marcus.com/" }
    "CC-POD2-QA"     { $ServicesURL="https://services.qa.api.cc-pod2.infra.marcus.com/" }
    "CC-POD2-DEV"    { $ServicesURL="https://services.dev.api.cc-pod2.infra.marcus.com/" }
    "CC-POD2-UAT"    { $ServicesURL="https://services.uat.api.cc-pod2.infra.marcus.com/" }
    "CC-POD2-PROD"   { $ServicesURL="https://services.api.cc-pod2.infra.marcus.com/" }
    "CC-POD4-PROD"   { $ServicesURL="https://services.api.cc-pod4.infra.marcus.com/" }

}

######################################################################################################################
# Step 6 - Test APIHUB URL
######################################################################################################################
if (-not $scriptFailed) {

    try {

        $response = Invoke-WebRequest `
            -Uri $APIHUBURL `
            -UseBasicParsing `
            -TimeoutSec 30 `
            -ErrorAction Stop

        if ($response.StatusCode -eq 200) {
            $urlStatus="PASSED"
        }
        else {
            $urlStatus="FAILED"
        }

    }
    catch { $urlStatus="FAILED" }

    $results += [PSCustomObject]@{
        Check="APIHUB URL Check"
        Value=$APIHUBURL
        Status=$urlStatus
    }
}

######################################################################################################################
# Step 7 - Test Services URL
######################################################################################################################
if ($ServicesURL) {

    try {

        $response = Invoke-WebRequest `
            -Uri $ServicesURL `
            -UseBasicParsing `
            -TimeoutSec 30 `
            -ErrorAction Stop

        if ($response.StatusCode -eq 200) {
            $urlStatus="PASSED"
        }
        else {
            $urlStatus="FAILED"
        }

    }
    catch { $urlStatus="FAILED" }

    $results += [PSCustomObject]@{
        Check="Services URL Check"
        Value=$ServicesURL
        Status=$urlStatus
    }
}

######################################################################################################################
# HTML REPORT
######################################################################################################################
$style=@"
<style>
body {font-family:Segoe UI;background:#f4f4f4;padding:20px;}
table {border-collapse:collapse;width:100%;}
th,td {border:1px solid #999;padding:8px;}
th {background:#0078D4;color:white;text-align:center;}
tr:nth-child(even){background:#f9f9f9;}
.status-PASSED {background:#d4edda;color:#155724;font-weight:bold;text-align:center;}
.status-FAILED {background:#f8d7da;color:#721c24;font-weight:bold;text-align:center;}
</style>
"@

$htmlRows = foreach ($r in $results) {

$class = if ($r.Status -eq "PASSED") {"status-PASSED"} else {"status-FAILED"}

"<tr>
<td>$($r.Check)</td>
<td>$($r.Value)</td>
<td class='$class'>$($r.Status)</td>
</tr>"
}

$html=@"
<html>
<head>
<title>Service & APIHUB URL Validation - $timestamp</title>
$style
</head>

<body>

<h2 style='text-align:center;'>Service & APIHUB URL Validation - $timestamp</h2>

<table>

<tr>
<th>Check</th>
<th>Value</th>
<th>Status</th>
</tr>

$htmlRows

</table>

</body>
</html>
"@

$html | Out-File -FilePath $htmlFile -Encoding UTF8
Invoke-Item $htmlFile