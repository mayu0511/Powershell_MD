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

$ServerTypeList = @('src','snk')
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

Write-Log "===================================================="
Write-Log "Scale File Validation Script Started"
Write-Log "Server list file: $ServerListFile"
Write-Log "Scale file path (remote): $ScalePath"
Write-Log "===================================================="

$Results = @()

foreach ($ComputerName in $ServerList) {

    Write-Host "Processing $ComputerName"
    Write-Log "----------------------------------------------------"
    Write-Log "Starting validation for server: $ComputerName"

    try {
        $Option = New-PSSessionOption -ProxyAccessType NoProxyServer
        Write-Log "Creating remote session option (NoProxyServer)"

        $Result = Invoke-Command -ComputerName $ComputerName -SessionOption $Option -ErrorAction Stop -ScriptBlock {

            $ScalePath   = "D:\DBBSetup\ScaleFiles"
            $ServerName  = $env:COMPUTERNAME
            $Environment = $env:USERDNSDOMAIN.ToUpper()

            Write-Output "INFO: Server=$ServerName"
            Write-Output "INFO: Environment=$Environment"
            Write-Output "INFO: ScalePath=$ScalePath"

            # Expected count
            $ExpectedCount = switch -Regex ($Environment) {
                "PATUAT" { 2 }
                "PATQA"  { 2 }
                "QA"     { 2 }
                "DEV"    { 2 }
                "UAT"    { 2 }
                "PERF"   { 31 }
                "PROD"   { 6 }
                default  { 0 }
            }

            Write-Output "INFO: ExpectedCount=$ExpectedCount"

            $FileCount  = 0
            $TotalBytes = 0
            $FileSize   = "0 KB"
            $FileStatus = "Path Not Found"
            $ResultText = "FAIL"
            $RowColor   = "orange"

            if (Test-Path $ScalePath) {

                Write-Output "INFO: Scale path exists"

                $Files = Get-ChildItem -Path $ScalePath -Filter "Scale_MC_*" -File
                $FileCount  = $Files.Count
                $TotalBytes = ($Files | Measure-Object Length -Sum).Sum

                Write-Output "INFO: FileCount=$FileCount"
                Write-Output "INFO: TotalBytes=$TotalBytes"

                if ($FileCount -gt 0) {
                    $FileSize   = "{0:N2} KB" -f ($TotalBytes / 1KB)
                    $FileStatus = "Available"
                    Write-Output "INFO: Files available, FileSize=$FileSize"
                }
                else {
                    $FileStatus = "Not Available"
                    Write-Output "WARN: No Scale_MC_ files found"
                }

                if ($FileCount -eq $ExpectedCount -and
                    $ExpectedCount -gt 0 -and
                    $TotalBytes -gt 0) {

                    $ResultText = "PASS"
                    $RowColor   = ""
                    Write-Output "INFO: Validation PASS"
                }
                else {
                    Write-Output "ERROR: Validation FAIL (count or size mismatch)"
                }
            }
            else {
                Write-Output "ERROR: Scale path not found"
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

        # Capture remote log output
        $Result | ForEach-Object {
            Write-Log "$ComputerName :: $_"
        }

        $Results += $Result | Where-Object { $_.ServerName }
        Write-Log "Completed validation for server: $ComputerName"
    }
    catch {
        Write-Log "ERROR: Unable to connect to server $ComputerName"
        Write-Log $_.Exception.Message

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

Write-Log "----------------------------------------------------"
Write-Log "All servers processed. Generating HTML report."

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
Write-Log "HTML report opened"
Write-Log "Scale File Validation Script Completed"
Write-Log "===================================================="
