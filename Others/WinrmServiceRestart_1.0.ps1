########################################################################################################################
# WinRM Service Restart Script | DEVELOPED BY:: Mahendra Dwivedi
# Version 2.0 | AWS Integration with HTML Reporting | Date:: 28-November-2025
#======================================================================================================================

Clear-Host

# Determine Region from Hostname
$ThisServer = (hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
} else {
    Write-Host "Unable to determine region from hostname. Exiting..." -ForegroundColor Red
    exit
}

# Get AWS Variables
$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

# POD Selection
if ($EnvironmentAttribution -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2" -ForegroundColor Cyan
    Write-Host "2. COOKIE - POD3 (POD4)" -ForegroundColor Cyan
    
    $PODNumberSelected = Read-Host "`nEnter your choice (1 or 2)"
    
    if ($PODNumberSelected -eq "1") {
        $PODName = "pod2"
    } elseif ($PODNumberSelected -eq "2") {
        $PODName = "pod4"
    } else {
        Write-Host "Invalid POD Name. Exiting..." -ForegroundColor Red
        exit
    }
} elseif ($EnvironmentAttribution -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attribution. Exiting..." -ForegroundColor Red
    exit
}

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"

# Get Availability Zones
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

Write-Host "`nAvailable Zones: $($AvailabilityZones -join ', ')" -ForegroundColor Yellow
$AvailabilityZone = Read-Host "Type Availability Zone from list above or * for all zones"

# Define Server Types
$ServerTypeList = @('bat', 'svc')
$ServerList = @()

# Build Server List from AWS
foreach ($ServerType in $ServerTypeList) {
    if ($AvailabilityZone -eq "*") {
        $ServersToAdd = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:attribution,Values=$EnvironmentAttribution" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json).Name
    } else {
        $ServersToAdd = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:attribution,Values=$EnvironmentAttribution" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values=$AvailabilityZone" --region $Region | ConvertFrom-Json).Name
    }
    
    if ($ServersToAdd) {
        $ServerList += $ServersToAdd
    }
}

# Display Server List
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Servers to Restart WinRM Service:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$ServerList | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
Write-Host "Total Servers: $($ServerList.Count)" -ForegroundColor Yellow

# Confirm before proceeding
$confirmation = Read-Host "`nDo you want to proceed with WinRM restart? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit
}

# Get Credentials
$credential = Get-Credential -Message "Enter Domain Admin credentials"

# Results array
$results = @()

Write-Host "`nStarting WinRM service restart on $($ServerList.Count) servers..." -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

foreach ($server in $ServerList) {
    Write-Host "`nProcessing: $server" -ForegroundColor Yellow
    
    try {
        # Test if server is reachable
        if (Test-Connection -ComputerName $server -Count 1 -Quiet) {
            
            # Method 1: Try using Invoke-Command with explicit credentials
            try {
                Write-Host "  Attempting remote restart via Invoke-Command..." -ForegroundColor Gray
                
                $session = New-PSSession -ComputerName $server -Credential $credential -ErrorAction Stop
                
                Invoke-Command -Session $session -ScriptBlock {
                    Restart-Service -Name WinRM -Force
                    Start-Sleep -Seconds 3
                    Get-Service -Name WinRM | Select-Object Name, Status
                } -ErrorAction Stop
                
                Remove-PSSession -Session $session
                
                Write-Host "  SUCCESS: WinRM service restarted on $server" -ForegroundColor Green
                
                $results += [PSCustomObject]@{
                    Server = $server
                    Status = "Success"
                    Method = "Invoke-Command"
                    Message = "WinRM restarted successfully"
                }
                continue
            }
            catch {
                Write-Host "  Method 1 failed: $($_.Exception.Message)" -ForegroundColor Yellow
                
                # Method 2: Try using WMI/CIM as fallback
                try {
                    Write-Host "  Attempting restart via WMI..." -ForegroundColor Gray
                    
                    $service = Get-WmiObject -Class Win32_Service -ComputerName $server -Credential $credential -Filter "Name='WinRM'" -ErrorAction Stop
                    
                    if ($service) {
                        $stopResult = $service.StopService()
                        Start-Sleep -Seconds 2
                        $startResult = $service.StartService()
                        
                        if ($startResult.ReturnValue -eq 0) {
                            Write-Host "  SUCCESS: WinRM service restarted on $server using WMI" -ForegroundColor Green
                            
                            $results += [PSCustomObject]@{
                                Server = $server
                                Status = "Success"
                                Method = "WMI"
                                Message = "WinRM restarted successfully via WMI"
                            }
                        }
                        else {
                            throw "WMI start service returned code: $($startResult.ReturnValue)"
                        }
                    }
                    continue
                }
                catch {
                    Write-Host "  Method 2 failed: $($_.Exception.Message)" -ForegroundColor Yellow
                    
                    # Method 3: Try using sc.exe remotely
                    try {
                        Write-Host "  Attempting restart via sc.exe..." -ForegroundColor Gray
                        
                        # Stop service
                        $stopCmd = "sc.exe \\$server stop WinRM"
                        $null = Invoke-Expression $stopCmd 2>&1
                        Start-Sleep -Seconds 3
                        
                        # Start service
                        $startCmd = "sc.exe \\$server start WinRM"
                        $startOutput = Invoke-Expression $startCmd 2>&1
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "  SUCCESS: WinRM service restarted on $server using sc.exe" -ForegroundColor Green
                            
                            $results += [PSCustomObject]@{
                                Server = $server
                                Status = "Success"
                                Method = "sc.exe"
                                Message = "WinRM restarted successfully via sc.exe"
                            }
                        }
                        else {
                            throw "sc.exe returned exit code: $LASTEXITCODE"
                        }
                    }
                    catch {
                        Write-Host "  ERROR: All methods failed for $server" -ForegroundColor Red
                        
                        $results += [PSCustomObject]@{
                            Server = $server
                            Status = "Failed"
                            Method = "All"
                            Message = "All restart methods failed. Check permissions and WinRM configuration."
                        }
                    }
                }
            }
        }
        else {
            Write-Host "  FAILED: Cannot reach $server" -ForegroundColor Red
            
            $results += [PSCustomObject]@{
                Server = $server
                Status = "Failed"
                Method = "N/A"
                Message = "Server unreachable"
            }
        }
    }
    catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        
        $results += [PSCustomObject]@{
            Server = $server
            Status = "Error"
            Method = "N/A"
            Message = $_.Exception.Message
        }
    }
}

