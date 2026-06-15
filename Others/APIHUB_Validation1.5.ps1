######################################################################################################################
# APIHUB Servers Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 | Date:: 12-Aug-2025
# Latest Updated by : Netra Chettri | Region Update
# Version 1.5 | Stack logic Update | Netra Chettri | Date:: 8-June-2026
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
$htmlFile = "C:\Temp\APIHUBServersValidation$timestamp.html"

# ==========================================================

# ----------------- Log Folder Check -----------------
$logJsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'
$expectedJsonLine = '"path": "D:/Logs/APIHUB/MergeAcrossAPI.log"'
$expectedResolvedPath = "D:\Logs\APIHUB"
$logResult = 'FAILED'

if (-not $results) { $results = @() }

if (Test-Path $logJsonFile) {
    $escapedPattern = [regex]::Escape($expectedJsonLine)

    $matchFound = Select-String -Path $logJsonFile -Pattern $escapedPattern -Quiet

    $folderExists = Test-Path $expectedResolvedPath

    if ($matchFound -and $folderExists) {
        $logResult = 'PASSED'
    } elseif ($matchFound -and -not $folderExists) {
        $logResult = 'Folder Missing'
    } elseif (-not $matchFound -and $folderExists) {
        $logResult = 'Path Mismatch in JSON'
    } else {
        $logResult = 'JSON Path & Folder Missing'
    }
} else {
    $logResult = 'JSON File Not Found'
}

$results += [PSCustomObject]@{
    Check  = 'Log Folder'
    Value  = $expectedResolvedPath
    Status = $logResult
}



# ----------------- Cert Folder Check -----------------
$certJsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'
$expectedJsonLine = '"CertFolder": "D:/CertFolder"'
$resolvedPath = 'D:\CertFolder'
$certResult = 'FAILED'

if (Test-Path $certJsonFile) {
    # Escape the pattern to avoid regex issues
    $escapedPattern = [regex]::Escape($expectedJsonLine)

    # Check JSON content
    $matchFound = Select-String -Path $certJsonFile -Pattern $escapedPattern -Quiet

    # Check if folder exists
    $folderExists = Test-Path $resolvedPath

    if ($matchFound -and $folderExists) {
        $certResult = 'PASSED'
    } elseif ($matchFound -and -not $folderExists) {
        $certResult = 'Folder Missing'
    } elseif (-not $matchFound -and $folderExists) {
        $certResult = 'Path Mismatch in JSON'
    } else {
        $certResult = 'JSON Path & Folder Missing'
    }
} else {
    $certResult = 'JSON File Not Found'
}

$results += [PSCustomObject]@{
    Check  = 'Cert Folder'
    Value  = $resolvedPath
    Status = $certResult
}

# ----------------- API URLs Validation -------------------

# Ignore certificate validation errors
if (-not ("TrustAllCertsPolicy" -as [type])) {
    Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint,
        X509Certificate certificate,
        WebRequest request,
        int certificateProblem
    ) {
        return true;
    }
}
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$jsonFile  = 'D:\ApiHub\PODRedirectService\appsettings.json'
$apiUrl    = $null
$apiResult = 'FAILED'

if (Test-Path $jsonFile) {

    $fileContent = Get-Content -Path $jsonFile -Raw -Encoding UTF8

    try {
        $jsonContent = $fileContent | ConvertFrom-Json -ErrorAction Stop
        $apiUrl = $jsonContent.APIURL
    }
    catch {
        if ($fileContent -match '"APIURL"\s*:\s*"([^"]+)"') {
            $apiUrl = $matches[1]
        }
    }

    if ($apiUrl) {

        # Remove placeholder segments if present
        $baseUrl = $apiUrl -replace '/\{0\}.*$', ''

        # Mandatory path check
        $requiredPath = 'accounts/issuerAccountIds'

        if ($baseUrl -notmatch [regex]::Escape($requiredPath)) {
            $apiResult = 'FAILED - API URL is Not Expected'
        }
        else {
            try {
                $response = Invoke-WebRequest -Uri $baseUrl -Method GET -UseBasicParsing -ErrorAction Stop

                if ($response.StatusCode -eq 200) {
                    $apiResult = 'Live (Unexpected 200)'
                }
                else {
                    $apiResult = "Unexpected ($($response.StatusCode))"
                }
            }
            catch {
                if ($_.Exception.Response) {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                    if ($statusCode -eq 401) {
                        $apiResult = 'PASSED'
                    }
                    else {
                        $apiResult = "Unexpected ($statusCode)"
                    }
                }
                else {
                    $apiResult = "Error: $($_.Exception.Message)"
                }
            }
        }

    }
    else {
        $apiResult = 'APIURL Missing'
    }

}
else {
    $apiResult = 'JSON File Not Found'
}

