######################################################################################################################

# KMS Service Start -Stop -Restart  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 31-July-2026

######################################################################################################################

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


$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack

$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZone = $NULL
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$AvailabilityZone

$ServerTypeList = @('kms')
$ServerType = $Null
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

#Read-Host "Press enter to see the Server List"
if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    Break Script
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

# Prompt for action
do {
    $Action = Read-Host @"
Select the action to perform:
1. Stop App Pool
2. Start App Pool
3. Restart App Pool
Enter your choice (1/2/3)
"@

    switch ($Action) {
        "1" { $Operation = "Stop"; break }
        "2" { $Operation = "Start"; break }
        "3" { $Operation = "Restart"; break }
        default {
            Write-Host "Invalid selection. Please enter 1, 2, or 3." -ForegroundColor Red
        }
    }
} while (-not $Operation)


$Results = Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction Continue -ArgumentList $Operation -ScriptBlock {

    param($Operation)

    $ServiceName = "sppsvc"   # KMS Service

    try {

        switch ($Operation) {

            "Stop" {
                Stop-Service -Name $ServiceName -Force
            }

            "Start" {
                Start-Service -Name $ServiceName
            }

            "Restart" {
                Restart-Service -Name $ServiceName -Force
            }
        }

        Start-Sleep -Seconds 2

        $Status = (Get-Service -Name $ServiceName).Status

        [PSCustomObject]@{
            ServerName = $env:COMPUTERNAME
            ServiceName = $ServiceName
            Status = $Status
        }
    }
    catch {
        [PSCustomObject]@{
            ServerName = $env:COMPUTERNAME
            ServiceName = $ServiceName
            Status = "FAILED - $($_.Exception.Message)"
        }
    }
}
# Create report folder
$ReportFolder = "C:\Temp"

if (!(Test-Path $ReportFolder)) {
    New-Item -Path $ReportFolder -ItemType Directory -Force | Out-Null
}

$DateTime = Get-Date -Format "yyyyMMdd_HHmmss"

$ReportFile = Join-Path $ReportFolder "KMS-Service-Status_$DateTime.html"

$HtmlHeader = @"
<html>
<head>
<title>KMS Service Status Report</title>
<style>
body {
    font-family: Arial;
    font-size: 10pt;
}
table {
    border-collapse: collapse;
    width: 80%;
}
th {
    background-color: #4472C4;
    color: white;
    border: 1px solid black;
    padding: 8px;
}
td {
    border: 1px solid black;
    padding: 8px;
}
tr:nth-child(even) {
    background-color: #F2F2F2;
}
</style>
</head>
<body>
<h2>KMS Service Status Report</h2>
<p>Generated: $(Get-Date)</p>
"@

$HtmlFooter = @"
</body>
</html>
"@

$Results |
    Sort-Object ServerName |
    ConvertTo-Html `
    -Property ServerName,ServiceName,Status `
    -Head $HtmlHeader `
    -PostContent $HtmlFooter |
    Out-File $ReportFile

Write-Host ""
Write-Host "Report Generated: $ReportFile" -ForegroundColor Green

Invoke-Item $ReportFile