# Display summary
Write-Host "`n" -NoNewline
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "Summary Report" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

$results | Format-Table -AutoSize

# Calculate statistics
$successCount = ($results | Where-Object {$_.Status -eq "Success"}).Count
$failedCount = ($results | Where-Object {$_.Status -ne "Success"}).Count

Write-Host "`nTotal Servers: $($ServerList.Count)" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failedCount" -ForegroundColor Red

# Generate HTML Report
$htmlPath = "C:\temp\winrmservicerestart.html"

# Create HTML content with styling
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>WinRM Service Restart Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            margin: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        .info {
            background-color: #e8f4f8;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border-left: 4px solid #3498db;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th {
            background-color: #3498db;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: bold;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .success {
            color: #27ae60;
            font-weight: bold;
        }
        .failed {
            color: #e74c3c;
            font-weight: bold;
        }
        .error {
            color: #e67e22;
            font-weight: bold;
        }
        .summary {
            display: flex;
            justify-content: space-around;
            margin: 20px 0;
        }
        .summary-box {
            padding: 20px;
            border-radius: 5px;
            text-align: center;
            flex: 1;
            margin: 0 10px;
        }
        .summary-box h3 {
            margin: 0;
            font-size: 2em;
        }
        .summary-box p {
            margin: 5px 0 0 0;
            color: #666;
        }
        .total-box {
            background-color: #3498db;
            color: white;
        }
        .success-box {
            background-color: #27ae60;
            color: white;
        }
        .failed-box {
            background-color: #e74c3c;
            color: white;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>WinRM Service Restart Report</h1>
        <div class="info">
            <strong>Execution Time:</strong> $(Get-Date -Format "dddd, MMMM dd, yyyy hh:mm:ss tt")<br>
            <strong>Executed By:</strong> $env:USERNAME<br>
            <strong>Computer:</strong> $env:COMPUTERNAME<br>
            <strong>Region:</strong> $Region ($ShortRegion)<br>
            <strong>Environment:</strong> $EnvironmentName<br>
            <strong>Attribution:</strong> $EnvironmentAttribution<br>
            <strong>POD:</strong> $PODName<br>
            <strong>Availability Zone:</strong> $AvailabilityZone
        </div>
        <div class="summary">
            <div class="summary-box total-box">
                <h3>$($ServerList.Count)</h3>
                <p>Total Servers</p>
            </div>
            <div class="summary-box success-box">
                <h3>$successCount</h3>
                <p>Successful</p>
            </div>
            <div class="summary-box failed-box">
                <h3>$failedCount</h3>
                <p>Failed</p>
            </div>
        </div>
        <table>
            <tr>
                <th>Server</th>
                <th>Status</th>
                <th>Method</th>
                <th>Message</th>
            </tr>
"@

$htmlRows = ""
foreach ($result in $results) {
    $statusClass = switch ($result.Status) {
        "Success" { "success" }
        "Failed" { "failed" }
        "Error" { "error" }
        default { "" }
    }
    
    $htmlRows += @"
            <tr>
                <td>$($result.Server)</td>
                <td class="$statusClass">$($result.Status)</td>
                <td>$($result.Method)</td>
                <td>$($result.Message)</td>
            </tr>
"@
}

$htmlFooter = @"
        </table>
        <div class="footer">
            <p>Generated by WinRM Service Restart Script | Developed by: Mahendra Dwivedi</p>
        </div>
    </div>
</body>
</html>
"@

$htmlContent = $htmlHeader + $htmlRows + $htmlFooter

# Ensure directory exists
$tempDir = Split-Path $htmlPath -Parent
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Save HTML report
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "`nHTML Report generated: $htmlPath" -ForegroundColor Cyan

# Open the HTML report in default browser
Start-Process $htmlPath

Write-Host "`nScript execution completed!" -ForegroundColor Green