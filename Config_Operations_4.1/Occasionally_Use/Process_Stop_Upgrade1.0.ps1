######################################################################################################################
# Stop-Processes During Upgrade  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.4 |  Stop-Processes | Date:: 15-Oct-2025
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

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Getting AWS Instance Information..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
Write-Host "Environment: $EnvironmentName" -ForegroundColor Green

$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
Write-Host "Attribution: $Environmentattributon" -ForegroundColor Green

if ($Environmentattributon -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2"
    Write-Host "2. COOKIE - POD3 (POD4)"
    
    $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
    
    if ($PODNumberSelected -eq "1") {
        $PODName = "pod2"
    } elseif ($PODNumberSelected -eq "2") {
        $PODName = "pod4"
    } else {
        $PODName = $NULL
        Write-Host "Invalid POD Name. Exiting..." -ForegroundColor Red
        exit
    }
} elseif ($Environmentattributon -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attribution. Exiting..." -ForegroundColor Red
    exit
}

$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
Write-Host "Stack: $EnvironmentStack" -ForegroundColor Green

# Get Availability Zones
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZone = $NULL
Write-Host "`nFetching Availability Zones..." -ForegroundColor Cyan

$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

Write-Host "Available Zones: $($AvailabilityZones -join ', ')" -ForegroundColor Yellow
$AvailabilityZone = Read-Host "Type Availability Zone ($($AvailabilityZones -join ', ')) or * for all zones"

