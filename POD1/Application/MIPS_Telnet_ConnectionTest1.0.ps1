######################################################################################################################
# MIP Connection Test  DEVELOPED BY :: Mahendra Dwivedi
# Version 1.3  Description : MIP Connectivity Test for Source and Sink Servers
######################################################################################################################

Clear-Host
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "           MIP Connectivity Test Utility             " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

#----------------------------------------------------------
# Detect Current Server
#----------------------------------------------------------

$ThisServer = $env:COMPUTERNAME.ToLower()

switch -Regex ($ThisServer) {

    "e1" {
        $Region      = "us-east-1"
        $ShortRegion = "e1"
    }

    "w2" {
        $Region      = "us-west-2"
        $ShortRegion = "w2"
    }

    default {

        Write-Host "Unable to determine AWS Region from server name." -ForegroundColor Red
        Exit

    }

}

Write-Host "Current Server : $ThisServer"
Write-Host "AWS Region     : $Region"
Write-Host ""

#----------------------------------------------------------
# Get AWS Details of Current Server
#----------------------------------------------------------

try {

    $AWSVariables = aws ec2 describe-instances `
        --region $Region `
        --filters `
            "Name=instance-state-name,Values=running" `
            "Name=tag:Name,Values=$ThisServer" `
        --query "Reservations[].Instances[].{
                Name:Tags[?Key=='Name']|[0].Value,
                Environment:Tags[?Key=='environment']|[0].Value,
                Stack:Tags[?Key=='stack']|[0].Value,
                Pod:Tags[?Key=='pod']|[0].Value,
                AvailabilityZone:Placement.AvailabilityZone
            }" `
        --output json | ConvertFrom-Json

}
catch {

    Write-Host "Unable to retrieve AWS information." -ForegroundColor Red
    Exit

}

if (!$AWSVariables) {

    Write-Host "Current server not found in AWS." -ForegroundColor Red
    Exit

}

$EnvironmentName  = $AWSVariables.Environment.ToLower()
$EnvironmentStack = $AWSVariables.Stack.ToLower()
$Pod              = $AWSVariables.Pod.ToLower()

Write-Host "Environment : $EnvironmentName"
Write-Host "Stack       : $EnvironmentStack"
Write-Host "POD         : $Pod"
Write-Host ""


$EnvironmentDomain = "cc-$Pod-$EnvironmentName".ToLower()

Write-Host "Environment Domain : $EnvironmentDomain" -ForegroundColor Green
Write-Host ""

#----------------------------------------------------------
# Get Availability Zones
#----------------------------------------------------------

$AvailabilityZonesDefaultServerType = "tnp"

$AvailabilityZones = aws ec2 describe-instances `
    --region $Region `
    --filters `
        "Name=instance-state-name,Values=running" `
        "Name=tag:Name,Values=*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName*" `
    --query "Reservations[].Instances[].Placement.AvailabilityZone" `
    --output json |
ConvertFrom-Json |
Sort-Object -Unique

Write-Host "Available Zones"
Write-Host "---------------"

$AvailabilityZones | ForEach-Object {

    Write-Host $_

}

Write-Host ""

$AvailabilityZone = Read-Host "Enter Availability Zone or * for ALL"

#----------------------------------------------------------
# Discover SRC and SNK Servers
#----------------------------------------------------------

$ServerTypeList = @(

    "src",
    "snk"

)

$ServerList = @()

foreach ($ServerType in $ServerTypeList) {

    Write-Host ""
    Write-Host "Searching $ServerType Servers..."

    $Query = aws ec2 describe-instances `
        --region $Region `
        --filters `
            "Name=instance-state-name,Values=running" `
            "Name=tag:Name,Values=*$ServerType$ShortRegion$EnvironmentName*" `
        --query "Reservations[].Instances[].{
                Name:Tags[?Key=='Name']|[0].Value,
                AvailabilityZone:Placement.AvailabilityZone
            }" `
        --output json

    $Servers = $Query | ConvertFrom-Json

    foreach ($Server in $Servers) {

        if (($AvailabilityZone -eq "*") -or ($Server.AvailabilityZone -eq $AvailabilityZone)) {

            $ServerList += [PSCustomObject]@{

                Name = $Server.Name
                AvailabilityZone = $Server.AvailabilityZone

            }

        }

    }

}

