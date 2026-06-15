######################################################################################################################
# Service & APIHUB URL Validation  | DEVELOPED BY:: Rahul Bajpai
# Version 1.0 | Service & APIHUB URL Validation | Date:: 04-Dec-2025
######################################################################################################################
# Application-Service & APIHUB-URL Servers Validation  
######################################################################################################################

Clear-Host

# Reset non-system variables
Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
} | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
}

# Initialize
$results = @()
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$htmlFile = "$env:TEMP\APIHUB-URL-Validation-$timestamp.html"

#-------- APIHUB URL Validation -----
$Module = "api-hub"
$ServerType = 'apihub'
$Module = "Services API"
$ServerTypes = 'svc','iss','aut','tnp','awf','src','snk','bat'

# Step 1: Get EC2 Metadata
try {
    $token = Invoke-RestMethod -Method PUT -Uri http://169.254.169.254/latest/api/token `
        -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }

    $identity = Invoke-RestMethod -Uri http://169.254.169.254/latest/dynamic/instance-identity/document `
        -Headers @{ "X-aws-ec2-metadata-token" = $token }

    $Region = $identity.region
    $InstanceId = $identity.instanceId
}
catch {
    $results += [PSCustomObject]@{
        Check  = "EC2 Metadata"
        Value  = "Error fetching metadata: $($_.Exception.Message)"
        Status = "FAILED"
    }
    goto REPORT
}

# Step 2: Get Instance Tags
try {
    $AWSVariables = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        --query "Reservations[*].Instances[*].{
            InstanceId:InstanceId,
            Environment:Tags[?Key=='environment']|[0].Value
        }" | ConvertFrom-Json
}
catch {
    $results += [PSCustomObject]@{
        Check  = "AWS Describe Instance"
        Value  = "Error: $($_.Exception.Message)"
        Status = "FAILED"
    }
    goto REPORT
}

$Instance = $AWSVariables[0][0]
$EnvironmentName = if ($Instance.Environment) { $Instance.Environment.ToUpper() } else { "QA" }

# Step 3: Map APIHUB URL
$APIHUBURL = switch ($EnvironmentName) {
    "PATUAT" { "https://apihub.patuat.cc-ss.infra.marcus.com/index.html" }
    "PATQA"  { "https://apihub.patqa.cc-ss.infra.marcus.com/index.html" }
    "PERF"   { "https://apihub.perf.cc-ss.infra.marcus.com/index.html" }
    "QA"     { "https://apihub.qa.cc-ss.infra.marcus.com/index.html" }
    "DEV"    { "https://apihub.dev.cc-ss.infra.marcus.com/index.html" }
    "UAT"    { "https://apihub.uat.cc-ss.infra.marcus.com/index.html" }
    "PROD"   { "https://apihub.cc-ss.infra.marcus.com/index.html" }
    default  { $null }
}

if (-not $APIHUBURL) {
    $results += [PSCustomObject]@{
        Check  = "APIHUB URL Check"
        Value  = "Unknown environment: $EnvironmentName"
        Status = "FAILED"
    }
    goto REPORT
}

# Step 4: Map Services API URL
$EnvironmentName = $env:USERDOMAIN
$ServicesURL = $null

if ($EnvironmentName -eq "CC-POD2-PATUAT") {
    $ServicesURL = "https://services.patuat.api.cc-pod2.infra.marcus.com/"
}
elseif ($EnvironmentName -eq "CC-POD2-PATQA") {
    $ServicesURL = "https://services.patqa.api.cc-pod2.infra.marcus.com/"
}
elseif ($EnvironmentName -eq "CC-POD2-PERF") {
    $ServicesURL = "https://services.perf.api.cc-pod2.infra.marcus.com/"
}
elseif ($EnvironmentName -eq "CC-POD2-QA") {
    $ServicesURL = "https://services.qa.api.cc-pod2.infra.marcus.com/"
}
elseif ($EnvironmentName -eq "CC-POD2-DEV") {
    $ServicesURL = "https://services.dev.api.cc-pod2.infra.marcus.com/"
}
elseif ($EnvironmentName -eq "CC-POD2-UAT") {
    $ServicesURL = "https://services.uat.api.cc-pod2.infra.marcus.com/"
}
elseif ($EnvironmentName -eq "CC-POD2-PROD") {
    $ServicesURL = "https://services.api.cc-pod2.infra.marcus.com/"
}
elseif ($EnvironmentName -eq "CC-POD4-PROD") {
    $ServicesURL = "https://services.api.cc-pod4.infra.marcus.com/"
}
else {
    $ServicesURL = $null
}

if (-not $ServicesURL) {
    $results += [PSCustomObject]@{
        Check  = "Services URL Check"
        Value  = "Unknown environment: $EnvironmentName"
        Status = "FAILED"
    }
    goto REPORT
}

# Step 5: Test APIHUB URL
try {
    $response = Invoke-WebRequest -Uri $APIHUBURL -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        $urlStatus = "PASSED"
        #$urlValue = "HTTP 200 OK"
    }
    else {
        $urlStatus = "FAILED"
        #$urlValue = "HTTP Status Code: $($response.StatusCode)"
    }
}
catch {
    $urlStatus = "FAILED"
    #$urlValue = "Error: $($_.Exception.Message)"
}

# Step 6: Append APIHUB result
$results += [PSCustomObject]@{
    Check  = "APIHUB URL Check"
    Value  = "$APIHUBURL"
    Status = $urlStatus
}
# Step 7: Test Services URL
try {
    $response = Invoke-WebRequest -Uri $ServicesURL -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        $urlStatus = "PASSED"
        #$urlValue = "HTTP 200 OK"
    }
    else {
        $urlStatus = "FAILED"
        #$urlValue = "HTTP Status Code: $($response.StatusCode)"
    }
}
catch {
    $urlStatus = "FAILED"
    #$urlValue = "Error: $($_.Exception.Message)"
}


# Step 8: Append Services result
$results += [PSCustomObject]@{
    Check  = "Services URL Check"
    Value  = "$ServicesURL"
    Status = $urlStatus
}

####################################################################
# HTML REPORT SECTION
####################################################################
$style = @"
<style>
    body {
        font-family: Segoe UI, sans-serif;
        background-color: #f4f4f4;
        padding: 20px;
    }

    table {
        border-collapse: collapse;
        width: 100%;
        margin-top: 20px;
    }

    th, td {
        border: 1px solid #999;
        padding: 8px;
    }

    th {
        background-color: #0078D4;   /* Blue header */
        color: white;
        text-align: center;          /* Center header text */
    }

    td {
        text-align: left;
    }

    tr:nth-child(even) {
        background-color: #f9f9f9;
    }

    .status-PASSED {
        background-color: #d4edda;
        color: #155724;
        font-weight: bold;
        text-align: center;
    }

    .status-FAILED {
        background-color: #f8d7da;
        color: #721c24;
        font-weight: bold;
        text-align: center;
    }
</style>
"@

$htmlRows = foreach ($r in $results) {
    $class = if ($r.Status.ToUpper() -eq "PASSED") { "status-PASSED" } else { "status-FAILED" }
    "<tr>
        <td>$($r.Check)</td>
        <td>$($r.Value)</td>
        <td class='$class'>$($r.Status)</td>
     </tr>"
}

$html = @"
<html>
<head>
<title>Service & APIHUB URL Validation - $timestamp</title>
$style
</head>
<body>
<h2 style="text-align:center;"> Service & APIHUB URL Validation - $timestamp</h2>
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