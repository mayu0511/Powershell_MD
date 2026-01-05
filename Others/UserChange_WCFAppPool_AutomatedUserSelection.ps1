######################################################################################################################
# User Change for WCF App Pool | DEVELOPED BY:: Mahendra Dwivedi
# Latest Update by :: Netra Chettri | Date:: 05-Nov-2025
# Version 1.1 | Updated with multiple user selection | Date:: 05-Nov-2025
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

$AvailabilityZone = Read-Host "Type Availability Zone of your choice $AvailabilityZones or * for all zones"
$AvailabilityZone

$ServerTypeList = @('wcf')
$ServerType = $Null
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | 
    Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    Break Script
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

# =====================================================================================================================
# Added Section: User Selection for WCF App Pool
# =====================================================================================================================
Clear-Host
Write-Host "Select App Pool user for WCF:"
Write-Host "1. cc-pod2-prod\gmsa-app-svc$"
Write-Host "2. cc-pod2-prod\gmsa-app-upg$"
Write-Host "3. cc-pod4-prod\gmsa-app-svc$"
Write-Host "4. cc-pod4-prod\gmsa-app-upg$"

$userChoice = Read-Host "Enter your choice (1-4)"

switch ($userChoice) {
    '1' { $userName = "cc-pod2-prod\gmsa-app-svc$" }
    '2' { $userName = "cc-pod2-prod\gmsa-app-upg$" }
    '3' { $userName = "cc-pod4-prod\gmsa-app-svc$" }
    '4' { $userName = "cc-pod4-prod\gmsa-app-upg$" }
    Default {
        Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
        Break Script
    }
}

$password = ""  # Not required for GMSA accounts
# =====================================================================================================================

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$Results = @()

foreach ($computername in $ServerList) {
    try {
        $result = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            param($userName)
            Import-Module WebAdministration
            Set-ItemProperty "IIS:\AppPools\WCF" -name processModel -value @{ userName = $userName; password = ""; identitytype = 3 }

            [PSCustomObject]@{
                ServerName = $env:COMPUTERNAME
                UserName   = $userName
            }
        } -ArgumentList $userName

        $Results += $result
    } catch {
        $Results += [PSCustomObject]@{
            ServerName = $computername
            UserName   = "FAILED: $_"
        }
    }
}

$Results | Select-Object ServerName, UserName | Format-Table -AutoSize