#----------------------------------------------------------
# Sort Server List
#----------------------------------------------------------

$ServerList = $ServerList |
Sort-Object {

    if ($_.Name -match '(\d+)$') {

        [int]$Matches[1]

    }
    else {

        9999

    }

},
Name

if (!$ServerList) {

    Write-Host ""
    Write-Host "No matching servers found." -ForegroundColor Red
    Exit

}

Write-Host ""
Write-Host "====================================================="
Write-Host "Servers Selected"
Write-Host "====================================================="
Write-Host ""

$ServerList | Format-Table -AutoSize

Read-Host "`nPress ENTER to continue"

#----------------------------------------------------------
# Variables used in next section
#----------------------------------------------------------

$Option = New-PSSessionOption -ProxyAccessType NoProxyServer

$Results = @()

Write-Host ""
Write-Host "Starting Connectivity Test..."
Write-Host ""

#######################################################################
# PART 2 - Remote MIP Mapping & Connectivity Test
#######################################################################

foreach ($ComputerName in ($ServerList.Name))
{
    try
    {
        $Output = Invoke-Command `
            -ComputerName $ComputerName `
            -SessionOption $Option `
            -ErrorAction Stop `
            -ArgumentList $EnvironmentDomain,$ShortRegion `
            -ScriptBlock {

            param(
                $EnvironmentDomain,
                $Region
            )

            $MIPList = @()
            $Port = $null

            switch ($EnvironmentDomain.ToLower())
            {

                ###########################################################
                # POD1 PATUAT
                ###########################################################

                "cc-pod1-patuat"
                {
                    $Port = 7034

                    $MIPList = @(
                        "patuat.dc11-36a.mips.infra.marcus.com",
                        "patuat.dc11-36b.mips.infra.marcus.com"
                    )
                }

                ###########################################################
                # POD1 PATQA
                ###########################################################

                "cc-pod1-patqa"
                {
                    $Port = 7035

                    $MIPList = @(
                        "patqa.dc11-3jj.mips.infra.marcus.com",
                        "patqa.dc11-3jk.mips.infra.marcus.com"
                    )
                }

                ###########################################################
                # POD2 PATUAT
                ###########################################################

                "cc-pod2-patuat"
                {
                    $Port = 7034

                    $MIPList = @(
                        "patuat.dc11-3jj.mips.infra.marcus.com",
                        "patuat.dc11-3jk.mips.infra.marcus.com"
                    )
                }

                ###########################################################
                # POD2 PATQA
                ###########################################################

                "cc-pod2-patqa"
                {
                    $Port = 7035

                    $MIPList = @(
                        "patqa.dc11-36a.mips.infra.marcus.com",
                        "patqa.dc11-36b.mips.infra.marcus.com"
                    )
                }

                ###########################################################
# POD2 PROD
###########################################################

"cc-pod2-prod"
{
    $Port = 7003

    if ($Region -eq "e1")
    {
        $MIPList = @(
            "prod.dc11-36a.mips.infra.marcus.com",
            "prod.dc11-36b.mips.infra.marcus.com"
        )
    }
    elseif ($Region -eq "w2")
    {
        $MIPList = @(
            "prod.se3-36c.mips.infra.marcus.com",
            "prod.se3-36d.mips.infra.marcus.com"
        )
    }
}

###########################################################
# POD4 PROD
###########################################################

"cc-pod4-prod"
{
    $Port = 7004

    if ($Region -eq "e1")
    {
        $MIPList = @(
            "prod.dc11-36a.mips.infra.marcus.com",
            "prod.dc11-36b.mips.infra.marcus.com"
        )
    }
    elseif ($Region -eq "w2")
    {
        $MIPList = @(
            "prod.se3-36c.mips.infra.marcus.com",
            "prod.se3-36d.mips.infra.marcus.com"
        )
    }
}

###########################################################
# POD1 PROD
###########################################################

"cc-pod1-prod"
{
    $Port = 7009

    if ($Region -eq "e1")
    {
        $MIPList = @(
            "prod.dc11-3jj.mips.infra.marcus.com",
            "prod.dc11-3jk.mips.infra.marcus.com"
        )
    }
    elseif ($Region -eq "w2")
    {
        $MIPList = @(
            "prod.dc11-3jl.mips.infra.marcus.com",
            "prod.dc11-3jm.mips.infra.marcus.com"
        )
    }
}

                ###########################################################
                default
                {
                    throw "Unknown Environment Domain : $EnvironmentDomain"
                }

            }

            $Result = @()

            foreach ($MIP in $MIPList)
            {
                $Test = Test-NetConnection `
                    -ComputerName $MIP `
                    -Port $Port `
                    -WarningAction SilentlyContinue

                $Result += [PSCustomObject]@{

                    "MIP Name" = $MIP
                    "Port"     = $Port
                    "Status"   = $Test.TcpTestSucceeded

                }
            }

            return $Result

        }

        foreach ($Item in $Output)
        {
            $Results += [PSCustomObject]@{

                "Server Name" = $ComputerName
                "MIP Name"    = $Item."MIP Name"
                "Port"        = $Item.Port
                "Status"      = $Item.Status

            }
        }

    }
    catch
    {
        $Results += [PSCustomObject]@{

            "Server Name" = $ComputerName
            "MIP Name"    = "N/A"
            "Port"        = "-"
            "Status"      = "FAILED"

        }
    }
}
#######################################################################
# PART 3 - Generate HTML Report
#######################################################################

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