# Define server types to search (try both uppercase and lowercase)
$ServerTypeList = @('bat', 'tnp', 'awf')  # lowercase as they appear in server names
$ServerList = @()

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Searching for Servers..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Debug: Show what patterns we're searching for
Write-Host "`nSearch Patterns:" -ForegroundColor Magenta
foreach ($st in $ServerTypeList) {
    $pattern = "*$st$ShortRegion$EnvironmentName$EnvironmentStack*"
    Write-Host "  $pattern" -ForegroundColor Magenta
}
Write-Host ""

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "Processing ServerType: $ServerType" -ForegroundColor Yellow
    
    # Build the search pattern
    $searchPattern = "*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*"
    Write-Host "  Search Pattern: $searchPattern" -ForegroundColor Gray
    
    try {
        # Query AWS for this server type
        $awsQuery = "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}"
        
        $awsOutput = aws ec2 describe-instances --query $awsQuery --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$searchPattern'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region
        
        if ($awsOutput) {
            $ServersFound = $awsOutput | ConvertFrom-Json
            
            if ($ServersFound -and $ServersFound.Count -gt 0) {
                Write-Host "  ? Found $($ServersFound.Count) server(s)" -ForegroundColor Green
                
                # Process each server found
                foreach ($server in $ServersFound) {
                    if ($server.Name) {
                        Write-Host "    - $($server.Name)" -ForegroundColor DarkGray
                        
                        # Calculate serial number
                        $serialNum = 0
                        try {
                            $splitResult = $server.Name -split "$EnvironmentName$EnvironmentStack"
                            if ($splitResult.Count -gt 1) {
                                $serialNum = [double]$splitResult[1]
                            }
                        } catch {
                            $serialNum = 0
                        }
                        
                        # Add to server list
                        $ServerList += [PSCustomObject]@{
                            Name = $server.Name
                            AvailabilityZone = $server.AvailabilityZone
                            ServerType = $ServerType.ToUpper()
                            IpAddress = $server.IpAddress
                            Serial = $serialNum
                        }
                    }
                }
            } else {
                Write-Host "  ? No servers found" -ForegroundColor Gray
            }
        } else {
            Write-Host "  ? No results from AWS" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  ? Error querying AWS: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Sort the server list by serial number
$ServerList = $ServerList | Sort-Object -Property Serial

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Total Servers Found: $($ServerList.Count)" -ForegroundColor Green

if ($ServerList.Count -eq 0) {
    Write-Host "`nNo servers found matching the criteria!" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. Server naming convention" -ForegroundColor Yellow
    Write-Host "  2. Environment name: $EnvironmentName" -ForegroundColor Yellow
    Write-Host "  3. Stack: $EnvironmentStack" -ForegroundColor Yellow
    Write-Host "  4. Region: $Region" -ForegroundColor Yellow
    Write-Host "  5. Availability Zone: $AvailabilityZone" -ForegroundColor Yellow
    exit
}

Write-Host "`nServers to Process:" -ForegroundColor Cyan
$ServerList | Format-Table Name, AvailabilityZone, ServerType, IpAddress -AutoSize | Out-Host

$confirmation = Read-Host "`nVerify the server list above. Continue? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit
}

# --- Output folder setup ---
$reportFolder = "C:\Temp"
if (-not (Test-Path $reportFolder)) { 
    New-Item -Path $reportFolder -ItemType Directory | Out-Null 
    Write-Host "Created report folder: $reportFolder" -ForegroundColor Green
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFile = Join-Path $reportFolder "ProcessStop_$timestamp.html"
$logFile    = Join-Path $reportFolder "ProcessStop_$timestamp.log"

# --- Processes to stop ---
$processNames = @(
    "Rundbb_TNP.exe",
    "Rundbb_ETNP.exe",
    "Rundbb_AccountReinstate.exe",
    "Rundbb_CoreAuthAging.exe",
    "Rundbb_ACHCreatePIIRequest_Cookie1.exe",
    "Rundbb_ACHSendPIIRequest_Cookie1.exe",
    "Rundbb_ACHCreatePIIRequest_Cookie2.exe",
    "Rundbb_ACHSendPIIRequest_Cookie2.exe",
    "Rundbb_PendingTxn.exe",
    "Rundbb_APJob.exe",
    "Rundbb_APIQueue.exe",
    "Rundbb_CBRCreatePIIRequest_Cookie1.exe",
    "Rundbb_CBRCreatePIIRequest_Cookie2.exe",
    "Rundbb_CBRSendPIIRequest_Cookie1.exe",
    "Rundbb_CBRSendPIIRequest_Cookie2.exe",
    "Rundbb_BillPayPayment.exe",
    "Rundbb_LockBox.exe",
    "Rundbb_AccountCreation.exe"
)

$results = @()
Add-Content $logFile "Process Stop Log - $timestamp"
Add-Content $logFile ("=" * 60)
Add-Content $logFile "Environment: $EnvironmentName"
Add-Content $logFile "Attribution: $Environmentattributon"
Add-Content $logFile "Stack: $EnvironmentStack"
Add-Content $logFile "Region: $Region"
Add-Content $logFile "Total Servers: $($ServerList.Count)"
Add-Content $logFile ("=" * 60)

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Starting Remote Process Stop..." -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# --- Remote process stop ---
$serverCount = 0
foreach ($server in $ServerList) {
    $serverCount++
    $computer = $server.Name
    Write-Host "[$serverCount/$($ServerList.Count)] Connecting to $computer ($($server.ServerType))" -ForegroundColor Cyan
    Add-Content $logFile "`nServer: $computer (Type: $($server.ServerType), Zone: $($server.AvailabilityZone))"
    Add-Content $logFile ("-" * 50)
    
    try {
        $session = New-PSSession -ComputerName $computer -SessionOption (New-PSSessionOption -ProxyAccessType NoProxyServer) -ErrorAction Stop
        
        $remoteResults = Invoke-Command -Session $session -ScriptBlock {
            param([string[]]$procList)
            $out = @()
            
            foreach ($proc in $procList) {
                $procName = $proc -replace '\.exe$',''
                try {
                    $p = Get-Process -Name $procName -ErrorAction SilentlyContinue
                    if ($p) { 
                        Stop-Process -Name $procName -Force -ErrorAction Stop
                        $status = "Stopped" 
                    }
                    else { 
                        $status = "Not Running" 
                    }
                } 
                catch { 
                    $status = "Error: $($_.Exception.Message)" 
                }
                
                $out += [PSCustomObject]@{
                    "Server Name"  = $env:COMPUTERNAME
                    "Process Name" = $proc
                    "Status"       = $status
                }
            }
            return $out
        } -ArgumentList (,$processNames)
        
        Remove-PSSession $session
        $results += $remoteResults
        
        # Log results
        foreach ($r in $remoteResults) { 
            Add-Content $logFile "[$(Get-Date -Format HH:mm:ss)] $($r.'Process Name') - $($r.Status)"
            if ($r.Status -eq "Stopped") {
                Write-Host "  ? $($r.'Process Name') - Stopped" -ForegroundColor Green
            } elseif ($r.Status -eq "Not Running") {
                Write-Host "  - $($r.'Process Name') - Not Running" -ForegroundColor Gray
            } else {
                Write-Host "  ? $($r.'Process Name') - $($r.Status)" -ForegroundColor Red
            }
        }
    }
    catch {
        $err = "Connection failed for $computer - $($_.Exception.Message)"
        Write-Host "  ? $err" -ForegroundColor Red
        Add-Content $logFile $err
        $results += [PSCustomObject]@{
            "Server Name" = $computer
            "Process Name" = "-"
            "Status" = "Connection Failed"
        }
    }
}

# --- HTML report ---
$htmlHeader = @"
<html><head><title>Process Stop Report - $timestamp</title>
<style>
body{font-family:Arial,sans-serif;background:#f7f7f7;margin:20px;}
h2{color:#333;}
.summary{background:#fff;padding:15px;margin-bottom:20px;border-radius:5px;box-shadow:0 2px 4px rgba(0,0,0,0.1);}
.summary p{margin:5px 0;}
table{border-collapse:collapse;width:100%;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,0.1);}
th,td{border:1px solid #ddd;padding:8px;text-align:left;}
th{background:#4CAF50;color:white;}
tr:nth-child(even){background:#f2f2f2;}
.Stopped{color:green;font-weight:bold;}
.NotRunning{color:gray;}
.Error{color:red;font-weight:bold;}
.ConnectionFailed{color:darkred;font-weight:bold;}
</style></head><body>
<h2>Process Stop Report - $timestamp</h2>
"@

# Filter results to show only stopped processes
$stoppedProcesses = $results | Where-Object { $_.Status -eq "Stopped" }

$htmlTable = "<table><tr><th>Server Name</th><th>Process Name</th><th>Status</th></tr>"

if ($stoppedProcesses.Count -gt 0) {
    foreach ($r in $stoppedProcesses) {
        $htmlTable += "<tr><td>$($r.'Server Name')</td><td>$($r.'Process Name')</td><td class='Stopped'>$($r.Status)</td></tr>"
    }
} else {
    $htmlTable += "<tr><td colspan='3' style='text-align:center;color:gray;'>No processes were stopped</td></tr>"
}
$htmlTable += "</table>"
$htmlFooter = "</body></html>"

($htmlHeader + $htmlTable + $htmlFooter) | Out-File -FilePath $reportFile -Encoding UTF8

Add-Content $logFile "`n"
Add-Content $logFile ("=" * 60)
Add-Content $logFile "HTML report generated at: $reportFile"
Add-Content $logFile "Script completed on: $(Get-Date)"
Add-Content $logFile ("=" * 60)

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Process Stop Completed!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "HTML Report: $reportFile" -ForegroundColor Yellow
Write-Host "Log File   : $logFile" -ForegroundColor Yellow

Start-Process $reportFile