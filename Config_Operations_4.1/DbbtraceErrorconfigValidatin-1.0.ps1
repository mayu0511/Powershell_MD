######################################################################################################################
# Hash Value Check  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.1 | Updated to handle missing reference files | Date:: 23-July-2025
#=====================================================================================================================

Clear-Host

$ThisServer = (hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
} else {
    Write-Host "? Unknown region from hostname. Exiting..." -ForegroundColor Red
    exit
}

$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

if ($EnvironmentAttribution -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2"
    Write-Host "2. COOKIE - POD3 (POD4)"

    $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
    $PODName = if ($PODNumberSelected -eq "1") { "pod2" } elseif ($PODNumberSelected -eq "2") { "pod4" } else {
        Write-Host "Invalid POD Name. Exiting..." -ForegroundColor Red
        exit
    }
} elseif ($EnvironmentAttribution -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attribution. Exiting..." -ForegroundColor Red
    exit
}

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$ServerTypeList = @('bat', 'svc', 'iss', 'aut', 'src', 'snk', 'tnp', 'awf')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "🔎 Looking for servers with type: $ServerType"
    $discovered = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json)
    $ServerList += $discovered | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { double[1] } } | Sort-Object -Property serial
}

if (-not $ServerList) {
    Write-Host "❌ No servers found for the given criteria. Exiting..." -ForegroundColor Red
    exit
}

$ServerList | Format-Table | Out-Host
$ServerList = $ServerList.Name
Read-Host "✔️ Please verify the server list above and press ENTER to continue..."

# --- HASH COMPARISON SECTION ---
Clear-Host

# Reference file paths
$referenceFile1 = "D:\TraceFiles\CoreIssue\dbbtrace.ini"
$referenceFile2 = "D:\TraceFiles\CoreAuth\dbbtrace.ini"
$referenceFile3 = "D:\TraceFiles\CoreIssue\errorconfig.ini"
$referenceFile4 = "D:\TraceFiles\CoreAuth\errorconfig.ini"

# Validate files
$missingFiles = @()
$refFiles = @($referenceFile1, $referenceFile2, $referenceFile3, $referenceFile4)
foreach ($f in $refFiles) {
    if (-not (Test-Path $f)) {
        Write-Host "❗ Reference file not found: $f" -ForegroundColor Red
        $missingFiles += $f
    }
}

# Hash only if available
$referenceHash1 = if ($missingFiles -contains $referenceFile1) { $null } else { Get-FileHash -Path $referenceFile1 -Algorithm SHA256 }
$referenceHash2 = if ($missingFiles -contains $referenceFile2) { $null } else { Get-FileHash -Path $referenceFile2 -Algorithm SHA256 }
$referenceHash3 = if ($missingFiles -contains $referenceFile3) { $null } else { Get-FileHash -Path $referenceFile3 -Algorithm SHA256 }
$referenceHash4 = if ($missingFiles -contains $referenceFile4) { $null } else { Get-FileHash -Path $referenceFile4 -Algorithm SHA256 }

# Remote file paths
$remoteFilePath1 = "D:\TraceFiles\CoreIssue\dbbtrace.ini"
$remoteFilePath2 = "D:\TraceFiles\CoreAuth\dbbtrace.ini"
$remoteFilePath3 = "D:\TraceFiles\CoreIssue\errorconfig.ini"
$remoteFilePath4 = "D:\TraceFiles\CoreAuth\errorconfig.ini"

$results = @()
$sessionOption = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

Write-Host "`n🔧 Checking and restarting WinRM service if stopped..."

foreach ($server in $ServerList) {
    try {
        Invoke-Command -ComputerName $server -SessionOption $sessionOption -ScriptBlock {
            $svc = Get-Service -Name WinRM -ErrorAction SilentlyContinue
            if ($svc.Status -ne 'Running') {
                Restart-Service -Name WinRM -Force
            }
        } -ErrorAction Stop
        Write-Host "✅ WinRM OK on $server" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to access/restart WinRM on $server $_" -ForegroundColor Red
    }
}

Write-Host "`n🔎 Performing hash comparison on the following servers:`n$($ServerList -join ', ')`n"

