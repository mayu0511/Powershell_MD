######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 5-March-2025
$line = '========================================================='
do {
   
    Clear-Host
    Write-Host $line
    Write-Host '************** Modules **************'
    Write-Host $line
    Write-Host ' 1', ' - ', 'SVC Targets Health Check'
    Write-Host ' 2', ' - ', 'SVC Targets Maintenance'
    Write-Host ' 3', ' - ', 'SVC Targets Maintenance Disable'
    Write-Host ' 4', ' - ', 'ISS Targets Health Check'
    Write-Host ' 5', ' - ', 'ISS Targets Maintenance'
    Write-Host ' 6', ' - ', 'ISS Targets Maintenance Disable'
    Write-Host ' 7', ' - ', 'AUT Targets Health Check'
    Write-Host ' 8', ' - ', 'AUT Targets Maintenance'
    Write-Host ' 9', ' - ', 'AUT Targets Maintenance Disable'
    Write-Host ' 0', ' - ', 'Quit'
    Write-Host $line
    $input = Read-Host 'Select'
    Switch ($input) {0 {exit}


'1'
{
Clear-Host
write-host -foregroundcolor green '==============================SVC Targets Health Check=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "Current Status of SVC Targets "
write-host -foregroundcolor green ======================================================================
""

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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"



$AvailabilityZone

$ServerTypeList = @('svc')
$ServerType = $Null
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    Break Script
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            $response = Invoke-WebRequest -Uri "http://$($Server):7011/healthy" -Headers $headers -Method Get
             
   if ($response.StatusCode -eq '200') {
            $healthStatus = $response
            $discretion = 'SVC Healthy'
        } else {
            $healthStatus = $response
            $discretion = "Maintenance Disable: $response"
        }
    } catch {
        $healthStatus = "UnHealthy"
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize	

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}

#End

'2'
{
Clear-Host
write-host -foregroundcolor green '==============================SVC Targets Maintenance=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "SVC Targets Maintenance"
write-host -foregroundcolor green ======================================================================
""
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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
    Write-Host "'*' doesn't support anymore"
    Break
}

$AvailabilityZone

$ServerTypeList = @('svc')
$ServerType = $Null
$ServerList = @()
$GetEnvironment = $Env:UserDNSDomain
If ($GetEnvironment -eq "DEV.AD.CC-POD2.INFRA.MARCUS.COM"){
$SecretObject = "DEV/app-rw-secret"
} elseif ($GetEnvironment -eq "QA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "QA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATQA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATQA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATUAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATUAT/app-rw-secret"

} elseif ($GetEnvironment -eq "UAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "UAT/app-rw-secret"

} elseif ($GetEnvironment -eq "PROD.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PROD/app-rw-secret"

} elseif ($GetEnvironment -eq "PERF.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PERF/app-rw-secret"

} elseif ($GetEnvironment -eq "DEV.AD.CC-JAZZ.INFRA.MARCUS.COM") {
$SecretObject = "DEV/app-rw-secret"


} elseif ($GetEnvironment -eq "QA.AD.CC-JAZZ.INFRA.MARCUS.COM") {
$SecretObject = "QA/app-rw-secret"

} elseif ($GetEnvironment -eq "UAT2.AD.CC-JAZZ.INFRA.MARCUS.COM") {
$SecretObject = "UAT2/app-rw-secret"

} elseif ($GetEnvironment -eq "PROD.AD.CC-JAZZ.INFRA.MARCUS.COM") {
$SecretObject = "PROD/app-rw-secret"
}
Write-Output $GetEnvironment
$SecretObj = (Get-SECSecretValue -SecretId $SecretObject)
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$username = $Secret.username
#$username = "mahendra.dwivedi"
$pair = "$($username):"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encodedCredentials"
    }

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
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            # $response = Invoke-RestMethod -Uri "'http://$($Server.Name)" + ":7011/MaintenanceSet?mode=1' -Headers $headers -Method Get"
            $response = Invoke-RestMethod -Uri "http://$($Server):7011/MaintenanceSet?mode=1" -Headers $headers -Method Get
             
    if ($response -eq 'OK') {
            $healthStatus = $response
            $discretion = 'Maintenance Enable'
        } else {
            $healthStatus = $response
            $discretion = "Unexpected response: $response"
        }
    } catch {
        $healthStatus = $response
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}

