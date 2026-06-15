######################################################################################################################
# MIP Connection Test   | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | MIP Connection Test for  Source And Sink Servers | Date:: 17-April-2026
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

        $output = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction SilentlyContinue -ArgumentList $EnvironmentName,$ShortRegion,$EnvironmentStack -ScriptBlock {

            param($envName,$region,$stack)

            $mipList = @()
$port = $null

switch ($envName.ToLower()) {

    "patqa" {
        $mipList = @(
            "patqa.dc11-36a.mips.infra.marcus.com",
            "patqa.dc11-36b.mips.infra.marcus.com"
        )
        $port = 7035
    }

    "patuat" {
        $mipList = @(
            "patuat.dc11-36a.mips.infra.marcus.com",
            "patuat.dc11-36b.mips.infra.marcus.com"
        )
        $port = 7034
    }

    "prod" {

        if ($region -eq "e1") {
            $mipList = @(
                "prod.dc11-36a.mips.infra.marcus.com",
                "prod.dc11-36b.mips.infra.marcus.com"
            )
        }
        elseif ($region -eq "w2") {
            $mipList = @(
                "prod.se3-36c.mips.infra.marcus.com",
                "prod.se3-36d.mips.infra.marcus.com"
            )
        }

        if ($stack -match "pod2") {
            $port = 7003
        }
        elseif ($stack -match "pod4") {
            $port = 7004
        }
    }  
}      

# ========================
# Connection Test
# ========================

$result = @()

foreach ($mip in $mipList) {
    $test = Test-NetConnection -ComputerName $mip -Port $port -WarningAction SilentlyContinue

    $result += [PSCustomObject]@{
        "MIP Name" = $mip
        "Port"     = $port
        "Status"   = $test.TcpTestSucceeded
    }
}

return $result
        }

        foreach ($item in $output) {
            $Results += [PSCustomObject]@{
                "Server Name" = $computername
                "MIP Name"    = $item."MIP Name"
                "Port"        = $item.Port
                "Status"      = $item.Status
            }
        }

    } catch {
        $Results += [PSCustomObject]@{
            "Server Name" = $computername
            "MIP Name"    = "N/A"
            "Port"        = "-"
            "Status"      = "Failed"
        }
    }
}
$ReportPath = "$env:TEMP\MIP_Telnet_Report.html"

$style = @"
<style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid black; padding: 6px; text-align: left; }
th { background-color: #333; color: white; }
.true { background-color: #c6efce; }
.false { background-color: #ffc7ce; }
</style>
"@

$rows = foreach ($r in $Results) {
    $statusClass = if ($r.Status -eq $true) { "true" } else { "false" }

    "<tr class='$statusClass'>
        <td>$($r.'Server Name')</td>
        <td>$($r.'MIP Name')</td>
        <td>$($r.Port)</td>
        <td>$($r.Status)</td>
    </tr>"
}

$html = @"
<html>
<head>
<title>MIPS Telnet Report</title>
$style
</head>
<body>
<h2>MIPS Telnet Connectivity Report</h2>
<table>
<tr>
<th>Server Name</th>
<th>MIP Name</th>
<th>Port</th>
<th>Status</th>
</tr>
$rows
</table>
</body>
</html>
"@

$html | Out-File $ReportPath
Start-Process $ReportPath