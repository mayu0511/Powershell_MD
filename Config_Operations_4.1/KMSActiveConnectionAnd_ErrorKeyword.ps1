######################################################################################################################
# KMS Active Connection And Error Keyword | DEVELOPED BY:: Mahendra Dwivedi
# # Version 1.3 |  KMS Active Connection | Date:: 19-Sep-2025
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

$ServerTypeList = @('kms')
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
Read-Host "Please verify the server list and press enter to continue or Stop the script"

# ---- Ask for how many log lines to check ----
$TailCount = Read-Host "Enter number of log lines to check (default 1000)"
if (-not $TailCount) { $TailCount = 1000 }

# ---- Collect Logs ----
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$results = @()  # Collect output here

foreach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    $logLines = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction SilentlyContinue -ScriptBlock {
        $folderPath = "D:\CoreCard\KMS\Service\Data"
        $today = (Get-Date).ToString("yyyy-MM-dd")

        # --- Try today's file first ---
        $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace$today*.txt" |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First 1

        # --- Fallback to latest if today's file doesn't exist ---
        if (-not $latestFile) {
            $latestFile = Get-ChildItem -Path $folderPath -Filter "kms-trace*.txt" |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First 1
        }

        if ($latestFile) {
            Get-Content -Path $latestFile.FullName -Tail $using:TailCount |
                Where-Object { $_ -match "INFO Connection received from|Authenticated|Starting as a service|on address https://localhost:8081|GC about to start|GC done|Error Code|decrypt failed|Service Stop|Service Started" }
        }
        else {
            "NO_LOG_FILE_FOUND"
        }
    }

    if ($logLines.Count -eq 0 -or $logLines -contains "NO_LOG_FILE_FOUND") {
        $results += [PSCustomObject]@{
            "Server Name"   = $computername
            "Log Time"      = ""
            "Log Message"   = "NO_CONNECTION_FOUND"
            "StatusClass"   = "error"
        }
    }
    else {
        foreach ($line in $logLines) {
            $statusClass = "ok"

            if ($line -match "Error Code|decrypt failed|Service Stop") {
                $statusClass = "error"
            } elseif ($line -match "Service Started") {
                $statusClass = "started"
            }

            $regex = '^(?<Date>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (?<Message>.*)'
            $date = ""
            $message = $line
            if ($line -match $regex) {
                $date = $matches['Date']
                $message = $matches['Message']
            }

            $results += [PSCustomObject]@{
                "Server Name"   = $computername
                "Log Time"      = $date
                "Log Message"   = $message
                "StatusClass"   = $statusClass
            }
        }
    }
}

# --- Build HTML report ---
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$htmlPath = "C:\temp\kmsactiveconnection-$timestamp.html"

$htmlHeader = @"
<html>
<head>
<title>KMS Active Connections</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
th { background-color: #333; color: white; }
tr.ok { background-color: #e6ffe6; }      /* Light green for normal */
tr.error { background-color: #ffe6e6; }   /* Light red for Error Code / decrypt failed / Service Stop */
tr.started { background-color: #e6f3ff; } /* Light blue for Service Started */
</style>
</head>
<body>
<h2>KMS Active Connection Report - $timestamp</h2>
<table>
<tr><th>Server Name</th><th>Date & Time</th><th>Status Message</th></tr>
"@

$htmlRows = foreach ($row in $results) {
    "<tr class='$($row.StatusClass)'><td>$($row.'Server Name')</td><td>$($row.'Log Time')</td><td>$($row.'Log Message')</td></tr>"
}

$htmlFooter = @"
</table>
</body>
</html>
"@

# Save and open HTML report
$htmlContent = $htmlHeader + ($htmlRows -join "`n") + $htmlFooter
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Start-Process $htmlPath
