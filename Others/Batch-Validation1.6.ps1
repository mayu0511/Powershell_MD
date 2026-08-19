######################################################################################################################
# Batch Server Validation | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.4 |  Batch Server Validation | Date:: 19-July-2025
#Batch Server Validation | Updated| IPMJsonGenerator Service:: Rahul Bajpai
# Version 1.5 | Batch Server Validation | Date:: 13-April-2026
#Batch Server Validation | Updated| VisualCronsJobsMonitor Service:: Rahul Bajpai
# Version 1.6 | Batch Server Validation | Date:: 17-April-2026
#=====================================================================================================================

Clear-Host
Get-ChildItem D:\ -Recurse | Unblock-File

#------------------- Server & Region ------------------- 
$ThisServer = $env:COMPUTERNAME.ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
}
elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}
else {
    Write-Host "Unable to determine region from hostname. Exiting..." -ForegroundColor Red
    exit
}

#------------------- AWS Instance Details -------------------
$AWSRaw = aws ec2 describe-instances `
--query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value}" `
--filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$ThisServer" `
--region $Region | ConvertFrom-Json

$AWSVariables = $AWSRaw[0][0]

#------------------- Safe Variables -------------------
$EnvironmentName = ([string]$AWSVariables.Environment).ToLower()
$EnvironmentStack = ([string]$AWSVariables.Stack).ToLower()[0]

#------------------- Server Discovery -------------------
$ServerTypeList = @('bat')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {

    $instances = aws ec2 describe-instances `
    --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}" `
    --filters "Name=instance-state-name,Values=running" `
              "Name=tag:Name,Values=*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*" `
    --region $Region | ConvertFrom-Json

    $instances = $instances | ForEach-Object { $_ } | ForEach-Object { $_ }

    $ServerList += $instances | Select-Object @{
        Name = "Name"; Expression = { $_.Name }
    }, @{
        Name = "AvailabilityZone"; Expression = { $_.AvailabilityZone }
    }, @{
        Name = "serial"; Expression = {
            if ($_.Name -match '(\d+)$') { [int]$matches[1] } else { 9999 }
        }
    } | Sort-Object serial, Name
}

$ServerList | Out-Host

if (-not $ServerList -or $ServerList.Count -eq 0) {
    Write-Host "No Server found. Exiting..." -ForegroundColor Red
    exit
}

$ServerList = $ServerList | Where-Object { $_.Name } | Select-Object -ExpandProperty Name

#------------------- SPECIAL SERVERS -------------------
$SpecialPattern = 'b4|b24|g4|g24'

Write-Host "Special Servers (IPM + VC Monitor check): $SpecialPattern" -ForegroundColor Yellow

#Read-Host "Verify server list and press Enter to continue"

#------------------- Remote Validation -------------------
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$ValidationResults = @()

