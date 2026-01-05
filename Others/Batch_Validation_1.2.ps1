######################################################################################################################
# Batch Server Validation | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 |  Batch Server Validation | Date:: 19-July-2025
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

if ($EnvironmentAttribution -eq "cookie") {
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

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$ServerTypeList = @('bat')
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

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$ValidationResults = @()

# ----------- Step 3: Perform remote checks -----------
foreach ($Server in $ServerList) {
    Write-Host "Checking server: $Server" -ForegroundColor Cyan

    $result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
        $output = @{}

        # --- BCP Check ---
        try {
            Get-Command bcp -ErrorAction Stop | Out-Null
            $output.BCP = "Installed"
        } catch {
            $output.BCP = "Not installed"
        }

        # --- Python Check ---
        $pythonPath = "D:\CC_Python\python.exe"
        $output.Python = if (Test-Path $pythonPath) { "Available" } else { "Missing" }

        # --- Platform Version Check ---
        $platformFile = "D:\CC_runtime\appsys30.dsl"
        $pattern = 'Application Release\s+([\d\.]+)'
        if (Test-Path $platformFile) {
            try {
                $match = Select-String -Path $platformFile -Pattern 'Application Release' | ForEach-Object {
                    if ($_ -match $pattern) { $matches[1] }
                }
                $output.PlatformVersion = if ($match) { $match } else { "Not found" }
            } catch {
                $output.PlatformVersion = "Error reading file"
            }
        } else {
            $output.PlatformVersion = "File not found"
        }

        # --- Translate.exe Check ---
        $translatePath = "D:\CC_runtime\translate.exe"
        $output.TranslateExe = if (Test-Path $translatePath) { "Available" } else { "Missing" }

        # --- VisualCron Service Check ---
        $serviceName = "VisualCron"
        $domain = $Env:USERDOMAIN
        $expectedAccount = "$domain\\gmsa-batch-svc$"
        try {
            $svc = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'" -ErrorAction Stop
            $account = $svc.StartName
            if ($account -eq $expectedAccount) {
                $output.VisualCronService = "PASSED"
            } else {
                $output.VisualCronService = "Running under: $account"
            }
        } catch {
            $output.VisualCronService = "Service Not Found"
        }

        # --- GPA (Gpg4win) Installation Check ---
        $allPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $gpaInstalled = $false
        foreach ($path in $allPaths) {
            $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*gpg*" -or $_.DisplayName -like "*Gpg4win*" }
            if ($apps) {
                $output.GPA = ($apps | Select-Object -First 1 -ExpandProperty DisplayVersion)
                $gpaInstalled = $true
                break
            }
        }
        if (-not $gpaInstalled) {
            $output.GPA = "Not Installed"
        }

        # MonitoringScript Folder Check (E:\Packages\MonitoringScript)
$folderPath = "D:\DBBSetup\MonitoringScript"
if (Test-Path $folderPath) {
    $size = (Get-ChildItem $folderPath -Recurse -Force -ErrorAction SilentlyContinue |
             Where-Object { -not $_.PSIsContainer } |
             Measure-Object -Property Length -Sum).Sum
    
    if ($size -gt 0) {
        $sizeGB = [math]::Round($size / 1GB, 2)
        $output.MonitoringScript = "Exists ($sizeGB GB)"
    }
    else {
        $output.MonitoringScript = "Exists (0 GB)"
    }
}
else {
    $output.MonitoringScript = "Not Found"
}
return $output
} -ErrorAction SilentlyContinue

    if (-not $result) {
        $result = @{
            BCP                = "Unreachable"
            Python             = "Unreachable"
            PlatformVersion    = "Unreachable"
            TranslateExe       = "Unreachable"
            VisualCronService  = "Unreachable"
            GPA                = "Unreachable"
            MonitoringScript   = "Unreachable"
        }
    }

    $ValidationResults += [PSCustomObject]@{
        ServerName         = $Server
        BCP                = $result.BCP
        Python             = $result.Python
        PlatformVersion    = $result.PlatformVersion
        TranslateExe       = $result.TranslateExe
        VisualCronService  = $result.VisualCronService
        GPA                = $result.GPA
        MonitoringScript   = $result.MonitoringScript
    }
}

# ----------- Step 4: Generate HTML Report with Inline Coloring ----------- 
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HtmlFile = "C:\Temp\RemoteValidationReport_$timestamp.html"

$style = @"
<style>
    table { border-collapse: collapse; width: 100%; font-family: Arial; }
    th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    .healthy { background-color: #e0ffe0; }   /* green row */
    .unhealthy { background-color: #ffe0e0; } /* red row */
    .warning { background-color: #fff3e0; }   /* orange row */
    .bad { color: red; font-weight: bold; }
    .good { color: green; font-weight: bold; }
    .warn { color: orange; font-weight: bold; }
</style>
"@

# Function to wrap values with color spans
function Format-Cell {
    param($value)

    switch -Regex ($value) {
        'unreachable' { return "<span class='warn'>$value</span>" }
        'not installed|missing|not found|error|service not' { return "<span class='bad'>$value</span>" }
        'installed|available|passed' { return "<span class='good'>$value</span>" }
        default { return $value }
    }
}

# Build HTML table manually so spans are not escaped
$header = @"
<html>
<head>
$style
<title>Batch Server Validation Report</title>
</head>
<body>
<h2>Batch Server Validation Report</h2>
<table>
<tr>
  <th>ServerName</th>
  <th>BCP</th>
  <th>Python</th>
  <th>PlatformVersion</th>
  <th>TranslateExe</th>
  <th>VisualCronService</th>
  <th>GPA</th>
  <th>MonitoringScript</th>
</tr>
"@

$rows = foreach ($row in $ValidationResults) {
    "<tr>" +
    "<td>$($row.ServerName)</td>" +
    "<td>$(Format-Cell $row.BCP)</td>" +
    "<td>$(Format-Cell $row.Python)</td>" +
    "<td>$(Format-Cell $row.PlatformVersion)</td>" +
    "<td>$(Format-Cell $row.TranslateExe)</td>" +
    "<td>$(Format-Cell $row.VisualCronService)</td>" +
    "<td>$(Format-Cell $row.GPA)</td>" +
    "<td>$(Format-Cell $row.MonitoringScript)</td>" +
    "</tr>"
}

$footer = @"
</table>
</body>
</html>
"@

# Write final HTML file
$header + ($rows -join "`n") + $footer | Out-File $HtmlFile -Encoding UTF8

Write-Host "Report saved to $HtmlFile" -ForegroundColor Green
Start-Process $HtmlFile