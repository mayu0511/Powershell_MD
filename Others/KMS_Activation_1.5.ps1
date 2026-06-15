######################################################################################################################
# KMS Activation DEVELOPED BY: Mahendra Dwivedi
# Version 1.5  Date: 08-Jun-2026

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
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()


$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

#$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$ServerTypeList = @('kms')
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
                9999  # fallback if no number found
            }
        }
    } | Sort-Object -Property serial, Name)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}


$ServerList = $ServerList | Where-Object { $_.Name } | Select-Object -ExpandProperty Name
Read-Host "Please verify the server list and press Enter to continue or Stop the script"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$ValidationResults = @()
# ------------------ Step 3: Perform remote checks -----------
foreach ($Server in $ServerList) {
    Write-Host "Checking server: $Server" -ForegroundColor Cyan

    $result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
        $output = @{}
 $LogFolder = "C:\Temp"

    if (!(Test-Path $LogFolder))
    {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }

    $TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogFile = Join-Path $LogFolder "KMS_Activation_$TimeStamp.log"

    function Write-Log
    {
        param([string]$Message)

        $Entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') : $Message"

        Write-Host $Entry
        Add-Content -Path $LogFile -Value $Entry
    }

    try
    {
        Write-Log "Starting KMS Activation"

        $Params = @{
            UseDefaultCredentials = $true
            UseBasicParsing       = $true
        }

        $BaseUrl = "https://localhost:8081"

        # Master Key1
        $r1 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK1/1" `
            -Method POST `
            -Body @{
                OrgK1  = "plat"
                OrgNum = "1"
            } `
            @Params

        Write-Log "Master Key1 Status Code : $($r1.StatusCode)"

        # Master Key2
        $r2 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK2/1" `
            -Method POST `
            -Body @{
                OrgK2  = "corecard"
                OrgNum = "1"
            } `
            @Params

        Write-Log "Master Key2 Status Code : $($r2.StatusCode)"

        # Org2 Key1
        $r3 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK1/2" `
            -Method POST `
            -Body @{
                OrgK1  = "plat"
                OrgNum = "2"
            } `
            @Params

        Write-Log "Org2 Key1 Status Code : $($r3.StatusCode)"

        # Org2 Key2
        $r4 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK2/2" `
            -Method POST `
            -Body @{
                OrgK2  = "corecard"
                OrgNum = "2"
            } `
            @Params

        Write-Log "Org2 Key2 Status Code : $($r4.StatusCode)"

        if (
            $r1.StatusCode -eq 200 -and
            $r2.StatusCode -eq 200 -and
            $r3.StatusCode -eq 200 -and
            $r4.StatusCode -eq 200
        )
        {
            Write-Log "SUCCESS - KMS Activation Completed Successfully"
        }
        else
        {
            Write-Log "FAILURE - One or More Requests Failed"
        }
    }
    catch
    {
        Write-Log "ERROR : $($_.Exception.Message)"
    }

    Write-Log "Script Completed"
}


}