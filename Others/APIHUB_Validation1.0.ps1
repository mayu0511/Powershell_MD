######################################################################################################################
# APIHUB Servers Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.2 | Date:: 12-Aug-2025
#======================================================================================================================
    Clear-Host

    Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
    } | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
    }

dir D:\ -Recurse | Unblock-File

# ----------------- Setup -----------------
$results = @()
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$htmlFile = "C:\Temp\APIHUBServersValidation$timestamp.html"

# ----------------- Log Folder Check -----------------
$logJsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'
$expectedJsonLine = '"path": "%PROGRAMDATA%/MergeAcrossAPI/MergeAcrossAPI.log"'
$expectedResolvedPath = Join-Path $env:PROGRAMDATA 'MergeAcrossAPI'
$logResult = 'FAILED'

if (Test-Path $logJsonFile) {
    $escapedPattern = [regex]::Escape($expectedJsonLine)
    $matchFound = Select-String -Path $logJsonFile -Pattern $escapedPattern -Quiet
    $folderExists = Test-Path $expectedResolvedPath

    if ($matchFound -and $folderExists) {
        $logResult = 'Available'
    } elseif ($matchFound -and -not $folderExists) {
        $logResult = 'Folder Missing'
    } elseif (-not $matchFound -and $folderExists) {
        $logResult = 'Path Mismatch in JSON'
    }
} else {
    $logResult = 'JSON File Not Found'
}

$results += [PSCustomObject]@{
    Check = 'Log Folder'
    Value = $expectedResolvedPath
    Status = $logResult
}

# ----------------- Cert Folder Check -----------------

$certJsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'
$pattern = '"CertFolder"\s*:\s*"D:/CertFolder"'
$resolvedPath = 'D:\CertFolder'
$certResult = 'FAILED'

if (Test-Path $certJsonFile) {
    $matchFound = Select-String -Path $certJsonFile -Pattern $pattern -Quiet
    $folderExists = Test-Path $resolvedPath

    if ($matchFound -and $folderExists) {
        $certResult = 'Available'
    } elseif ($matchFound -and -not $folderExists) {
        $certResult = 'Folder Missing'
    } elseif (-not $matchFound -and $folderExists) {
        $certResult = 'Path Mismatch in JSON'
    } else {
        $certResult = 'Missing and Mismatch'
    }
} else {
    $certResult = 'JSON File Not Found'
}

$results += [PSCustomObject]@{
    Check = 'Cert Folder'
    Value = $resolvedPath
    Status = $certResult
}

# ----------------- API URLs Validation -------------------

if (-not ("TrustAllCertsPolicy" -as [type])) {
    Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$jsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'
$apiUrl = $null
$apiResult = 'FAILED'

if (Test-Path $jsonFile) {
    $fileContent = Get-Content -Path $jsonFile -Raw -Encoding UTF8

    try {
        $jsonContent = $fileContent | ConvertFrom-Json -ErrorAction Stop
        $apiUrl = $jsonContent.APIURL
    } catch {
        if ($fileContent -match '"APIURL"\s*:\s*"([^"]+)"') {
            $apiUrl = $matches[1]
        }
    }

    if ($apiUrl) {
        $baseUrl = $apiUrl -split '/\{0\}/' | Select-Object -First 1
        try {
            Invoke-WebRequest -Uri $baseUrl -Method GET -UseBasicParsing -ErrorAction Stop
            $apiResult = 'Unexpected Response'
        } catch {
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
                if ($statusCode -eq 401) {
                    $apiResult = 'Able to browse'
                } else {
                    $apiResult = "Unable to browse ($statusCode)"
                }
            } else {
                $apiResult = "Error: $($_.Exception.Message)"
            }
        }
    } else {
        $apiResult = 'APIURL Missing'
    }
} else {
    $apiResult = 'JSON File Not Found'
}

$results += [PSCustomObject]@{
    Check  = 'API URL'
    Value  = $apiUrl
    Status = $apiResult
}


# ----------------- PODs URL Validation -----------------