$results += [PSCustomObject]@{
    Check  = 'API URL'
    Value  = $apiUrl
    Status = $apiResult
}



# ----------------- PODs URLs Validation -----------------

if (Test-Path $jsonFile) {
    $fileContent = Get-Content -Path $jsonFile -Raw -Encoding UTF8
    $matches = [regex]::Matches($fileContent, '"(POD\d+)"\s*:\s*"([^"]+)"')

    foreach ($match in $matches) {
        $keyName = $match.Groups[1].Value
        $url     = $match.Groups[2].Value

        if ($keyName -match '^POD[124]$') {
            $status = 'FAILED'
            try {
                $uri = [uri]$url
                $baseUrl = $uri.GetLeftPart([System.UriPartial]::Authority)
                $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop

                if ($response.StatusCode -eq 200) {
                    $status = 'PASSED'
                } else {
                    $status = "UnPASSED ($($response.StatusCode))"
                }
            } catch {
                if ($_.Exception.InnerException -and $_.Exception.InnerException.GetType().Name -eq 'TimeoutException') {
                    $status = 'Error: Request Timed Out'
                } else {
                    $status = "Error: $($_.Exception.Message)"
                }
            }

            $results += [PSCustomObject]@{
                Check  = $keyName
                Value  = $url
                Status = $status
            }
        }
    }
} else {
    $results += [PSCustomObject]@{
        Check  = 'POD URLs'
        Value  = ''
        Status = 'JSON File Not Found'
    }
}


#----------- AWS Secret Key Validation ------------

$jsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'

if (Test-Path $jsonFile) {
    try {
        $rawJson = Get-Content -Path $jsonFile -Raw -Encoding UTF8
        # Remove /* ... */ comments, including multiline
        $cleanJson = $rawJson -replace '(?s)/\*.*?\*/', ''
        $jsonContent = $cleanJson | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $results += [PSCustomObject]@{
            Check  = 'Secret Keys'
            Value  = ''
            Status = "Failed to read JSON: $($_.Exception.Message)"
        }
        $jsonContent = $null
    }
} else {
    $results += [PSCustomObject]@{
        Check  = 'Secret Keys'
        Value  = ''
        Status = 'JSON File Not Found'
    }
    $jsonContent = $null
}

if ($jsonContent) {
    $region = $jsonContent.AWSConfiguration.SecretManagerRegionEndpointName
    $secretKeys = @(
        "APIUserId",
        "APIPassword",
        "AuthorizationUserIdAWSKey",
        "AuthorizationPwdAWSKey"
    )

    foreach ($key in $secretKeys) {
        $secretId = $jsonContent.AWSConfiguration.$key
        if (-not $secretId) {
            $status = "Missing in JSON"
            $secretId = ''
        } else {
            try {
                $secretValue = Get-SECSecretValue -Region $region -SecretId $secretId -ErrorAction Stop
                if ($secretValue.SecretString) {
                    $status = "PASSED"
                } else {
                    $status = "UnPASSED (no value returned)"
                }
            }
            catch {
                $status = "UnPASSED ($($_.Exception.Message))"
            }
        }

        $results += [PSCustomObject]@{
            Check  = "Secret Key - $key"
            Value  = $secretId
            Status = $status
        }
    }
}

