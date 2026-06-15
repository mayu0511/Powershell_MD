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

Clear-Host

$Results = @()

# ========================
# AUTO DETECT FROM HOSTNAME
# ========================
$ThisServer = (hostname).ToLower()

# ENV
if ($ThisServer -match "patqa") {
    $EnvironmentName = "patqa"
}
elseif ($ThisServer -match "patuat") {
    $EnvironmentName = "patuat"
}
elseif ($ThisServer -match "prod") {
    $EnvironmentName = "prod"
}

# REGION
if ($ThisServer -match "e1") {
    $ShortRegion = "e1"
}
elseif ($ThisServer -match "w2") {
    $ShortRegion = "w2"
}

# STACK
if ($ThisServer -match "pod2") {
    $EnvironmentStack = "pod2"
}
elseif ($ThisServer -match "pod4") {
    $EnvironmentStack = "pod4"
}

Write-Host "ENV: $EnvironmentName | REGION: $ShortRegion | STACK: $EnvironmentStack"
Write-Host "---------------------------------------------"

# ========================
# SERVER LOOP
# ========================
foreach ($computername in $ServerList) {

    try {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer 

        $output = Invoke-Command -ComputerName $computername `
            -SessionOption $option `
            -ErrorAction SilentlyContinue `
            -ArgumentList $EnvironmentName, $ShortRegion, $EnvironmentStack `
            -ScriptBlock {

            param($envName, $region, $stack)

            $mipList = @()
            $port = $null

            switch ($envName) {

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

                    # SIMPLE PORT LOGIC
                    if ($stack -match "pod2") {
                        $port = 7003
                    }
                    elseif ($stack -match "pod4") {
                        $port = 7004
                    }
                }
            }

            $result = @()

            if ($port -and $mipList.Count -gt 0) {
                foreach ($mip in $mipList) {

                    $test = Test-NetConnection -ComputerName $mip -Port $port -WarningAction SilentlyContinue

                    $result += [PSCustomObject]@{
                        "MIP Name" = $mip
                        "Port"     = $port
                        "Status"   = if ($test.TcpTestSucceeded) { "Success" } else { "Failed" }
                    }
                }
            }
            else {
                $result += [PSCustomObject]@{
                    "MIP Name" = "N/A"
                    "Port"     = "-"
                    "Status"   = "Invalid Config"
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

# ========================
# DISPLAY OUTPUT
# ========================
$Results | Format-Table -AutoSize

# ========================
# HTML REPORT
# ========================

$ReportPath = "C:\Temp\MIPS_Report.html"

# Add color column
$HtmlData = $Results | Select-Object `
    "Server Name",
    "MIP Name",
    "Port",
    @{Name="Status";Expression={
        if ($_.Status -eq "Success") {
            "<span style='color:green;font-weight:bold;'>Success</span>"
        }
        elseif ($_.Status -eq "Failed") {
            "<span style='color:red;font-weight:bold;'>Failed</span>"
        }
        else {
            "<span style='color:orange;font-weight:bold;'>Invalid Config</span>"
        }
    }}

# HTML Style
$style = @"
<style>
body { font-family: Arial; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background-color: #333; color: white; padding: 8px; text-align: left; }
td { border: 1px solid #ddd; padding: 6px; }
tr:nth-child(even) { background-color: #f2f2f2; }
</style>
"@

$HtmlReport = $HtmlData | ConvertTo-Html -Title "MIPS Telnet Connectivity Report" -Head $style | Out-String

# Fix HTML rendering issue
$HtmlReport = $HtmlReport -replace '&lt;', '<' -replace '&gt;', '>'

$HtmlReport | Out-File $ReportPath
Start-Process $ReportPath