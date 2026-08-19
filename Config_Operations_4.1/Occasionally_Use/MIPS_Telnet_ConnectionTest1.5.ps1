######################################################################################################################
# MIP Connectivity Test DEVELOPED BY:: Mahendra Dwivedi
# Version 2.0 | MIP Connectivity Test For Source And Sink Servers
# Date:: 17-August-2026
#=====================================================================================================================

Clear-Host

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                    MIP CONNECTIVITY TEST" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------------------------------------------------
# Step 1: Detect Current Server and AWS Region
# ---------------------------------------------------------------------------------------------------------------------

$ThisServer = (Hostname).ToLower()

if ($ThisServer -match 'e1') {

    $Region = "us-east-1"
    $ShortRegion = "e1"

}
elseif ($ThisServer -match 'w2') {

    $Region = "us-west-2"
    $ShortRegion = "w2"

}
else {

    Write-Host "Unable to determine AWS Region from server name: $ThisServer" -ForegroundColor Red
    Write-Host "Server name should contain e1 or w2." -ForegroundColor Yellow
    exit 1
}

Write-Host "Current Server : $ThisServer" -ForegroundColor Cyan
Write-Host "AWS Region     : $Region" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------------------------------------------------
# Step 2: MIP Environment Selection
# ---------------------------------------------------------------------------------------------------------------------

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                    SELECT MIP ENVIRONMENT" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Press 1  - POD1 PATUAT" -ForegroundColor Yellow
Write-Host "Press 2  - POD1 PATQA" -ForegroundColor Yellow
Write-Host "Press 3  - POD1 PROD EAST" -ForegroundColor Yellow
Write-Host "Press 4  - POD1 PROD WEST" -ForegroundColor Yellow
Write-Host "Press 5  - POD2 PATQA" -ForegroundColor Yellow
Write-Host "Press 6  - POD2 PATUAT" -ForegroundColor Yellow
Write-Host "Press 7  - POD2 PROD EAST" -ForegroundColor Yellow
Write-Host "Press 8  - POD2 PROD WEST" -ForegroundColor Yellow
Write-Host "Press 9  - POD4 PROD EAST" -ForegroundColor Yellow
Write-Host "Press 10 - POD4 PROD WEST" -ForegroundColor Yellow
Write-Host ""

do {

    $MIPChoice = Read-Host "Enter your choice (1-10)"

    $ValidChoice = $MIPChoice -match '^(10|[1-9])$'

    if (-not $ValidChoice) {

        Write-Host ""
        Write-Host "Invalid choice. Please select a number from 1 to 10." -ForegroundColor Red
        Write-Host ""
    }

}
until ($ValidChoice)

# ---------------------------------------------------------------------------------------------------------------------
# Step 3: Configure MIP Names and Ports Based on User Selection
# ---------------------------------------------------------------------------------------------------------------------

$MIPList = @()
$MIPEnvironment = ""

switch ([int]$MIPChoice) {

    1 {

        $MIPEnvironment = "POD1 PATUAT"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "patuat.dc11-3jj.mips.infra.marcus.com"
                "Port"     = 7034
            },
            [PSCustomObject]@{
                "MIP Name" = "patuat.dc11-3jk.mips.infra.marcus.com"
                "Port"     = 7036
            }
        )
    }

    2 {

        $MIPEnvironment = "POD1 PATQA"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "patqa.dc11-3jj.mips.infra.marcus.com"
                "Port"     = 7035
            },
            [PSCustomObject]@{
                "MIP Name" = "patqa.dc11-3jk.mips.infra.marcus.com"
                "Port"     = 7035
            }
        )
    }

    3 {

        $MIPEnvironment = "POD1 PROD EAST"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-3jj.mips.infra.marcus.com"
                "Port"     = 7009
            },
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-3jk.mips.infra.marcus.com"
                "Port"     = 7009
            }
        )
    }

    4 {

        $MIPEnvironment = "POD1 PROD WEST"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-3jl.mips.infra.marcus.com"
                "Port"     = 7009
            },
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-3jm.mips.infra.marcus.com"
                "Port"     = 7009
            }
        )
    }

    5 {

        $MIPEnvironment = "POD2 PATQA"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "patqa.dc11-36a.mips.infra.marcus.com"
                "Port"     = 7035
            },
            [PSCustomObject]@{
                "MIP Name" = "patqa.dc11-36b.mips.infra.marcus.com"
                "Port"     = 7035
            }
        )
    }

    6 {

        $MIPEnvironment = "POD2 PATUAT"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "patuat.dc11-36a.mips.infra.marcus.com"
                "Port"     = 7034
            },
            [PSCustomObject]@{
                "MIP Name" = "patuat.dc11-36b.mips.infra.marcus.com"
                "Port"     = 7034
            }
        )
    }

    7 {

        $MIPEnvironment = "POD2 PROD EAST"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-36a.mips.infra.marcus.com"
                "Port"     = 7003
            },
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-36b.mips.infra.marcus.com"
                "Port"     = 7003
            }
        )
    }

    8 {

        $MIPEnvironment = "POD2 PROD WEST"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "prod.se3-36c.mips.infra.marcus.com"
                "Port"     = 7003
            },
            [PSCustomObject]@{
                "MIP Name" = "prod.se3-36d.mips.infra.marcus.com"
                "Port"     = 7003
            }
        )
    }

    9 {

        $MIPEnvironment = "POD4 PROD EAST"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-36a.mips.infra.marcus.com"
                "Port"     = 7004
            },
            [PSCustomObject]@{
                "MIP Name" = "prod.dc11-36b.mips.infra.marcus.com"
                "Port"     = 7004
            }
        )
    }

    10 {

        $MIPEnvironment = "POD4 PROD WEST"

        $MIPList = @(
            [PSCustomObject]@{
                "MIP Name" = "prod.se3-36c.mips.infra.marcus.com"
                "Port"     = 7004
            },
            [PSCustomObject]@{
                "MIP Name" = "prod.se3-36d.mips.infra.marcus.com"
                "Port"     = 7004
            }
        )
    }
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 4: Display Selected MIP Configuration
# ---------------------------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "                  SELECTED MIP CONFIGURATION" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Environment : $MIPEnvironment" -ForegroundColor Cyan
Write-Host ""