#End

'3'
{
Clear-Host
write-host -foregroundcolor green '==============================SVC Targets Maintenance Disabled=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "SVC Targets Maintenance Disabled"
write-host -foregroundcolor green ======================================================================
""
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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
    Write-Host "'*' doesn't support anymore"
    Break
}

$AvailabilityZone

$ServerTypeList = @('svc')
$ServerType = $Null
$ServerList = @()
$GetEnvironment = $Env:UserDNSDomain
If ($GetEnvironment -eq "DEV.AD.CC-POD2.INFRA.MARCUS.COM"){
$SecretObject = "DEV/app-rw-secret"
} elseif ($GetEnvironment -eq "QA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "QA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATQA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATQA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATUAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATUAT/app-rw-secret"

} elseif ($GetEnvironment -eq "UAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "UAT/app-rw-secret"

} elseif ($GetEnvironment -eq "PROD.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PROD/app-rw-secret"

} elseif ($GetEnvironment -eq "PERF.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PERF/app-rw-secret"
}

Write-Output $GetEnvironment
$SecretObj = (Get-SECSecretValue -SecretId $SecretObject)
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$username = $Secret.username
#$username = "mahendra.dwivedi"
$pair = "$($username):"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encodedCredentials"
    }

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
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            # $response = Invoke-RestMethod -Uri "'http://$($Server.Name)" + ":7011/MaintenanceSet?mode=1' -Headers $headers -Method Get"
            $response = Invoke-RestMethod -Uri "http://$($Server):7011/MaintenanceSet?mode=0" -Headers $headers -Method Get
             
    if ($response -eq 'OK') {
            $healthStatus = $response
            $discretion = 'Maintenance Disable'
        } else {
            $healthStatus = $response
            $discretion = "Unexpected response: $response"
        }
    } catch {
        $healthStatus = $response
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize
write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}

#End

'4'
{
Clear-Host
write-host -foregroundcolor green '==============================ISS Targets Health Check=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "Current Status of ISS Targets "
write-host -foregroundcolor green ======================================================================
""

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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"



$AvailabilityZone

$ServerTypeList = @('iss')
$ServerType = $Null
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    Break Script
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            $response = Invoke-WebRequest -Uri "http://$($Server):7012/healthy" -Headers $headers -Method Get
             
   if ($response.StatusCode -eq '200') {
            $healthStatus = $response
            $discretion = 'ISS Healthy'
        } else {
            $healthStatus = $response
            $discretion = "Maintenance Disable: $response"
        }
    } catch {
        $healthStatus = "UnHealthy"
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize		

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}

#END

'5'
{
Clear-Host
write-host -foregroundcolor green '==============================ISS Targets Mainitnance============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "ISS Targets Mainitnance "
write-host -foregroundcolor green ======================================================================
""

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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
    Write-Host "'*' doesn't support anymore"
    Break
}

$AvailabilityZone

$ServerTypeList = @('iss')
$ServerType = $Null
$ServerList = @()
$GetEnvironment = $Env:UserDNSDomain
If ($GetEnvironment -eq "DEV.AD.CC-POD2.INFRA.MARCUS.COM"){
$SecretObject = "DEV/app-rw-secret"
} elseif ($GetEnvironment -eq "QA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "QA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATQA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATQA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATUAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATUAT/app-rw-secret"

} elseif ($GetEnvironment -eq "UAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "UAT/app-rw-secret"

} elseif ($GetEnvironment -eq "PROD.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PROD/app-rw-secret"

} elseif ($GetEnvironment -eq "PERF.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PERF/app-rw-secret"
}

