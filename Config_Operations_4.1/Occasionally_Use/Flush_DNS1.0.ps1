######################################################################################################################
# IP Config Flush DNS   | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | IP Config Flush DNS for Source And Sink Servers | Date:: 17-April-2026
#=============================================================================================================================================

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

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique


$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"
$AvailabilityZone

$ServerTypeList = @('src' , 'snk')
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json) | Select-Object @{
        n = "Name"; e = { $_.Name }
    }, @{
        n = "AvailabilityZone"; e = { $_.AvailabilityZone }
    }, @{
        n = "serial"; e = {
            if ($_.Name -match '(\d+)$') {
    [int]$matches[1]

            } else {
            }
        }
    } | Sort-Object -Property serial, Name)
}

$ServerList | Out-Host

if ($null -eq $ServerList) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}


$ServerList = $ServerList | Where-Object { $_.Name } | Select-Object -ExpandProperty Name
Read-Host "Please verify the server list and press Enter to continue or Stop the script"

$Results = @()

foreach ($computername in $ServerList) {

    try {
     $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
       # $output = Invoke-Command -ComputerName $computername -ScriptBlock {
          $output = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
            ipconfig /flushdns
       }

        $status = "Command Executed"
        $rowColor = "#d4edda"   # Light Green
    }
    catch {
        $output = $_.Exception.Message
        $status = "Failed"
        $rowColor = "#ffe5b4"   # Light Orange
    }

    $Results += [PSCustomObject]@{
        ServerName = $computername
        Output     = ($output -join " ")
        Status     = $status
        RowColor   = $rowColor
    }
}

# Build HTML manually (for full control)
$rows = foreach ($r in $Results) {
    "<tr style='background-color:$($r.RowColor)'>
        <td>$($r.ServerName)</td>
        <td>$($r.Output)</td>
        <td><b>$($r.Status)</b></td>
    </tr>"
}

# Summary
$total   = $Results.Count
$success = ($Results | Where-Object {$_.Status -eq "Command Executed"}).Count
$failed  = ($Results | Where-Object {$_.Status -eq "Failed"}).Count

# HTML content
$HtmlReport = @"
<html>
<head>
<title>DNS Flush Report</title>
<style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid black; padding: 8px; text-align: left; }
th { background-color: #f2f2f2; }
h2 { color: #333; }
.summary { margin-bottom: 15px; }
</style>
</head>
<body>

<h2>DNS Flush Status</h2>

<div class='summary'>
<b>Total Servers:</b> $total <br>
<b>Success:</b> <span style='color:green;'>$success</span> <br>
<b>Failed:</b> <span style='color:orange;'>$failed</span>
</div>

<table>
<tr>
    <th>Server Name</th>
    <th>Output</th>
    <th>Status</th>
</tr>

$($rows -join "`n")

</table>

</body>
</html>
"@

# Save report
$ReportPath = "C:\Temp\DNSFlushReport.html"
$HtmlReport | Out-File $ReportPath -Encoding UTF8

# Open report
Start-Process $ReportPath