# ==========================================================
#   SecretManagerRegionEndpointName Validation
# ==========================================================

# -------- Detect Server Region from Hostname --------
$ThisServer = (hostname).ToLower()
$ShortRegion = "UNKNOWN"

# Define hostname patterns to region mapping
$hostnameRegionMap = @{
    'e1' = 'us-east-1'
    'w2' = 'us-west-2'
}

foreach ($key in $hostnameRegionMap.Keys) {
    if ($ThisServer -match $key) {
        $ShortRegion = $key
        break
    }
}

# -------- Determine Expected Region --------
$expectedRegion = if ($ShortRegion -ne "UNKNOWN") {
    $hostnameRegionMap[$ShortRegion]
} else {
    "UNKNOWN"
}

#Write-Host "Server Hostname: $ThisServer"
#Write-Host "Detected Short Region: $ShortRegion"
#Write-Host "Expected Region: $expectedRegion"

# -------- JSON Validation --------
$jsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'

if (Test-Path $jsonFile) {
    try {
        $rawJson = Get-Content -Path $jsonFile -Raw -Encoding UTF8

        # Remove block comments from JSON (/* ... */)
        $cleanJson = $rawJson -replace '(?s)/\*.*?\*/', ''

        # Parse JSON
        $jsonData = $cleanJson | ConvertFrom-Json -ErrorAction Stop

        # Read region from JSON
        $regionValue = $jsonData.AWSConfiguration.SecretManagerRegionEndpointName

        # -------- Validation Logic --------
        if (-not $regionValue) {
            $status = "FAILED"
            $value  = "Missing in JSON"
        }
        elseif ($expectedRegion -eq "UNKNOWN") {
            # Fallback: if hostname detection failed, just check JSON for known valid regions
            if ($regionValue -in $hostnameRegionMap.Values) {
                $status = "PASSED"
                $value  = $regionValue #+ " (Detected from JSON)"
            }
            else {
                $status = "FAILED"
                $value  = "Unknown server region & invalid JSON value: $regionValue"
            }
        }
        elseif ($regionValue -eq $expectedRegion) {
            $status = "PASSED"
            $value  = $regionValue
        }
        else {
            $status = "FAILED"
            $value  = "Found: $regionValue | Expected: $expectedRegion"
        }
    }
    catch {
        $status = "FAILED"
        $value  = "Error parsing JSON: $($_.Exception.Message)"
    }
}
else {
    $status = "FAILED"
    $value  = "JSON File Not Found"
}

# -------- Push Result to Table --------
$results += [PSCustomObject]@{
    Check  = "SecretManagerRegionEndpointName"
    Value  = $value
    Status = $status
}

#--------- AppPool Validation --------

Import-Module WebAdministration -ErrorAction Stop

$Computername = $env:COMPUTERNAME
$Locations = @("PODRedirectService")
$ExpectedAppPools = @{
    "PODRedirectService" = "APIHUB"
}
$allPASSED = $true

if ($Locations.Count -eq 0) {
    $results += [PSCustomObject]@{
        Check  = "AppPool"
        Value  = ""
        Status = "No relevant IIS sites for this server ($Computername)"
    }
} else {
    foreach ($Location in $Locations) {
        try {
            if (Test-Path "IIS:\Sites\$Location") {
                $site = Get-Item "IIS:\Sites\$Location"
                $appPoolName = $site.ApplicationPool
                $expectedAppPool = $ExpectedAppPools[$Location]

                if ($appPoolName -eq $expectedAppPool) {
                    $status = "PASSED"
                } else {
                    $status = "FAILED (Expected: $expectedAppPool)"
                    $allPASSED = $false
                }
            } else {
                $status = "WARNING (Site Not Found)"
                $appPoolName = ""
                $allPASSED = $false
            }
        } catch {
            $status = "ERROR: $($_.Exception.Message)"
            $appPoolName = ""
            $allPASSED = $false
        }

        $results += [PSCustomObject]@{
            Check  = "AppPool Validate"
            Value  = $appPoolName
            Status = $status
        }
    }
}

