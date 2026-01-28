######################################################################################################################
# Stop-Processes During Upgrade  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 |  Stop-Processes | Date:: 15-Oct-2025
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

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName

$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon

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
        Write-Host "Invalid POD Name. Exiting..."
        Break Script
    }
    
    $PODName = "pod2"
} elseif ($Environmentattributon -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attributon. Exiting..."
    #Break Script
}

$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack

$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZone = $NULL
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$AvailabilityZone
$ServerTypeList = @('bat' ,'TNP', 'AWF')
$ServerType = $Null
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host
Read-Host "Verify the server list and press Enter to continue"

# --- Output folder setup ---
$reportFolder = "C:\Temp"
if (-not (Test-Path $reportFolder)) { New-Item -Path $reportFolder -ItemType Directory | Out-Null }

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


# --- Remote process stop ---
foreach ($computer in $ServerList.Name) {
    Write-Host "Connecting to $computer" -ForegroundColor Cyan
    Add-Content $logFile "`nServer: $computer"
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
        
        foreach ($r in $remoteResults) { 
            Add-Content $logFile "[$(Get-Date -Format HH:mm:ss)] $($r.'Server Name') - $($r.'Process Name') - $($r.Status)" 
        }
    }
    catch {
        $err = "Connection failed for $computer - $($_.Exception.Message)"
        Write-Host $err -ForegroundColor Red
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
table{border-collapse:collapse;width:100%;background:#fff;}
th,td{border:1px solid #ddd;padding:8px;text-align:left;}
th{background:#4CAF50;color:white;}
tr:nth-child(even){background:#f2f2f2;}
.Stopped{color:green;font-weight:bold;}
.NotRunning{color:gray;}
.Error{color:red;font-weight:bold;}
.ConnectionFailed{color:darkred;font-weight:bold;}
</style></head><body>
<h2>Process Stop Report - $timestamp</h2>
<p>Generated On: $(Get-Date)</p>
"@

$htmlTable = "<table><tr><th>Server Name</th><th>Process Name</th><th>Status</th></tr>"
foreach ($r in $results) {
    $class = switch ($r.Status) {
        "Stopped" { "Stopped" }
        "Not Running" { "NotRunning" }
        "Connection Failed" { "ConnectionFailed" }
        default { "Error" }
    }
    $htmlTable += "<tr><td>$($r.'Server Name')</td><td>$($r.'Process Name')</td><td class='$class'>$($r.Status)</td></tr>"
}
$htmlTable += "</table>"
$htmlFooter = "</body></html>"

($htmlHeader + $htmlTable + $htmlFooter) | Out-File -FilePath $reportFile -Encoding UTF8

Add-Content $logFile ("=" * 60)
Add-Content $logFile "HTML report generated at: $reportFile"
Add-Content $logFile "Script completed on: $(Get-Date)"
Add-Content $logFile ("=" * 60)

Start-Process $reportFile
Write-Host "Remote process stop completed."
Write-Host "HTML Report: $reportFile"
Write-Host "Log File   : $logFile"