$ReportFolder = "C:\Temp"

if (!(Test-Path $ReportFolder))
{
    New-Item -ItemType Directory -Path $ReportFolder | Out-Null
}

$ReportPath = Join-Path $ReportFolder "MIP_Telnet_Report_$TimeStamp.html"

$SuccessCount = ($Results | Where-Object {$_.Status -eq $true}).Count
$FailedCount  = ($Results | Where-Object {$_.Status -ne $true}).Count
$TotalCount   = $Results.Count

$style = @"
<style>

body{
    font-family:Calibri;
    font-size:11pt;
    background:#F4F4F4;
}

h1{
    color:#003366;
}

table{
    border-collapse:collapse;
    width:100%;
    background:white;
}

th{
    background:#003366;
    color:white;
    padding:8px;
    border:1px solid black;
}

td{
    padding:6px;
    border:1px solid #BFBFBF;
}

.success{
    background:#C6EFCE;
}

.failed{
    background:#FFC7CE;
}

.summary{
    width:400px;
    margin-bottom:20px;
}

.summary td{
    font-weight:bold;
}

</style>
"@

$Rows = foreach($Row in $Results)
{

    if($Row.Status -eq $true)
    {
        $StatusText="SUCCESS"
        $Class="success"
    }
    else
    {
        $StatusText="FAILED"
        $Class="failed"
    }

@"
<tr class='$Class'>
<td>$($Row.'Server Name')</td>
<td>$($Row.'MIP Name')</td>
<td align='center'>$($Row.Port)</td>
<td align='center'>$StatusText</td>
</tr>
"@

}

$HTML = @"

<html>

<head>

<title>MIP Connectivity Report</title>

$style

</head>

<body>

<h1>MIP Connectivity Report</h1>

<b>Generated :</b> $(Get-Date)

<br><br>

<table class='summary'>

<tr>
<td>Total Tests</td>
<td>$TotalCount</td>
</tr>

<tr>
<td>Successful</td>
<td style='color:green'>$SuccessCount</td>
</tr>

<tr>
<td>Failed</td>
<td style='color:red'>$FailedCount</td>
</tr>

</table>

<table>

<tr>

<th>Server Name</th>

<th>MIP Server</th>

<th>Port</th>

<th>Status</th>

</tr>

$Rows

</table>

</body>

</html>

"@

$HTML | Out-File $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "Report Generated Successfully"
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host $ReportPath -ForegroundColor Yellow
Write-Host ""

Start-Process $ReportPath

#######################################################################
# END OF SCRIPT
#######################################################################