$MIPList | Format-Table `
    @{Label = "MIP Name"; Expression = { $_."MIP Name" } },
    @{Label = "Port"; Expression = { $_.Port } } `
    -AutoSize

Write-Host ""

$ConfirmMIP = Read-Host "Press Enter to continue or type N to select another MIP environment"

if ($ConfirmMIP -match '^[Nn]$') {

    Write-Host ""
    Write-Host "Please run the script again and select the required environment." -ForegroundColor Yellow
    exit
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 5: Get AWS Information for Current Server
# ---------------------------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "Getting AWS information for current server..." -ForegroundColor Cyan

try {

    $AWSVariables = (
        aws ec2 describe-instances `
            --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" `
            --filters "Name=instance-state-name,Values=running" `
            "Name=tag:Name,Values=$ThisServer" `
            "Name=availability-zone,Values=*" `
            --region $Region |
            ConvertFrom-Json
    )

}
catch {

    Write-Host "Failed to retrieve AWS information." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if ($null -eq $AWSVariables) {

    Write-Host "No AWS information found for $ThisServer." -ForegroundColor Red
    exit 1
}

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]

Write-Host "Environment : $EnvironmentName" -ForegroundColor Cyan
Write-Host "Stack       : $EnvironmentStack" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------------------------------------------------
# Step 6: Get Available Availability Zones
# ---------------------------------------------------------------------------------------------------------------------

$AvailabilityZonesDefaultServerType = "tnp"

Write-Host "Getting available Availability Zones..." -ForegroundColor Cyan

try {

    $AvailabilityZones = @(
        (
            aws ec2 describe-instances `
                --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" `
                --filters "Name=instance-state-name,Values=running" `
                "Name=tag:Name,Values=*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*" `
                "Name=availability-zone,Values=*" `
                --region $Region |
                ConvertFrom-Json
        ).AvailabilityZone |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        } |
        Sort-Object -Unique
    )

}
catch {

    Write-Host "Failed to retrieve Availability Zones." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if ($AvailabilityZones.Count -eq 0) {

    Write-Host "No Availability Zones found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Available Zones" -ForegroundColor Green
Write-Host "---------------" -ForegroundColor Green

$AvailabilityZones | ForEach-Object {
    Write-Host $_
}

Write-Host ""

# ---------------------------------------------------------------------------------------------------------------------
# Step 7: Ask User for Availability Zone
# ---------------------------------------------------------------------------------------------------------------------

$AvailabilityZone = Read-Host "Enter Availability Zone or * for ALL"

if ([string]::IsNullOrWhiteSpace($AvailabilityZone)) {

    Write-Host "Availability Zone cannot be blank." -ForegroundColor Red
    exit 1
}

if (
    $AvailabilityZone -ne "*" -and
    $AvailabilityZones -notcontains $AvailabilityZone
) {

    Write-Host ""
    Write-Host "Invalid Availability Zone: $AvailabilityZone" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 8: Find Source and Sink Servers
# ---------------------------------------------------------------------------------------------------------------------

$ServerTypeList = @(
    "src",
    "snk"
)

$ServerList = @()

foreach ($ServerType in $ServerTypeList) {

    Write-Host ""
    Write-Host "Searching $ServerType Servers..." -ForegroundColor Yellow

    try {

        $CurrentServerList = @(
            (
                aws ec2 describe-instances `
                    --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" `
                    --filters "Name=instance-state-name,Values=running" `
                    "Name=tag:Name,Values=*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*" `
                    "Name=availability-zone,Values=*" `
                    --region $Region |
                    ConvertFrom-Json
            ) |
            Select-Object `
                @{n = "Name"; e = { $_.Name } },
                @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } },
                @{n = "Serial"; e = {
                    if ($_.Name -match '(\d+)$') {
                        [int]$matches[1]
                    }
                    else {
                        999999
                    }
                } }
        )

        if ($AvailabilityZone -ne "*") {

            $CurrentServerList = @(
                $CurrentServerList |
                Where-Object {
                    $_.AvailabilityZone -eq $AvailabilityZone
                }
            )
        }

        $CurrentServerList = @(
            $CurrentServerList |
            Sort-Object Serial, Name
        )

        $ServerList += $CurrentServerList

    }
    catch {

        Write-Host "Error while searching $ServerType servers." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 9: Validate Server List
# ---------------------------------------------------------------------------------------------------------------------

$ServerList = @(
    $ServerList |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_.Name)
    } |
    Sort-Object Name -Unique
)

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "                       MATCHING SERVERS" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

