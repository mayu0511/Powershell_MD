######################################################################################################################
# KMS Servers  Recovery Setting | Updated by : Mahendra Dwivedi
# Version 1.1 | Date:: 20-May-2026
#======================================================================================================================

Clear-Host

$ThisServer = (Hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
}
elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}
else {
    Write-Host "Unable to determine AWS region"
    exit
}

# Get current server details
$AWSVariables = (
    aws ec2 describe-instances `
    --query "Reservations[*].Instances[*].{
        AvailabilityZone:Placement.AvailabilityZone,
        IpAddress:PrivateIpAddress,
        Type:InstanceType,
        Name:Tags[?Key=='Name']|[0].Value,
        Status:State.Name,
        Environment:Tags[?Key=='environment']|[0].Value,
        Stack:Tags[?Key=='stack']|[0].Value,
        Attribution:Tags[?Key=='attribution']|[0].Value
    }" `
    --filters "Name=instance-state-name,Values=running" `
              "Name=tag:Name,Values=$ThisServer" `
    --region $Region | ConvertFrom-Json
)

if (-not $AWSVariables) {
    Write-Host "No AWS instance details found"
    exit
}

$EnvironmentName = if ($AWSVariables.Environment) {
    $AWSVariables.Environment.ToLower()
} else {
    ""
}

$EnvironmentAttribution = if ($AWSVariables.Attribution) {
    $AWSVariables.Attribution.ToLower()
} else {
    ""
}

$EnvironmentStack = if ($AWSVariables.Stack) {
    $AWSVariables.Stack.ToLower()[0]
} else {
    ""
}

Write-Host "Environment      : $EnvironmentName"
Write-Host "Attribution      : $EnvironmentAttribution"
Write-Host "EnvironmentStack : $EnvironmentStack"

# Get Availability Zones
$AvailabilityZonesDefaultServerType = "tnp"

$AvailabilityZones = (
    (
        aws ec2 describe-instances `
        --query "Reservations[*].Instances[*].{
            AvailabilityZone:Placement.AvailabilityZone
        }" `
        --filters "Name=instance-state-name,Values=running" `
                  "Name=tag:Name,Values=*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*" `
        --region $Region | ConvertFrom-Json
    ).AvailabilityZone
) | Sort-Object -Unique

Write-Host "`nAvailable Zones:"
$AvailabilityZones

$AvailabilityZone = Read-Host "Enter Availability Zone or * for all"

# Build server list
$ServerTypeList = @('kms')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {

    Write-Host "Searching for server type: $ServerType"

    $Servers = (
        aws ec2 describe-instances `
        --query "Reservations[*].Instances[*].{
            AvailabilityZone:Placement.AvailabilityZone,
            Name:Tags[?Key=='Name']|[0].Value
        }" `
        --filters "Name=instance-state-name,Values=running" `
                  "Name=tag:Name,Values=*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*" `
                  "Name=availability-zone,Values=$AvailabilityZone" `
        --region $Region | ConvertFrom-Json
    )

    $ServerList += $Servers | Select-Object `
        @{n="Name";e={$_.Name}},
        @{n="AvailabilityZone";e={$_.AvailabilityZone}},
        @{n="serial";e={
            [double](($_.Name -split "$EnvironmentName$EnvironmentStack")[1])
        }} | Sort-Object serial
}

if (-not $ServerList) {
    Write-Host "No servers found"
    exit
}

$ServerList | Format-Table -AutoSize

Read-Host "Verify server list and press ENTER to continue"

$ServerNames = $ServerList.Name

$OutputFile = "C:\temp\log1248788.txt"

"Service Failure Actions Check - $(Get-Date)" | Out-File $OutputFile

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

Invoke-Command -ComputerName $ServerNames `
    -SessionOption $option `
    -ErrorAction Continue `
    -ScriptBlock {

    $serviceName = "KMSService"
    $failureActions = "restart/60000/restart/60000/restart/60000"

    sc.exe failure $serviceName reset=0 actions=$failureActions | Out-Null

    $Result = sc.exe qfailure $serviceName

    if ($Result -match "RESET PERIOD \(in seconds\)\s+:\s+0") {

        "[$env:COMPUTERNAME] PASSED"

    } else {

        "[$env:COMPUTERNAME] FAILED"

    }

} | Out-File $OutputFile -Append

Write-Host "`nCheck completed. Results saved in:"
Write-Host $OutputFile