foreach ($server in $ServerList) {
    $hashStatus1 = ""; $hashStatus2 = ""; $hashStatus3 = ""; $hashStatus4 = ""

    try {
        $remoteHashes = Invoke-Command -ComputerName $server -SessionOption $sessionOption -ScriptBlock {
            param($p1, $p2, $p3, $p4)
            $check = {
                param($path)
                if (Test-Path $path) {
                    return (Get-FileHash -Path $path -Algorithm SHA256).Hash
                } else {
                    return "NotFound"
                }
            }
            return [PSCustomObject]@{
                H1 = & $check $p1
                H2 = & $check $p2
                H3 = & $check $p3
                H4 = & $check $p4
            }
        } -ArgumentList $remoteFilePath1, $remoteFilePath2, $remoteFilePath3, $remoteFilePath4 -ErrorAction Stop

        $hashStatus1 = if (-not $referenceHash1) { "Reference File Missing" }
                       elseif ($remoteHashes.H1 -eq "NotFound") { "File Not Found" }
                       elseif ($remoteHashes.H1 -eq $referenceHash1.Hash) { "Identical" } else { "Different" }

        $hashStatus2 = if (-not $referenceHash2) { "Reference File Missing" }
                       elseif ($remoteHashes.H2 -eq "NotFound") { "File Not Found" }
                       elseif ($remoteHashes.H2 -eq $referenceHash2.Hash) { "Identical" } else { "Different" }

        $hashStatus3 = if (-not $referenceHash3) { "Reference File Missing" }
                       elseif ($remoteHashes.H3 -eq "NotFound") { "File Not Found" }
                       elseif ($remoteHashes.H3 -eq $referenceHash3.Hash) { "Identical" } else { "Different" }

        $hashStatus4 = if (-not $referenceHash4) { "Reference File Missing" }
                       elseif ($remoteHashes.H4 -eq "NotFound") { "File Not Found" }
                       elseif ($remoteHashes.H4 -eq $referenceHash4.Hash) { "Identical" } else { "Different" }

    } catch {
        $hashStatus1 = $hashStatus2 = $hashStatus3 = $hashStatus4 = "Connection Failed"
    }

    $results += [PSCustomObject]@{
        Server           = $server
        CoreIssue_dbb    = $hashStatus1
        CoreAuth_dbb     = $hashStatus2
        CoreIssue_error  = $hashStatus3
        CoreAuth_error   = $hashStatus4
    }
}

# --- HTML Report ---
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = "C:\temp\DbbTrace_Errorconfig_Validation_Report_$timestamp.html"

$HtmlHeader = @"
<html>
<head>
    <title>DbbTrace and Errorconfig File Validation Report</title>
    <style>
        body { font-family: Arial; padding: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        .ok { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        .warn { color: orange; font-weight: bold; }
    </style>
</head>
<body>
    <h2>DbbTrace and Errorconfig File Validation Report</h2>
    <p>Generated on: $(Get-Date)</p>
    <table>
        <tr>
            <th>Server Name</th>
            <th>CoreIssue\dbbtrace.ini</th>
            <th>CoreAuth\dbbtrace.ini</th>
            <th>CoreIssue\errorconfig.ini</th>
            <th>CoreAuth\errorconfig.ini</th>
        </tr>
"@

$HtmlBody = foreach ($result in $results) {
    $getClass = {
        param($status)
        switch ($status) {
            "Identical" { "ok" }
            "Different" { "fail" }
            "File Not Found" { "fail" }
            "Connection Failed" { "fail" }
            "Reference File Missing" { "warn" }
            default { "fail" }
        }
    }

    "<tr>
        <td>$($result.Server)</td>
        <td class='$(& $getClass $result.CoreIssue_dbb)'>$($result.CoreIssue_dbb)</td>
        <td class='$(& $getClass $result.CoreAuth_dbb)'>$($result.CoreAuth_dbb)</td>
        <td class='$(& $getClass $result.CoreIssue_error)'>$($result.CoreIssue_error)</td>
        <td class='$(& $getClass $result.CoreAuth_error)'>$($result.CoreAuth_error)</td>
    </tr>"
}

$HtmlFooter = @"
    </table>
</body>
</html>
"@

$HtmlHeader + ($HtmlBody -join "`n") + $HtmlFooter | Out-File -FilePath $ReportPath -Encoding UTF8

if (Test-Path $ReportPath) {
    Write-Host "`n✅ HTML report saved to: $ReportPath" -ForegroundColor Cyan
    Start-Process $ReportPath
} else {
    Write-Host "❌ Failed to generate report." -ForegroundColor Red
}