Write-Output $GetEnvironment
$SecretObj = (Get-SECSecretValue -SecretId $SecretObject)
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$username = $Secret.username
#$username = "mahendra.dwivedi"
$pair = "$($username):"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encodedCredentials"
    }

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
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            # $response = Invoke-RestMethod -Uri "'http://$($Server.Name)" + ":7011/MaintenanceSet?mode=1' -Headers $headers -Method Get"
            $response = Invoke-RestMethod -Uri "http://$($Server):7012/MaintenanceSet?mode=1" -Headers $headers -Method Get
             
    if ($response -eq 'OK') {
            $healthStatus = $response
            $discretion = 'Maintenance Enable'
        } else {
            $healthStatus = $response
            $discretion = "Unexpected response: $response"
        }
    } catch {
        $healthStatus = $response
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}
#END

'6'
{
Clear-Host
write-host -foregroundcolor green '==============================ISS Targets Mainitnance Disable=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "ISS Targets Mainitnance Disable"
write-host -foregroundcolor green ======================================================================
""
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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
    Write-Host "'*' doesn't support anymore"
    Break
}

$AvailabilityZone

$ServerTypeList = @('iss')
$ServerType = $Null
$ServerList = @()
$GetEnvironment = $Env:UserDNSDomain
If ($GetEnvironment -eq "DEV.AD.CC-POD2.INFRA.MARCUS.COM"){
$SecretObject = "DEV/app-rw-secret"
} elseif ($GetEnvironment -eq "QA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "QA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATQA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATQA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATUAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATUAT/app-rw-secret"

} elseif ($GetEnvironment -eq "UAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "UAT/app-rw-secret"

} elseif ($GetEnvironment -eq "PROD.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PROD/app-rw-secret"

} elseif ($GetEnvironment -eq "PERF.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PERF/app-rw-secret"
}

Write-Output $GetEnvironment
$SecretObj = (Get-SECSecretValue -SecretId $SecretObject)
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$username = $Secret.username
#$username = "mahendra.dwivedi"
$pair = "$($username):"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encodedCredentials"
    }

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
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            # $response = Invoke-RestMethod -Uri "'http://$($Server.Name)" + ":7011/MaintenanceSet?mode=1' -Headers $headers -Method Get"
            $response = Invoke-RestMethod -Uri "http://$($Server):7012/MaintenanceSet?mode=0" -Headers $headers -Method Get
             
    if ($response -eq 'OK') {
            $healthStatus = $response
            $discretion = 'Maintenance Disable'
        } else {
            $healthStatus = $response
            $discretion = "Unexpected response: $response"
        }
    } catch {
        $healthStatus = $response
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize	

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}
#END

'7'
{
Clear-Host
write-host -foregroundcolor green '==============================AUT Targets Health Check=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "Current Status of AUT Targets "
write-host -foregroundcolor green ======================================================================
""

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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"



$AvailabilityZone

$ServerTypeList = @('aut')
$ServerType = $Null
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    Break Script
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            $response = Invoke-WebRequest -Uri "http://$($Server):7013/healthy" -Headers $headers -Method Get
             
   if ($response.StatusCode -eq '200') {
            $healthStatus = $response
            $discretion = 'SVC Healthy'
        } else {
            $healthStatus = $response
            $discretion = "Maintenance Disable: $response"
        }
    } catch {
        $healthStatus = "UnHealthy"
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize	

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}

#End

'8'
{
Clear-Host
write-host -foregroundcolor green '==============================AUT Targets Maintenance Enable=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "AUT Targets Maintenance Enable "
write-host -foregroundcolor green ======================================================================
""

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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
    Write-Host "'*' doesn't support anymore"
    Break
}

$AvailabilityZone

$ServerTypeList = @('aut')
$ServerType = $Null
$ServerList = @()
$GetEnvironment = $Env:UserDNSDomain
If ($GetEnvironment -eq "DEV.AD.CC-POD2.INFRA.MARCUS.COM"){
$SecretObject = "DEV/app-rw-secret"
} elseif ($GetEnvironment -eq "QA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "QA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATQA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATQA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATUAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATUAT/app-rw-secret"

} elseif ($GetEnvironment -eq "UAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "UAT/app-rw-secret"

} elseif ($GetEnvironment -eq "PROD.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PROD/app-rw-secret"

} elseif ($GetEnvironment -eq "PERF.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PERF/app-rw-secret"
}