if ($ServerList.Count -eq 0) {

    Write-Host "No matching servers found." -ForegroundColor Red
    Write-Host ""
    exit 1
}

$ServerList |
    Select-Object Name, AvailabilityZone |
    Format-Table -AutoSize

Write-Host ""

$ServerNames = @(
    $ServerList |
    Select-Object -ExpandProperty Name
)

$ConfirmServers = Read-Host "Please verify the server list and press Enter to continue or type N to stop"

if ($ConfirmServers -match '^[Nn]$') {

    Write-Host "Script stopped by user." -ForegroundColor Yellow
    exit
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 10: MIP Connectivity Test
# ---------------------------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                  STARTING MIP CONNECTIVITY TEST" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

$Results = @()

foreach ($ComputerName in $ServerNames) {

    Write-Host "Testing Server: $ComputerName" -ForegroundColor Yellow

    try {

        $option = New-PSSessionOption -ProxyAccessType NoProxyServer

        # Convert MIP objects to arrays for remote session
        $RemoteMIPNames = @(
            $MIPList |
            ForEach-Object {
                $_."MIP Name"
            }
        )

        $RemoteMIPPorts = @(
            $MIPList |
            ForEach-Object {
                $_.Port
            }
        )

        $Output = Invoke-Command `
            -ComputerName $ComputerName `
            -SessionOption $option `
            -ArgumentList $RemoteMIPNames, $RemoteMIPPorts `
            -ErrorAction Stop `
            -ScriptBlock {

                param (
                    [string[]]$MIPNames,
                    [int[]]$MIPPorts
                )

                $RemoteResults = @()

                for ($i = 0; $i -lt $MIPNames.Count; $i++) {

                    $MIPName = $MIPNames[$i]
                    $MIPPort = $MIPPorts[$i]

                    try {

                        Write-Output "Testing $MIPName on port $MIPPort"

                        $Test = Test-NetConnection `
                            -ComputerName $MIPName `
                            -Port $MIPPort `
                            -WarningAction SilentlyContinue `
                            -ErrorAction SilentlyContinue

                        $RemoteResults += [PSCustomObject]@{
                            "MIP Name" = $MIPName
                            "Port"     = $MIPPort
                            "Status"   = [bool]$Test.TcpTestSucceeded
                        }

                    }
                    catch {

                        $RemoteResults += [PSCustomObject]@{
                            "MIP Name" = $MIPName
                            "Port"     = $MIPPort
                            "Status"   = $false
                        }
                    }
                }

                return $RemoteResults
            }

        foreach ($Item in $Output) {

            # Ignore informational strings returned by Write-Output
            if ($null -eq $Item.PSObject.Properties["MIP Name"]) {
                continue
            }

            $StatusText = if ($Item.Status -eq $true) {
                "SUCCESS"
            }
            else {
                "FAILED"
            }

            $Results += [PSCustomObject]@{
                "Server Name" = $ComputerName
                "MIP Name"    = $Item."MIP Name"
                "Port"        = $Item.Port
                "Status"      = $StatusText
            }

            if ($Item.Status -eq $true) {

                Write-Host "  $($Item.'MIP Name') : $($Item.Port) - SUCCESS" -ForegroundColor Green

            }
            else {

                Write-Host "  $($Item.'MIP Name') : $($Item.Port) - FAILED" -ForegroundColor Red
            }
        }

    }
    catch {

        Write-Host "  Failed to connect to server $ComputerName" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red

        foreach ($MIP in $MIPList) {

            $Results += [PSCustomObject]@{
                "Server Name" = $ComputerName
                "MIP Name"    = $MIP."MIP Name"
                "Port"        = $MIP.Port
                "Status"      = "FAILED"
            }
        }
    }

    Write-Host ""
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 11: Display Final Results
# ---------------------------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "                         TEST RESULTS" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

if ($Results.Count -gt 0) {

    $Results |
        Format-Table `
            "Server Name",
            "MIP Name",
            "Port",
            "Status" `
            -AutoSize

}
else {

    Write-Host "No test results generated." -ForegroundColor Red
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 12: Generate HTML Report
# ---------------------------------------------------------------------------------------------------------------------

$DateTime = Get-Date -Format "yyyyMMdd_HHmmss"

$ReportPath = "$env:TEMP\MIP_Telnet_Report_$DateTime.html"

$style = @"
<style>

body {
    font-family: Arial, Helvetica, sans-serif;
    margin: 20px;
    background-color: #f5f5f5;
}

h2 {
    color: #333333;
}

.info {
    background-color: white;
    padding: 15px;
    margin-bottom: 20px;
    border: 1px solid #cccccc;
}

table {
    border-collapse: collapse;
    width: 100%;
    background-color: white;
}

th {
    background-color: #333333;
    color: white;
    padding: 8px;
    border: 1px solid #999999;
    text-align: left;
}

td {
    padding: 8px;
    border: 1px solid #999999;
    text-align: left;
}

.success {
    background-color: #c6efce;
    color: #006100;
    font-weight: bold;
}

.failed {
    background-color: #ffc7ce;
    color: #9c0006;
    font-weight: bold;
}

</style>
"@

# ---------------------------------------------------------------------------------------------------------------------
# Step 13: Build MIP Configuration Table
# ---------------------------------------------------------------------------------------------------------------------

$MIPConfigurationRows = foreach ($MIP in $MIPList) {

    @"
<tr>
    <td>$($MIP.'MIP Name')</td>
    <td>$($MIP.Port)</td>
</tr>
"@
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 14: Build Test Result Rows
# ---------------------------------------------------------------------------------------------------------------------

$ResultRows = foreach ($R in $Results) {

    if ($R.Status -eq "SUCCESS") {
        $StatusClass = "success"
    }
    else {
        $StatusClass = "failed"
    }

    @"
<tr>
    <td>$($R.'Server Name')</td>
    <td>$($R.'MIP Name')</td>
    <td>$($R.Port)</td>
    <td class="$StatusClass">$($R.Status)</td>
</tr>
"@
}

# ---------------------------------------------------------------------------------------------------------------------
# Step 15: Generate HTML
# ---------------------------------------------------------------------------------------------------------------------

$html = @"
<html>

<head>

<title>MIP Connectivity Report</title>

$style

</head>

<body>

<h2>MIP Connectivity Report</h2>

<div class="info">

<table>

<tr>
    <th>Parameter</th>
    <th>Value</th>
</tr>

<tr>
    <td>Test Server</td>
    <td>$ThisServer</td>
</tr>

<tr>
    <td>AWS Region</td>
    <td>$Region</td>
</tr>

<tr>
    <td>Environment</td>
    <td>$EnvironmentName</td>
</tr>

<tr>
    <td>Stack</td>
    <td>$EnvironmentStack</td>
</tr>

<tr>
    <td>Availability Zone</td>
    <td>$AvailabilityZone</td>
</tr>

<tr>
    <td>MIP Environment Selected</td>
    <td>$MIPEnvironment</td>
</tr>

<tr>
    <td>Report Generated</td>
    <td>$(Get-Date)</td>
</tr>

</table>

</div>

<h3>MIP Configuration</h3>

<table>

<tr>
    <th>MIP Name</th>
    <th>Port</th>
</tr>

$MIPConfigurationRows

</table>

<br>

<h3>MIP Connectivity Test Results</h3>

<table>

<tr>
    <th>Server Name</th>
    <th>MIP Name</th>
    <th>Port</th>
    <th>Status</th>
</tr>

$ResultRows

</table>

</body>

</html>
"@

# ---------------------------------------------------------------------------------------------------------------------
# Step 16: Save Report
# ---------------------------------------------------------------------------------------------------------------------

$html | Out-File `
    -FilePath $ReportPath `
    -Encoding UTF8

# ---------------------------------------------------------------------------------------------------------------------
# Step 17: Open Report
# ---------------------------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                  REPORT GENERATED SUCCESSFULLY" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Selected MIP Environment : $MIPEnvironment" -ForegroundColor Green
Write-Host "Report Path              : $ReportPath" -ForegroundColor Green
Write-Host ""

if (Test-Path $ReportPath) {

    Start-Process $ReportPath

}
else {

    Write-Host "Unable to find generated report." -ForegroundColor Red
}

Write-Host ""
Write-Host "MIP Connectivity Test Completed." -ForegroundColor Green
Write-Host ""
