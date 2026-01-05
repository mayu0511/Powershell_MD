######################################################################################################################
# Batch Server Validation | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.4 |  Batch Server Validation | Date:: 19-July-2025
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
# ------------------ Step 3: Perform remote checks -----------
foreach ($Server in $ServerList) {
    Write-Host "Checking server: $Server" -ForegroundColor Cyan

    $result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
        $output = @{}

        #--------------------- BCP Check ------------------------
        try {
            Get-Command bcp -ErrorAction Stop | Out-Null
            $output.BCP = "Installed"
        } catch {
            $output.BCP = "Not installed"
        }

        #---------------------------- Python Check ----------------------
        $pythonPath = "D:\CC_Python\python.exe"
        $output.Python = if (Test-Path $pythonPath) { "Available" } else { "Missing" }

        #-------------------- Platform Version Check ------------------------
        $platformFile = "D:\CC_runtime\appsys30.dsl"
        $pattern = 'Application Release\s+([\d\.]+)'
        if (Test-Path $platformFile) {
            try {
                $match = Select-String -Path $platformFile -Pattern $pattern | Select-Object -First 1
                if ($match -and $match.Matches.Groups.Count -gt 1) {
                    $output.PlatformVersion = $match.Matches.Groups[1].Value
                } else {
                    $output.PlatformVersion = "Not found"
                }
            } catch {
                $output.PlatformVersion = "Error reading file"
            }
        } else {
            $output.PlatformVersion = "File not found"
        }

        #----------------- Translate.exe Check -------------
        $translatePath = "D:\CC_runtime\translate.exe"
        $output.TranslateExe = if (Test-Path $translatePath) { "Available" } else { "Missing" }

        # --- VisualCron Service Check ---
        $serviceName = "VisualCron"
        $domain = $Env:USERDOMAIN
        $expectedAccount = "$domain\gmsa-batch-svc$"
        try {
            $svc = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'" -ErrorAction Stop
            $account = $svc.StartName
            if ($account -eq $expectedAccount) {
                $output.VisualCronService = "PASSED"
            } else {
                $output.VisualCronService = "Wrong Account: $account"
            }
        } catch {
            $output.VisualCronService = "Service Not Found"
        }

        #---------------------- GPA (Gpg4win) Installation Check ---
        $exePath = "C:\Program Files (x86)\Gpg4win\bin\gpa.exe"

        $allPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $registryMatch = $null

        foreach ($path in $allPaths) {
            $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.DisplayName -like "*Gpg4win*" -or $_.DisplayName -like "*GPG*"
                }

            if ($apps) {
                $registryMatch = $apps | Select-Object -First 1
                break
            }
        }

        $exeExists = Test-Path -Path $exePath -PathType Leaf

        # Return plain text - HTML formatting will be done later
        if ($exeExists -and $registryMatch) {
            $output.GPA = "Installed (Version: $($registryMatch.DisplayVersion))"
        }
        elseif (-not $exeExists) {
            $output.GPA = "Not Installed - exe not found"
        }
        elseif (-not $registryMatch) {
            $output.GPA = "Not in Registry"
        }
        else {
            $output.GPA = "Not Installed"
        }

        #------------------- MonitoringScript Folder Check
        $folderPath = "D:\DBBSetup\MonitoringScript"
        if (Test-Path $folderPath) {
            try {
                $size = (Get-ChildItem $folderPath -Recurse -Force -ErrorAction SilentlyContinue |
                         Where-Object { -not $_.PSIsContainer } |
                         Measure-Object -Property Length -Sum).Sum
                
                if ($null -eq $size -or $size -eq 0) {
                    $output.MonitoringScript = "Exists (0 GB)"
                } else {
                    $sizeGB = [math]::Round($size / 1GB, 2)
                    $output.MonitoringScript = "Exists ($sizeGB GB)"
                }
            } catch {
                $output.MonitoringScript = "Exists (Error reading size)"
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
    table { border-collapse: collapse; width: 100%; font-family: Arial; margin-top: 20px; }
    th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
    th { background-color: #4CAF50; color: white; font-weight: bold; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    tr:hover { background-color: #f5f5f5; }
    .bad { color: red; font-weight: bold; }
    .good { color: green; font-weight: bold; }
    .warn { color: orange; font-weight: bold; }
    h2 { color: #333; font-family: Arial; }
    body { padding: 20px; }
</style>
"@

# Function to wrap values with color spans
function Format-Cell {
    param($value)

    # Convert to lowercase for comparison
    $lowerValue = $value.ToLower()

    if ($lowerValue -match 'unreachable') {
        return "<span class='warn'>$value</span>"
    }
    elseif ($lowerValue -match 'not installed|missing|not found|error|service not found|not in registry|wrong account') {
        return "<span class='bad'>$value</span>"
    }
    elseif ($lowerValue -match 'installed|available|passed|exists') {
        return "<span class='good'>$value</span>"
    }
    else {
        return $value
    }
}

# Build HTML table manually so spans are not escaped
$header = @"
<html>
<head>
<meta charset="UTF-8">
$style
<title>Batch Server Validation Report</title>
</head>
<body>
<h2>Batch Server Validation Report - Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</h2>
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
    "<td><strong>$($row.ServerName)</strong></td>" +
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
$htmlContent = $header + ($rows -join "`n") + $footer
$htmlContent | Out-File $HtmlFile -Encoding UTF8

Write-Host "`nReport saved to $HtmlFile" -ForegroundColor Green
Write-Host "Total servers checked: $($ValidationResults.Count)" -ForegroundColor Cyan

# Open the report
Start-Process $HtmlFile