Write-Output $GetEnvironment
$SecretObj = (Get-SECSecretValue -SecretId $SecretObject)
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$username = $Secret.username
#$username = "mahendra.dwivedi"
$pair = "$($username):"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encodedCredentials"
    }

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
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            # $response = Invoke-RestMethod -Uri "'http://$($Server.Name)" + ":7011/MaintenanceSet?mode=1' -Headers $headers -Method Get"
            $response = Invoke-RestMethod -Uri "http://$($Server):7013/MaintenanceSet?mode=1" -Headers $headers -Method Get
             
    if ($response -eq 'OK') {
            $healthStatus = $response
            $discretion = 'Maintenance Enable'
        } else {
            $healthStatus = $response
            $discretion = "Unexpected response: $response"
        }
    } catch {
        $healthStatus = $response
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize	

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}

'9'
{
Clear-Host
write-host -foregroundcolor green '==============================AUT Targets Maintenance Disable=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "AUT Targets Maintenance Disable "
write-host -foregroundcolor green ======================================================================
""

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
    
    $PODName = "pod2"
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

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
    Write-Host "'*' doesn't support anymore"
    Break
}

$AvailabilityZone

$ServerTypeList = @('aut')
$ServerType = $Null
$ServerList = @()
$GetEnvironment = $Env:UserDNSDomain
If ($GetEnvironment -eq "DEV.AD.CC-POD2.INFRA.MARCUS.COM"){
$SecretObject = "DEV/app-rw-secret"
} elseif ($GetEnvironment -eq "QA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "QA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATQA.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATQA/app-rw-secret"

} elseif ($GetEnvironment -eq "PATUAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PATUAT/app-rw-secret"

} elseif ($GetEnvironment -eq "UAT.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "UAT/app-rw-secret"

} elseif ($GetEnvironment -eq "PROD.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PROD/app-rw-secret"

} elseif ($GetEnvironment -eq "PERF.AD.CC-POD2.INFRA.MARCUS.COM") {
$SecretObject = "PERF/app-rw-secret"
}

Write-Output $GetEnvironment
$SecretObj = (Get-SECSecretValue -SecretId $SecretObject)
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$username = $Secret.username
#$username = "mahendra.dwivedi"
$pair = "$($username):"
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encodedCredentials"
    }

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
$Results = @()
$response = $NULL

foreach ($Server in $ServerList) {
     
           try {
                       
            # $response = Invoke-RestMethod -Uri "'http://$($Server.Name)" + ":7011/MaintenanceSet?mode=1' -Headers $headers -Method Get"
            $response = Invoke-RestMethod -Uri "http://$($Server):7013/MaintenanceSet?mode=0" -Headers $headers -Method Get
             
    if ($response -eq 'OK') {
            $healthStatus = $response
            $discretion = 'Maintenance Enable'
        } else {
            $healthStatus = $response
            $discretion = "Unexpected response: $response"
        }
    } catch {
        $healthStatus = $response
        $discretion = "Error: $($_.Exception.Message)"
    }

    # Collect result
    $Results += [PSCustomObject]@{
        'Server Name' = $server
        'Status'      = $healthStatus
        'Discretion'  = $discretion
    }
}

# Output results in a formatted table
$Results | Format-Table -AutoSize	

write-host -foregroundcolor green '===================================Completed==================================='
write-host -foregroundcolor green 'Press any key to return to Main Menu'
[void][System.Console]::ReadKey($true)
cls
}

#End
default {
            Write-Host -foregroundcolor Red 'Incorrect Option, Please enter the correct number!!'
            [void][System.Console]::ReadKey($true)
        }
	
    }
     Start-Sleep -Seconds 1.5
} 
while ($input -ne '0')
Stop-Transcript
pause