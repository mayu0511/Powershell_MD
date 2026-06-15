######################################################################################################################
# IP Config Flush DNS   | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | IP Config Flush DNS For Source And Sink Servers | Date:: 17-April-2026
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

        $output = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction SilentlyContinue -ScriptBlock {

            $mipList = @(
                "patqa.dc11-36a.mips.infra.marcus.com",
                "patqa.dc11-36b.mips.infra.marcus.com"
            )

            $port = 7035
            $result = @()

            foreach ($mip in $mipList) {
                $test = Test-NetConnection -ComputerName $mip -Port $port -WarningAction SilentlyContinue

                $result += [PSCustomObject]@{
                    "MIP Name" = $mip
                    "Status"   = $test.TcpTestSucceeded
                }
            }

            return $result
        }

        foreach ($item in $output) {
            $Results += [PSCustomObject]@{
                "Server Name" = $computername
                "MIP Name"    = $item."MIP Name"
                "Status"      = $item.Status
            }
        }

    } catch {
        $Results += [PSCustomObject]@{
            "Server Name" = $computername
            "MIP Name"    = "N/A"
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
.true { background-color: #c6efce; }   /* green */
.false { background-color: #ffc7ce; }  /* red */
</style>
"@

$rows = foreach ($r in $Results) {
    $statusClass = if ($r.Status -eq $true) { "true" } else { "false" }

    "<tr class='$statusClass'>
        <td>$($r.'Server Name')</td>
        <td>$($r.'MIP Name')</td>
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
<th>Status</th>
</tr>
$rows
</table>
</body>
</html>
"@

$html | Out-File $ReportPath

# Auto open
Start-Process $ReportPath