######################################################################################################################
# HashValue Check  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 | Fixed Folder Copy Issue | Date:: 23-April-2025
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
    Write-Host "Unknown region from hostname. Exiting..." -ForegroundColor Red
    exit
}

$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

switch ($EnvironmentAttribution) {
    "cookie" {
        Clear-Host
        Write-Host "1. COOKIE - POD2"
        Write-Host "2. COOKIE - POD3 (POD4)"
        
        $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
        
        $PODName = switch ($PODNumberSelected) {
            "1" { "pod2" }
            "2" { "pod4" }
            default {
                Write-Host "Invalid POD Name. Exiting..." -ForegroundColor Red
                exit
            }
        }
    }
    "jazz" { $PODName = "jazz" }
    default {
        Write-Host "Invalid Environment Attribution. Exiting..." -ForegroundColor Red
        exit
    }
}

$EnvironmentStack = $AWSVariables.Stack.ToLower()[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZone = Read-Host "Type Availability Zone choice ($AvailabilityZones) or * for all zones"

$ServerTypeList = @('bat')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "Looking for servers with type: $ServerType"

    $discovered = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value,AvailabilityZone:Placement.AvailabilityZone}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json

    $ServerList += $discovered
}

if (-not $ServerList) {
    Write-Host "No servers found for the given criteria. Exiting..." -ForegroundColor Red
    exit
}

$ServerList | Format-Table | Out-Host
$ServerList = $ServerList.Name
Read-Host "Please verify the server list above and press ENTER to continue..."

Clear-Host
$referencePath = "D:\DBBSetup\BatchScripts\CoreIssue\SetupCI.bat"
if (-not (Test-Path $referencePath)) {
    Write-Host "Reference file not found: $referencePath" -ForegroundColor Red
    exit
}
$referenceHash = (Get-FileHash $referencePath -Algorithm SHA256).Hash
$results = @()

foreach ($server in $ServerList) {
    try {
        $remoteHash = Invoke-Command -ComputerName $server -SessionOption $option -ScriptBlock {
            $path = "D:\DBBSetup\BatchScripts\CoreIssue\SetupCI.bat"
            if (Test-Path $path) {
                return (Get-FileHash $path -Algorithm SHA256).Hash
            } else {
                return "File Not Found"
            }
        }

        $hashStatus = switch ($remoteHash) {
            "File Not Found" { "File Not Found" }
            $referenceHash { "Identical" }
            default { "Different" }
        }
    } catch {
        $hashStatus = "Connection Failed"
    }

    $results += [PSCustomObject]@{
        Server       = $server
        FileLocation = "D:\DBBSetup\BatchScripts\CoreIssue\SetupCI.bat"
        HashStatus   = $hashStatus
    }
}

if ($results.Count -eq 0) {
    Write-Host "No results found for hash comparison. Exiting..." -ForegroundColor Red
    exit
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = "C:\temp\hash_report_$timestamp.html"

$HtmlHeader = @"
<html>
<head>
    <title>File Hash Comparison Report</title>
    <style>
        body { font-family: Arial; padding: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        .ok { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h2>File Hash Comparison Report</h2>
    <p>Generated on: $(Get-Date)</p>
    <table>
        <tr>
            <th>Server Name</th>
            <th>File Location</th>
            <th>Hash Status</th>
        </tr>
"@

$HtmlBody = foreach ($result in $results) {
    $class = switch ($result.HashStatus) {
        "Identical" { "ok" }
        "Different" { "fail" }
        "File Not Found" { "fail" }
        "Connection Failed" { "fail" }
        default { "" }
    }

    "<tr>
        <td>$($result.Server)</td>
        <td>$($result.FileLocation)</td>
        <td class='$class'>$($result.HashStatus)</td>
    </tr>"
}

$HtmlFooter = @"
    </table>
</body>
</html>
"@

$HtmlHeader + ($HtmlBody -join "`n") + $HtmlFooter | Out-File -FilePath $ReportPath -Encoding UTF8

if (Test-Path $ReportPath) {
    Write-Host "HTML report saved to: $ReportPath" -ForegroundColor Cyan
    Start-Process $ReportPath
} else {
    Write-Host "Failed to generate report." -ForegroundColor Red
}