#----------- Site Protocol Validation -----------
$ConfirmPreference = 'High'

$Locations = @("PODRedirectService")

foreach ($Location in $Locations) {
    $status = ""
    $protocols = ""

    try {
        if (-not (Test-Path "IIS:\Sites\$Location")) {
            $status = "WARNING: Site Not Found"
            $protocols = "N/A"
        }
        else {
            $Bindings = Get-WebBinding -Name $Location -ErrorAction SilentlyContinue | Select-Object -ExpandProperty protocol
            if (-not $Bindings) {
                $protocols = "None"
                $status = "FAILED: No bindings found"
            }
            else {
                $protocols = ($Bindings | Sort-Object -Unique | ForEach-Object { $_.ToUpper() }) -join "/"

                $hasHttp  = $Bindings | Where-Object { $_ -ieq "http" }
                $hasHttps = $Bindings | Where-Object { $_ -ieq "https" }

                if ($hasHttp -and $hasHttps) {
                    $status = "PASSED"
                }
                elseif ($hasHttp) {
                    $status = "WARNING: Only HTTP"
                }
                elseif ($hasHttps) {
                    $status = "WARNING: Only HTTPS"
                }
                else {
                    $status = "FAILED: Unknown protocols"
                }
            }
        }
    }
    catch {
        $status = "ERROR: $($_.Exception.Message)"
        $protocols = "N/A"
    }

    $results += [PSCustomObject]@{
        Check  = "Site Protocols"
        Value  = $protocols
        Status = $status
    }
}

#--------APIHUB URL Validation -----

$Module = "api-hub"
$ServerType = 'apihub'

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
        Check  = "APIHUB URL Check"
        Value  = "Error fetching EC2 metadata"
        Status = "FAILED"
    }
    return
}

# Step 2: Get instance tags
try {
    $AWSVariables = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        | ConvertFrom-Json
}
catch {
    $results += [PSCustomObject]@{
        Check  = "APIHUB URL Check"
        Value  = "Error describing instance: $($_.Exception.Message)"
        Status = "FAILED"
    }
    return
}

$Tags = $AWSVariables.Reservations[0].Instances[0].Tags

$EnvironmentName = ($Tags | Where-Object { $_.Key -ieq 'Environment' } | Select-Object -First 1).Value
$Stack           = ($Tags | Where-Object { $_.Key -ieq 'Stack' } | Select-Object -First 1).Value

$EnvironmentName = if ($EnvironmentName) {
    $EnvironmentName.ToUpper().Trim()
} else {
    "QA"
}

$Stack = if ($Stack) {
    $Stack.ToLower().Trim()
} else {
    ""
}

# Debug (remove after validation)
Write-Host "EnvironmentName = [$EnvironmentName]"
Write-Host "Stack = [$Stack]"

# Step 3: Map to URL based on Stack