$fileContent = Get-Content -Path $jsonFile -Raw -Encoding UTF8
$matches = [regex]::Matches($fileContent, '"(POD\d+)"\s*:\s*"([^"]+)"')

foreach ($match in $matches) {
    $keyName = $match.Groups[1].Value
    $url     = $match.Groups[2].Value

    if ($keyName -in @('POD1', 'POD2', 'POD4')) {
        $status = 'FAILED'
        try {
            $uri = [uri]$url
            $baseUrl = $uri.Scheme + '://' + $uri.Host + '/'
            $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $status = 'Able to access'
            } else {
                $status = "Unable to access ($($response.StatusCode))"
            }
        } catch {
            $status = "Error: $($_.Exception.Message)"
        }

        $results += [PSCustomObject]@{
            Check  = $keyName
            Value  = $url
            Status = $status
        }
    }
}

#----------- AWS Secret Key Validation ------------

$jsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'

try {
    $rawJson = Get-Content -Path $jsonFile -Raw
    $cleanJson = $rawJson -replace '/\*.*?\*/', ''
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
        } else {
            try {
                $secretValue = Get-SECSecretValue -Region $region -SecretId $secretId -ErrorAction Stop
                if ($secretValue.SecretString) {
                    $status = "Able to fetch"
                } else {
                    $status = "Unable to fetch (no value returned)"
                }
            }
            catch {
                $status = "Unable to fetch ($($_.Exception.Message))"
            }
        }

        $results += [PSCustomObject]@{
            Check  = "Secret Key - $key"
            Value  = $secretId
            Status = $status
        }
    }
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
    Write-Output "No relevant IIS sites for this server ($Computername). Exiting."
    exit
}

foreach ($Location in $Locations) {
    try {
        if (Test-Path "IIS:\\Sites\\$Location") {
            $site = Get-Item "IIS:\\Sites\\$Location"
            $appPoolName = $site.ApplicationPool
            $expectedAppPool = $ExpectedAppPools[$Location]

            if ($appPoolName -eq $expectedAppPool) {
                Write-Output "PASSED: Website '$Location' is correctly mapped with application pool '$appPoolName'."
                $status = "PASSED"
            } else {
                Write-Output "FAILED: Website '$Location' is mapped with application pool '$appPoolName', expected '$expectedAppPool'."
                $status = "FAILED"
                $allPASSED = $false
            }
        } else {
            Write-Output "WARNING: IIS site '$Location' does not exist on this server."
            $status = "WARNING"
            $appPoolName = "<Site Not Found>"
            $allPASSED = $false
        }
    } catch {
        Write-Output "ERROR: $($_.Exception.Message)"
        $status = "ERROR"
        $appPoolName = "<Error>"
        $allPASSED = $false
    }

    $results += [PSCustomObject]@{
        Check  = "AppPool - $Location"
        Value  = $appPoolName
        Status = $status
    }
}

#-----------Site Protocol Validation 

$ConfirmPreference = 'High'

$Locations = @("PODRedirectService")

foreach ($Location in $Locations) {
    $status = ""
    $protocols = ""

    try {
        if (!(Test-Path "IIS:\\Sites\\$Location")) {
            $status = "Site Not Found"
            $protocols = "N/A"
        }
        else {
            $Bindings = Get-WebBinding -Name $Location -ErrorAction SilentlyContinue | Select-Object -ExpandProperty protocol
            if (-not $Bindings) {
                $protocols = "None"
                $status = "Failed: No bindings found"
            }
            else {
                $protocols = ($Bindings | Sort-Object -Unique | ForEach-Object { $_.ToUpper() }) -join "/"

                $hasHttp = $Bindings | Where-Object { $_ -ieq "http" }
                $hasHttps = $Bindings | Where-Object { $_ -ieq "https" }

                if ($hasHttp -and $hasHttps) {
                    $status = "Available"
                }
                elseif ($hasHttp) {
                    $status = "Only HTTP"
                }
                elseif ($hasHttps) {
                    $status = "Only HTTPS"
                }
                else {
                    $status = "Unknown protocols"
                }
            }
        }
    }
    catch {
        $status = "Error: $($_.Exception.Message)"
        $protocols = "N/A"
    }

    $results += [PSCustomObject]@{
        Check  = "Protocols - $Location"
        Value  = $protocols
        Status = $status
    }
}

