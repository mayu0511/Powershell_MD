######################################################################################################################
# Scale File Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 |  Stop-Processes | Date:: 15-JAN-2026
#=====================================================================================================================

Clear-Host
$ThisServer = (Hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

<#if ($EnvironmentAttribution -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2"
    Write-Host "2. COOKIE - POD3 (POD4)"
    
    $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
    
    if ($PODNumberSelected -eq "1") {
        $PODName = "pod2"
    } elseif ($PODNumberSelected -eq "2") {
        $PODName = "pod4"
    } else {
        Write-Host "Invalid POD Name. Exiting..."
        exit
    }
} elseif ($EnvironmentAttribution -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attribution. Exiting..."
    exit
}
#>

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$ServerTypeList = @('src' , 'snk')
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { double[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press Enter to continue or Stop the script"

# Remote scale file path
$ScalePath = "D:\DBBSetup\ScaleFiles"

# Local paths
$LogDir    = "C:\temp"
$ReportDir = "C:\temp"
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

$LogFile    = "$LogDir\ScaleFileValidation_$TimeStamp.log"
$ReportFile = "$ReportDir\ScalefileVAldiaitonreprot_$TimeStamp.html"

# Create log directory
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

function Write-Log {
    param ($Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogFile -Value $entry
}

Write-Log "Multi-server scale file validation started"

$Results = @()

foreach ($ComputerName in $ServerList) {

    Write-Host "Connecting to $ComputerName"
    Write-Log "Connecting to $ComputerName"

    try {
        $Option = New-PSSessionOption -ProxyAccessType NoProxyServer

        $Result = Invoke-Command -ComputerName $ComputerName -SessionOption $Option -ErrorAction Stop -ScriptBlock {

            $ScalePath   = "D:\DBBSetup\ScaleFiles"
            $Environment = $env:USERDNSDOMAIN.ToUpper()
            $ServerName  = $env:COMPUTERNAME

            # Expected count by environment
            $ExpectedCount = switch -Regex ($Environment) {
                "PATUAT" { 2 }
                "PATQA"  { 2 }
                "QA" { 2 }
                "DEV"    { 2 }
                "UAT"    { 2 }
                "PERF"   { 13 }
                "PROD"   { 13 }
                default  { 0 }
            }

            $FileCount  = 0
            $TotalBytes = 0
            $FileSize   = "0 KB"
            $FileStatus = "Path Not Found"
            $ResultText = "FAIL"
            $RowColor   = ""   # PASS will stay default

            if (Test-Path $ScalePath) {

                $Files = Get-ChildItem -Path $ScalePath -Filter "Scale_MC_*" -File
                $FileCount  = $Files.Count
                $TotalBytes = ($Files | Measure-Object Length -Sum).Sum

                if ($FileCount -gt 0) {
                    $FileSize   = "{0:N2} KB" -f ($TotalBytes / 1KB)
                    $FileStatus = "Available"
                }
                else {
                    $FileStatus = "Not Available"
                }

                # PASS / FAIL logic
                if ($FileCount -eq $ExpectedCount -and
                    $ExpectedCount -gt 0 -and
                    $TotalBytes -gt 0) {

                    $ResultText = "PASS"
                    $RowColor   = ""   # no color for PASS
                }
                else {
                    $ResultText = "FAIL"
                    $RowColor   = "orange"
                }
            }

            [PSCustomObject]@{
                ServerName   = $ServerName
                FileLocation = $ScalePath
                FileSize     = $FileSize
                FileStatus   = $FileStatus
                Expected     = $ExpectedCount
                Actual       = $FileCount
                Result       = $ResultText
                Color        = $RowColor
            }
        }

        $Results += $Result
        Write-Log "Validation completed for $ComputerName"
    }
    catch {
        Write-Log "Connection failed for $ComputerName"

        $Results += [PSCustomObject]@{
            ServerName   = $ComputerName
            FileLocation = $ScalePath
            FileSize     = "0 KB"
            FileStatus   = "Connection Failed"
            Expected     = "-"
            Actual       = "-"
            Result       = "FAIL"
            Color        = "orange"
        }
    }
}

# Build HTML rows
$Rows = foreach ($R in $Results) {

    if ($R.Color) {
@"
<tr style="background-color:$($R.Color);">
<td>$($R.ServerName)</td>
<td>$($R.FileLocation)</td>
<td>$($R.FileSize)</td>
<td>$($R.FileStatus)</td>
<td>$($R.Expected)</td>
<td>$($R.Actual)</td>
<td><b>$($R.Result)</b></td>
</tr>
"@
    }
    else {
@"
<tr>
<td>$($R.ServerName)</td>
<td>$($R.FileLocation)</td>
<td>$($R.FileSize)</td>
<td>$($R.FileStatus)</td>
<td>$($R.Expected)</td>
<td>$($R.Actual)</td>
<td><b>$($R.Result)</b></td>
</tr>
"@
    }
}

# HTML Report
$HtmlContent = @"
<html>
<head>
<title>Scale File Validation Report</title>
<style>
table { border-collapse: collapse; width: 100%; font-family: Arial; }
th, td { border: 1px solid black; padding: 8px; text-align: left; }
th { background-color: #f2f2f2; }
</style>
</head>
<body>
<h3>Scale File Validation Report</h3>
<table>
<tr>
<th>Server Name</th>
<th>File Location</th>
<th>File Size</th>
<th>File Status</th>
<th>Expected Count</th>
<th>Actual Count</th>
<th>Result</th>
</tr>
$Rows
</table>
</body>
</html>
"@

$HtmlContent | Out-File -FilePath $ReportFile -Encoding UTF8

Write-Log "HTML report generated: $ReportFile"
Invoke-Item $ReportFile
Write-Log "Report opened"
Write-Log "Script execution completed"