if ($Stack -eq "blue") {

    $APIHUBURL = switch ($EnvironmentName) {
        "PATUAT" { "https://apihub.patuat-blue-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "PATQA"  { "https://apihub.patqa-blue-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "PERF"   { "https://apihub.perf-blue-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "QA"     { "https://apihub.qa-blue-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "DEV"    { "https://apihub.dev-blue-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "UAT"    { "https://apihub.uat-blue-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "PROD"   { "https://apihub.cc-ss.infra.marcus.com/index.html" }
        default  { $null }
    }

}
elseif ($Stack -eq "green") {

    $APIHUBURL = switch ($EnvironmentName) {
        "PATUAT" { "https://apihub.patuat-green-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "PATQA"  { "https://apihub.patqa-green-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "PERF"   { "https://apihub.perf-green-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "QA"     { "https://apihub.qa-green-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "DEV"    { "https://apihub.dev-green-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "UAT"    { "https://apihub.uat-green-us-east-1.cc-ss.infra.marcus.com/index.html" }
        "PROD"   { "https://apihub.cc-ss.infra.marcus.com/index.html" }
        default  { $null }
    }

}
else {

    # Existing Logic
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

}

if (-not $APIHUBURL) {
    $results += [PSCustomObject]@{
        Check  = "APIHUB URL Check"
        Value  = "Unknown environment: $EnvironmentName"
        Status = "FAILED"
    }
    return
}

# Step 4: Check the URL
try {
    $response = Invoke-WebRequest -Uri $APIHUBURL -UseBasicParsing -TimeoutSec 120
    if ($response.StatusCode -eq 200) {
        $urlStatus = "PASSED"
        $urlValue = "HTTP 200 OK"
    }
    else {
        $urlStatus = "FAILED"
        $urlValue = "HTTP Status Code: $($response.StatusCode)"
    }
} catch {
    $urlStatus = "FAILED"
    $urlValue = "Error: $($_.Exception.Message)"
}

# Step 5: Append to results
$results += [PSCustomObject]@{
    Check  = "APIHUB URL Check"
    Value  = $urlValue
    Status = $urlStatus
}


#---------- IIS Cert Expiration Check--------------

Import-Module WebAdministration

$now = Get-Date
$warningDays = 30   # Days before expiry to show warning
$sites = Get-ChildItem IIS:\Sites

foreach ($site in $sites) {
    $siteName = $site.Name
    $bindings = $site.Bindings.Collection

    foreach ($binding in $bindings) {
        if ($binding.Protocol -eq 'https') {
            if (-not $binding.CertificateHash) {
                # No cert assigned
                $results += [PSCustomObject]@{
                    Check  = "Cert Expiry - $siteName ($($binding.BindingInformation))"
                    Value  = "No certificate assigned"
                    Status = "FAILED"
                }
                continue
            }

            # Normalize thumbprint and find certificate
            $bindingThumb = ($binding.CertificateHash).Replace(" ", "")
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $bindingThumb }

            if ($cert) {
                $expirationDate = $cert.NotAfter
                $expDateStr = $expirationDate.ToString('yyyy-MM-dd HH:mm:ss')

                if ($expirationDate -le $now) {
                    $status = "FAILED"
                    $value  = "Expired on: $expDateStr"
                }
                elseif ($expirationDate -le $now.AddDays($warningDays)) {
                    $status = "WARNING"
                    $value  = "Expires soon: $expDateStr"
                }
                else {
                    $status = "PASSED"
                    $value  = "Expires: $expDateStr"
                }
            }
            else {
                $status = "FAILED"
                $value  = "Certificate not found"
            }

            $results += [PSCustomObject]@{
                Check  = "Cert Expiry - $siteName ($($binding.BindingInformation))"
                Value  = $value
                Status = $status
            }
        }
    }
}

#------------ Folder Certificate Expiry Check ---------------

$certFolder   = 'D:\CertFolder'
$currentDate  = Get-Date
$warningDays  = 30   # Show warning if cert expires within this many days

if (Test-Path $certFolder) {
    Get-ChildItem -Path $certFolder -Filter *.cer | ForEach-Object {
        try {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $cert.Import($_.FullName)

            $expiryDate = $cert.NotAfter
            $expDateStr = $expiryDate.ToString('yyyy-MM-dd HH:mm:ss')

            if ($expiryDate -le $currentDate) {
                $status = "FAILED"
                $value  = "Expired on: $expDateStr"
            }
            elseif ($expiryDate -le $currentDate.AddDays($warningDays)) {
                $status = "WARNING"
                $value  = "Expires soon: $expDateStr"
            }
            else {
                $status = "PASSED"
                $value  = "Expires: $expDateStr"
            }

            $results += [PSCustomObject]@{
                Check  = "Folder Cert Expiry - $($_.Name)"
                Value  = $value
                Status = $status
            }
        }
        catch {
            $results += [PSCustomObject]@{
                Check  = "Folder Cert Expiry - $($_.Name)"
                Value  = "Error: $($_.Exception.Message)"
                Status = "FAILED"
            }
        }
    }
}
else {
    $results += [PSCustomObject]@{
        Check  = "Folder Cert Expiry"
        Value  = "Folder not found: $certFolder"
        Status = "FAILED"
    }
}

#---------- APIHUB Version Check --------------

$DllPath = "D:\ApiHub\PODRedirectService\clrjit.dll"

if (Test-Path $DllPath) {
    try {
        $versionInfo = (Get-Item $DllPath).VersionInfo
        $fileVersion = $versionInfo.FileVersion.Split(" ")[0]  # Take only main version number

        $results += [PSCustomObject]@{
            Check  = "APIHUB DLL Version"
            Value  = $fileVersion
            Status = "PASSED"
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Check  = "APIHUB DLL Version"
            Value  = "Error: $($_.Exception.Message)"
            Status = "FAILED"
        }
    }
}
else {
    $results += [PSCustomObject]@{
        Check  = "APIHUB DLL Version"
        Value  = "File not found: $DllPath"
        Status = "FAILED"
    }
}


# ---------- AuthURL Validation ----------

$jsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'

$checkName = "AuthURL"
$value     = "Not Found"
$status    = "Error"

if (Test-Path $jsonFile) {
    try {
        $jsonContent = Get-Content -Path $jsonFile -Raw -Encoding UTF8

        # Match AuthUrl key and capture value
        if ($jsonContent -match '"AuthUrl"\s*:\s*"([^"]+)"') {
            $authUrl = $Matches[1]
            $value   = $authUrl

            # Extract base URL
            if ($authUrl -match '^(https?:\/\/[^\/]+)') {
                $baseUrl = $Matches[1]
                try {
                    Invoke-WebRequest -Uri $baseUrl -Method GET -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop | Out-Null
                    $status = "PASSED"
                }
                catch {
                    $status = if ($_.Exception.Response) {
                        [int]$_.Exception.Response.StatusCode
                    } else {
                        "Unreachable"
                    }
                }
            }
            else {
                $status = "Invalid URL"
            }
        }
        else {
            $value  = "AuthUrl Missing"
            $status = "FAILED"
        }
    }
    catch {
        $value  = "Error reading file"
        $status = "FAILED"
    }
}
else {
    $value  = "JSON File Missing"
    $status = "FAILED"
}

# Remove any existing AuthURL check before adding
$results = $results | Where-Object { $_.Check -ne $checkName }
$results += [PSCustomObject]@{
    Check  = $checkName
    Value  = $value
    Status = $status
}



# ---------- HTML Report ----------

$style = @"
<style>
    body { font-family: Segoe UI, sans-serif; background-color: #f4f4f4; padding: 20px; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #999; padding: 8px; text-align: left; }
    th { background-color: #333; color: white; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .status-PASSED { background-color: #d4edda; color: #155724; font-weight: bold; }
    .status-FAILED { background-color: #f8d7da; color: #721c24; font-weight: bold; }
</style>
"@

$htmlRows = foreach ($r in $results) {
    $statusNormalized = "$($r.Status)".ToUpper()
    $statusClass = if ($statusNormalized -eq "PASSED" -or $statusNormalized -eq "200") {
        "status-PASSED"
    } else {
        "status-FAILED"
    }
    "<tr><td>$($r.Check)</td><td>$($r.Value)</td><td class='$statusClass'>$($r.Status)</td></tr>"
}

$html = @"
<html>
<head><title>APIHUB Servers Validation - $timestamp</title>
$style
</head>
<body>
<h2>APIHUB Servers Validation - $timestamp</h2>
<table>
<tr><th>Check</th><th>Value</th><th>Status</th></tr>
$htmlRows
</table>
</body>
</html>
"@

$html | Out-File -FilePath $htmlFile -Encoding UTF8
Invoke-Item $htmlFile