#--------APIHUB URL Validation -----

$Module = "api-hub"
$ServerType = 'apihub'

# Step 1: Get EC2 Metadata (Region + Instance ID)
try {
    $token = Invoke-RestMethod -Method PUT -Uri http://169.254.169.254/latest/api/token `
        -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }

    $identity = Invoke-RestMethod -Uri http://169.254.169.254/latest/dynamic/instance-identity/document `
        -Headers @{ "X-aws-ec2-metadata-token" = $token }

    $Region = $identity.region
    $InstanceId = $identity.instanceId
} catch {
    Write-Host "? ERROR: Could not fetch EC2 metadata." -ForegroundColor Red
    exit
}

# Step 3: Describe this instance and extract tags
try {
    $AWSVariables = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        --query "Reservations[*].Instances[*].{
            InstanceId:InstanceId,
            Name:Tags[?Key=='Name']|[0].Value,
            Environment:Tags[?Key=='environment']|[0].Value,
            Stack:Tags[?Key=='stack']|[0].Value,
            Attribution:Tags[?Key=='attribution']|[0].Value,
            Pod:Tags[?Key=='pod']|[0].Value,
            Status:State.Name,
            IpAddress:PrivateIpAddress
        }" | ConvertFrom-Json
} catch {
    Write-Host "? ERROR: Failed to describe instance $InstanceId." -ForegroundColor Red
    exit
}

$Instance = $AWSVariables[0][0]

$EnvironmentName = if ($Instance.Environment) { $Instance.Environment.ToUpper() } else { "QA" }
Write-Host "`n?? Detected Environment: $EnvironmentName"

# Map environment to URL
$APIHUBURL = switch ($EnvironmentName) {
    "PATUAT" { "https://apihub.patuat.cc-ss.infra.marcus.com/index.html" }
    "PATQA"  { "https://apihub.patqa.cc-ss.infra.marcus.com/index.html" }
    "PERF"   { "https://apihub.perf.cc-ss.infra.marcus.com/index.html" }
    "QA"     { "https://apihub.qa.cc-ss.infra.marcus.com/index.html" }
    "DEV"    { "https://apihub.dev.cc-ss.infra.marcus.com/index.html" }
    "UAT"    { "https://apihub.uat.cc-ss.infra.marcus.com/index.html" }
    "PROD"   { "https://apihub.prod.cc-ss.infra.marcus.com/index.html" }
    Default  { Write-Error "Unknown environment: $EnvironmentName"; exit }
}

Write-Host "Checking URL: $APIHUBURL"

try {
    $response = Invoke-WebRequest -Uri $APIHUBURL -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        $urlStatus = "PASSED"
        $urlValue = "HTTP 200 OK"
        Write-Output "Able to browse $APIHUBURL"
    }
    else {
        $urlStatus = "Failed"
        $urlValue = "HTTP Status Code: $($response.StatusCode)"
        Write-Output "Unable to browse $APIHUBURL - HTTP Status Code: $($response.StatusCode)"
    }
}
catch {
    $urlStatus = "Failed"
    $urlValue = "Error: $($_.Exception.Message)"
    Write-Output "? Unable to browse $APIHUBURL - Error: $($_.Exception.Message)"
}

$results += [PSCustomObject]@{
    Check  = "APIHUB URL Check"
    Value  = $urlValue
    Status = $urlStatus
}

#---------- IIS Cert Expiration Check--------------

Import-Module WebAdministration

$now = Get-Date
$sites = Get-ChildItem IIS:\Sites

