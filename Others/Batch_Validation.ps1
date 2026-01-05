######################################################################################################################
# BCP Instalaltion Check  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 |  BCP Instalaltion Check | Date:: 04-April-2025
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

# Ensure server names are in array format
$ServerList = $ServerList.Name  # Make sure $ServerList is a list of names, or replace with an array like @('Server1', 'Server2')
Read-Host "Please verify the server list and press Enter to continue or Stop the script"

# Initialize variables
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$ValidationResults = @()

# ----------- Step 3: Perform remote checks -----------
foreach ($Server in $ServerList) {
    Write-Host "`n?? Checking server: $Server" -ForegroundColor Cyan

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

        return $output
    } -ErrorAction SilentlyContinue

    if (-not $result) {
        $result = @{
            BCP = "Unreachable"
            Python = "Unreachable"
            PlatformVersion = "Unreachable"
            TranslateExe = "Unreachable"
            VisualCronService = "Unreachable"
            GPA = "Unreachable"
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
    }
}

# ----------- Step 4: Generate HTML Report -----------
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HtmlFile = "C:\Temp\RemoteValidationReport_$timestamp.html"

$style = @"
<style>
    table { border-collapse: collapse; width: 100%; font-family: Arial; }
    th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
</style>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const cells = document.querySelectorAll('td');
        cells.forEach(cell => {
            const text = cell.textContent.toLowerCase();
            if (text.includes('not installed') || 
                text.includes('missing') || 
                text.includes('error') || 
                text.includes('not found') || 
                text.includes('unreachable')) {
                cell.style.color = 'red';
            } else if (text.includes('passed') || text.includes('available') || text.includes('installed')) {
                cell.style.color = 'green';
            }
        });
    });
</script>
"@

$ValidationResults | ConvertTo-Html -Property ServerName, BCP, Python, PlatformVersion, TranslateExe, VisualCronService, GPA -Head $style -Title "Remote Server Validation Report" |
    Out-File $HtmlFile -Encoding UTF8

Write-Host "`n? Report saved to $HtmlFile" -ForegroundColor Green
Start-Process $HtmlFile