foreach ($Server in $ServerList) {

    Write-Host "Checking server: $Server" -ForegroundColor Cyan

    try {
        $result = Invoke-Command -ComputerName $Server -SessionOption $option -ErrorAction Stop -ScriptBlock {

            param($CurrentServer, $SpecialPattern)

            $output = @{
                BCP = "Unknown"
                Python = "Unknown"
                PlatformVersion = "Unknown"
                TranslateExe = "Unknown"
                VisualCronService = "Unknown"
                GPA = "Unknown"
                MonitoringScript = "Unknown"
                IPMJsonGenerator = "Unknown"
                VisualCronsJobsMonitor = "Unknown"
            }

            $shortName = $CurrentServer.ToLower()

            #------------------- COMMON CHECKS -------------------

            $output.BCP = if (Get-Command bcp -ErrorAction SilentlyContinue) { "Installed" } else { "Not Installed" }

            $output.Python = if (Test-Path "D:\CC_Python\python.exe") { "Available" } else { "Missing" }

            if (Test-Path "D:\CC_runtime\appsys30.dsl") {
                $match = Select-String "D:\CC_runtime\appsys30.dsl" -Pattern 'Application Release\s+([\d\.]+)' | Select-Object -First 1
                $output.PlatformVersion = if ($match) { $match.Matches.Groups[1].Value } else { "Not Found" }
            } else {
                $output.PlatformVersion = "File Missing"
            }

            $output.TranslateExe = if (Test-Path "D:\CC_runtime\translate.exe") { "Available" } else { "Missing" }

            try {
                $svc = Get-WmiObject Win32_Service -Filter "Name='VisualCron'"
                $expected = "$env:USERDOMAIN\gmsa-batch-svc$"
                $output.VisualCronService = if ($svc.StartName -eq $expected) { "Passed" } else { "Wrong Account" }
            } catch {
                $output.VisualCronService = "Service Not Found"
            }

            $output.GPA = if (Test-Path "C:\Program Files (x86)\Gpg4win\bin\gpa.exe") { "Installed" } else { "Not Installed" }

            if (Test-Path "D:\DBBSetup\MonitoringScript") {
                $size = (Get-ChildItem "D:\DBBSetup\MonitoringScript" -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { -not $_.PSIsContainer } |
                        Measure-Object Length -Sum).Sum
                $output.MonitoringScript = "Exists ($([math]::Round($size/1GB,2)) GB)"
            } else {
                $output.MonitoringScript = "Not Found"
            }

            #------------------- SPECIAL SERVER CHECKS -------------------

            if ($shortName -match $SpecialPattern) {

                # IPMJsonGenerator
                $ipmService = Get-Service | Where-Object { $_.Name -like "*IPMJson*" }
                if ($ipmService) {
                    $output.IPMJsonGenerator = if ($ipmService.Status -eq "Running") { "Running" } else { "Stopped" }
                } else {
                    $output.IPMJsonGenerator = "Not Installed"
                }

                # VC Monitor
                $service = Get-Service -Name "VisualCronMonitoringJobService" -ErrorAction SilentlyContinue
                if ($null -eq $service) {
                    $output.VisualCronsJobsMonitor = "Not Installed"
                }
                elseif ($service.Status -eq "Running") {
                    $output.VisualCronsJobsMonitor = "Running"
                }
                else {
                    $output.VisualCronsJobsMonitor = "Stopped"
                }

            } else {
                $output.IPMJsonGenerator = "N/A"
                $output.VisualCronsJobsMonitor = "N/A"
            }

            return $output

        } -ArgumentList $Server, $SpecialPattern
    }
    catch {
        $result = @{
            BCP="Unreachable";Python="Unreachable";PlatformVersion="Unreachable"
            TranslateExe="Unreachable";VisualCronService="Unreachable"
            GPA="Unreachable";MonitoringScript="Unreachable"
            IPMJsonGenerator="Unreachable";VisualCronsJobsMonitor="Unreachable"
        }
    }

    $ValidationResults += [PSCustomObject]@{
        ServerName = $Server
        BCP = $result.BCP
        Python = $result.Python
        PlatformVersion = $result.PlatformVersion
        TranslateExe = $result.TranslateExe
        VisualCronService = $result.VisualCronService
        GPA = $result.GPA
        MonitoringScript = $result.MonitoringScript
        IPMJsonGenerator = $result.IPMJsonGenerator
        VisualCronsJobsMonitor = $result.VisualCronsJobsMonitor
    }
}

#------------------- HTML Report -------------------
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HtmlFile = "C:\Temp\BatchValidation_$timestamp.html"

function Format-Cell($v) {
    if (-not $v) { return "" }
    $val = $v.ToLower()

    if ($val -match "unreachable") { return "<span class='warn'>$v</span>" }
    elseif ($val -match "not|missing|wrong|stopped") { return "<span class='fail'>$v</span>" }
    elseif ($val -match "installed|available|running|passed|exists") { return "<span class='pass'>$v</span>" }
    elseif ($val -match "n/a") { return "<span style='color:gray'>N/A</span>" }
    else { return $v }
}

$html = @"
<html>
<head>
<style>
body { font-family: Arial; background:#f4f6f8; }
table { border-collapse: collapse; width:100%; background:white; }
th { background:#2f5597; color:white; padding:10px; }
td { padding:8px; text-align:center; border-bottom:1px solid #ddd; }
.pass { color:green; font-weight:bold; }
.fail { color:red; font-weight:bold; }
.warn { color:orange; font-weight:bold; }
</style>
</head>
<body>

<h2>Batch Validation Report</h2>
<h3>Special Servers: b4,b24,g4,g24</h3>

<table>
<tr>
<th>Server</th><th>BCP</th><th>Python</th><th>Platform</th>
<th>Translate</th><th>VisualCron</th><th>GPA</th>
<th>Monitoring</th><th>IPM</th><th>VC Monitor</th>
</tr>
"@

foreach ($r in $ValidationResults) {
    $html += "<tr>
    <td>$($r.ServerName)</td>
    <td>$(Format-Cell $r.BCP)</td>
    <td>$(Format-Cell $r.Python)</td>
    <td>$(Format-Cell $r.PlatformVersion)</td>
    <td>$(Format-Cell $r.TranslateExe)</td>
    <td>$(Format-Cell $r.VisualCronService)</td>
    <td>$(Format-Cell $r.GPA)</td>
    <td>$(Format-Cell $r.MonitoringScript)</td>
    <td>$(Format-Cell $r.IPMJsonGenerator)</td>
    <td>$(Format-Cell $r.VisualCronsJobsMonitor)</td>
    </tr>"
}

$html += "</table></body></html>"

$html | Out-File $HtmlFile -Encoding UTF8

Write-Host "Report generated: $HtmlFile" -ForegroundColor Green
Start-Process $HtmlFile