foreach ($site in $sites) {
    $siteName = $site.Name
    $bindings = $site.Bindings.Collection

    foreach ($binding in $bindings) {
        if ($binding.Protocol -eq 'https' -and $binding.CertificateHash) {
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $binding.CertificateHash }

            if ($cert) {
                $expirationDate = $cert.NotAfter
                if ($expirationDate -gt $now) {
                    $status = "PASSED"
                    $value = "Expires: $expirationDate"
                } else {
                    $status = "FAILED"
                    $value = "Expired on: $expirationDate"
                }
            } else {
                $status = "FAILED"
                $value = "Certificate not found"
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

$certFolder = 'D:\CertFolder'
$currentDate = Get-Date

Get-ChildItem -Path $certFolder -Filter *.cer | ForEach-Object {
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($_.FullName)
        $expiryDate = $cert.NotAfter
        $status = if ($expiryDate -gt $currentDate) { "PASSED" } else { "FAILED" }
        $value = "Expires: $expiryDate"

        Write-Output "$($_.Name): $status ($value)"

        # Add to results for HTML report
        $results += [PSCustomObject]@{
            Check  = "Folder Cert Expiry - $($_.Name)"
            Value  = $value
            Status = $status
        }
    }
    catch {
        Write-Output "Error reading cert file $($_.Name): $($_.Exception.Message)"
        $results += [PSCustomObject]@{
            Check  = "Folder Cert Expiry - $($_.Name)"
            Value  = "Error: $($_.Exception.Message)"
            Status = "FAILED"
        }
    }
}
#----------APIHUB Version Check--------------

$DllPath = "D:\ApiHub\PODRedirectService\clrjit.dll"

if (Test-Path $DllPath) {
    $versionInfo = (Get-Item $DllPath).VersionInfo
    $fileVersion = $versionInfo.FileVersion
    Write-Output "File: $DllPath"
    Write-Output "APIHUB Version: $fileVersion"

    $results += [PSCustomObject]@{
        Check  = "APIHUB DLL Version"
        Value  = $fileVersion
        Status = "PASSED"
    }
} else {
    Write-Output "File not found: $DllPath"

    $results += [PSCustomObject]@{
        Check  = "APIHUB DLL Version"
        Value  = "File not found"
        Status = "FAILED"
    }
}

# ---------- AuthURL Validation ----------
$jsonFile = 'D:\ApiHub\PODRedirectService\appsettings.json'

$checkName = "AuthURL"
$value     = "Not Found"
$status    = "Error"

if (Test-Path $jsonFile) {
    $jsonContent = Get-Content -Path $jsonFile -Raw -Encoding UTF8

    if ($jsonContent -match '"AuthUrl"\s*:\s*"([^"]+)"') {
        $authUrl = $matches[1]
        $value = $authUrl

        if ($authUrl -match '^(https?:\/\/[^\/]+)') {
            $baseUrl = $matches[1]
            try {
                $response = Invoke-WebRequest -Uri $baseUrl -Method GET -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
                $status = "PASSED"
            }
            catch {
                $status = if ($_.Exception.Response) {
                    [int]$_.Exception.Response.StatusCode
                } else {
                    "Unreachable"
                }
            }
        } else {
            $status = "Invalid URL"
        }
    } else {
        $value = "AuthUrl Missing"
        $status = "Error"
    }
} else {
    $value = "JSON File Missing"
    $status = "File Missing"
}

$results = $results | Where-Object { $_.Check -ne "AuthURL" }
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
    .status-failed { background-color: #f8d7da; color: #721c24; font-weight: bold; }
</style>
"@

$htmlRows = foreach ($r in $results) {
    $statusClass = if ($r.Status -eq 200 -or $r.Status -eq "PASSED") {
        "status-PASSED"
    } else {
        "status-failed"
    }
    "<tr><td>$($r.Check)</td><td>$($r.Value)</td><td class='$statusClass'>$($r.Status)</td></tr>"
}

$html = @"
<html>
<head><title>APIHUB Servers Validation - $timestamp</title>
$style
</head>
<body>
<h2>APIHUB Servers Validation</h2>
<table>
<tr><th>Check</th><th>Value</th><th>Status</th></tr>
$htmlRows
</table>
</body>
</html>
"@

$html | Out-File -FilePath $htmlFile -Encoding UTF8
Invoke-Item $htmlFile
