Clear-Host

# Reset non-system variables
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}

# Initialize
$results   = @()
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$htmlFile  = "$env:TEMP\APIHUB-Services-URL-Validation-$timestamp.html"

####################################################################
# STEP 1: GET EC2 METADATA
####################################################################
try {
    $token = Invoke-RestMethod -Method PUT -Uri "http://169.254.169.254/latest/api/token" `
        -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }

    $identity = Invoke-RestMethod -Uri "http://169.254.169.254/latest/dynamic/instance-identity/document" `
        -Headers @{ "X-aws-ec2-metadata-token" = $token }

    $Region     = $identity.region
    $InstanceId = $identity.instanceId
}
catch {
    $results += [PSCustomObject]@{
        Check  = "EC2 Metadata"
        Value  = "Metadata fetch failed"
        Status = "FAILED"
    }
    goto REPORT
}

####################################################################
# STEP 2: GET INSTANCE TAGS
####################################################################
try {
    $AWSVariables = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        --query "Reservations[*].Instances[*].{
            Environment:Tags[?Key=='environment']|[0].Value
        }" | ConvertFrom-Json
}
catch {
    $results += [PSCustomObject]@{
        Check  = "AWS Describe Instance"
        Value  = "AWS CLI error"
        Status = "FAILED"
    }
    goto REPORT
}

$Instance  = $AWSVariables[0][0]
$ApiHubEnv = if ($Instance.Environment) { $Instance.Environment.ToUpper() } else { "QA" }

####################################################################
# STEP 3: MAP APIHUB URL
####################################################################
$APIHUBURL = switch ($ApiHubEnv) {
    "PATUAT" { "https://apihub.patuat.cc-ss.infra.marcus.com/index.html" }
    "PATQA"  { "https://apihub.patqa.cc-ss.infra.marcus.com/index.html" }
    "PERF"   { "https://apihub.perf.cc-ss.infra.marcus.com/index.html" }
    "QA"     { "https://apihub.qa.cc-ss.infra.marcus.com/index.html" }
    "DEV"    { "https://apihub.dev.cc-ss.infra.marcus.com/index.html" }
    "UAT"    { "https://apihub.uat.cc-ss.infra.marcus.com/index.html" }
    "PROD"   { "https://apihub.cc-ss.infra.marcus.com/index.html" }
    default  { $null }
}

####################################################################
# STEP 4: MAP SERVICES URL (DOMAIN BASED)
####################################################################
$ServicesDomain = $env:USERDNSDOMAIN.ToUpper()

$ServicesURL = if ($ServicesDomain -match 'PATUAT') {
    "https://services.patuat.api.cc-pod2.infra.marcus.com/"
}
elseif ($ServicesDomain -match 'PATQA') {
    "https://services.patqa.api.cc-pod2.infra.marcus.com/"
}
elseif ($ServicesDomain -match 'PERF') {
    "https://services.perf.api.cc-pod2.infra.marcus.com/"
}
elseif ($ServicesDomain -match '\bQA\b') {
    "https://services.qa.api.cc-pod2.infra.marcus.com/"
}
elseif ($ServicesDomain -match 'DEV') {
    "https://services.dev.api.cc-pod2.infra.marcus.com/"
}
elseif ($ServicesDomain -match 'UAT') {
    "https://services.uat.api.cc-pod2.infra.marcus.com/"
}
elseif ($ServicesDomain -match 'PROD') {
    "https://services.prod.api.cc-pod2.infra.marcus.com/"
}
else {
    $null
}

####################################################################
# STEP 5: TEST APIHUB URL
####################################################################
if ($APIHUBURL) {
    try {
        $response  = Invoke-WebRequest -Uri $APIHUBURL -UseBasicParsing -TimeoutSec 10
        $apiStatus = if ($response.StatusCode -eq 200) { "PASSED" } else { "FAILED" }
    }
    catch {
        $apiStatus = "FAILED"
    }
}
else {
    $apiStatus = "FAILED"
}

$results += [PSCustomObject]@{
    Check  = "APIHUB URL Check"
    Value  = if ($APIHUBURL) { $APIHUBURL } else { "URL not resolved" }
    Status = $apiStatus
}

####################################################################
# STEP 6: TEST SERVICES URL
####################################################################
if ($ServicesURL) {
    try {
        $response   = Invoke-WebRequest -Uri $ServicesURL -UseBasicParsing -TimeoutSec 10
        $svcStatus  = if ($response.StatusCode -eq 200) { "PASSED" } else { "FAILED" }
    }
    catch {
        $svcStatus = "FAILED"
    }
}
else {
    $svcStatus = "FAILED"
}

$results += [PSCustomObject]@{
    Check  = "Services URL Check"
    Value  = if ($ServicesURL) { $ServicesURL } else { "URL not resolved" }
    Status = $svcStatus
}

####################################################################
# REPORT
####################################################################


$style = @"
<style>
body { font-family: Segoe UI, sans-serif; background-color: #f4f4f4; padding: 20px; }
table { border-collapse: collapse; width: 100%; margin-top: 20px; }
th, td { border: 1px solid #999; padding: 8px; }
th { background-color: #333; color: white; }
tr:nth-child(even) { background-color: #f9f9f9; }
.status-PASSED { background-color: #d4edda; color: #155724; font-weight: bold; }
.status-FAILED { background-color: #f8d7da; color: #721c24; font-weight: bold; }
</style>
"@

$htmlRows = foreach ($r in $results) {
    $class = if ($r.Status -eq "PASSED") { "status-PASSED" } else { "status-FAILED" }
    "<tr><td>$($r.Check)</td><td>$($r.Value)</td><td class='$class'>$($r.Status)</td></tr>"
}

$html = @"
<html>
<head>
<title>Services & APIHUB URL Validation - $timestamp</title>
$style
</head>
<body>
<h2>Services & APIHUB URL Validation - $timestamp</h2>
<table>
<tr><th>Check</th><th>Value</th><th>Status</th></tr>
$htmlRows
</table>
</body>
</html>
"@

$html | Out-File -FilePath $htmlFile -Encoding UTF8
Invoke-Item $htmlFile
