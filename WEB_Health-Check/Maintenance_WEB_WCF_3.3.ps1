######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
$line = '========================================================='
do {
   
    Clear-Host
    Write-Host $line
    Write-Host '************** Modules **************'
    Write-Host $line
    Write-Host ' 1', ' - ', 'WEB Targets Health Check'
    Write-Host ' 2', ' - ', 'WEB Targets Maintenance'
    Write-Host ' 3', ' - ', 'WEB Targets Maintenance Disable'
    Write-Host ' 4', ' - ', 'WCF Targets Health Check'
    Write-Host ' 5', ' - ', 'WCF Targets Maintenance'
    Write-Host ' 6', ' - ', 'WCF Targets Maintenance Disable'
    Write-Host ' 0', ' - ', 'Quit'
    Write-Host $line
    $input = Read-Host 'Select'
    Switch ($input) {0 {exit}


'1'

{
Clear-Host
write-host -foregroundcolor green '==============================WEB Targets Health Check=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "Current Status of WEB Targets "
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

$ServerTypeList = @('web')
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

foreach ($Server in $ServerList) {
    try {
        $Result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
            Import-Module -Name WebAdministration

            
            $IP = (Get-WebBinding "Services" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = $IP.Substring(0,$IP.Length-5)

            class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
                [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                             [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                             [System.Net.WebRequest] $c,
                                             [int] $d) {
                    return $true
                }
            }
            [System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

             try {
            $response = Invoke-WebRequest -Uri "https://$IP/HealthWebServerApp/api/server/health" -Method GET -UseDefaultCredentials -ErrorAction Stop
            
    if ($response.StatusCode -eq 200) {
        $healthStatus = $response.Content
        Write-Output "$healthStatus"
    } else {
        Write-Output "Unhealthy (Status Code: $($response.StatusCode))"
    }
} catch {
    Write-Output "Unhealthy (Error: $($_.Exception.Message))"
}
        }
        $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = $Result -replace '\s+', ' '
        }
    }
    catch {
       $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = "Error: $_"
        }
    }
}
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
write-host -foregroundcolor green '==============================WEB Targets Maintenance=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "WEB Targets Maintenance"
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
Write-host "* doesn't support anymore"
Break
}

$AvailabilityZone

$ServerTypeList = @('web')
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

foreach ($Server in $ServerList) {
    try {
        $Result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
            Import-Module -Name WebAdministration

            $IP = (Get-WebBinding "Services" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = (Get-WebBinding "CoreIssue" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = $IP.Substring(0,$IP.Length-5)

            class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
                [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                             [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                             [System.Net.WebRequest] $c,
                                             [int] $d) {
                    return $true
                }
            }
            [System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

             try {
             $response = Invoke-WebRequest -Uri "https://$IP/HealthWebServerApp/api/server/maintenance/1" -Method GET -UseDefaultCredentials -ErrorAction Stop
            
    if ($response.StatusCode -eq 200) {
        $healthStatus = $response.Content
        Write-Output "$healthStatus"
    } else {
        Write-Output "Unhealthy (Status Code: $($response.StatusCode))"
    }
} catch {
    Write-Output "Unhealthy (Error: $($_.Exception.Message))"
}
        }
        $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = $Result -replace '\s+', ' '
        }
    }
    catch {
       $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = "Error: $_"
        }
    }
}
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
write-host -foregroundcolor green '==============================WEB Targets Maintenance Disable=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "WEB Targets Maintenance Disable"
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
Write-host "* doesn't support anymore"
Break
}

$AvailabilityZone

$ServerTypeList = @('web')
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

foreach ($Server in $ServerList) {
    try {
        $Result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
            Import-Module -Name WebAdministration

            
            $IP = (Get-WebBinding "Services" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = (Get-WebBinding "CoreIssue" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = $IP.Substring(0,$IP.Length-5)

            class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
                [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                             [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                             [System.Net.WebRequest] $c,
                                             [int] $d) {
                    return $true
                }
            }
            [System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

           try {
             $response = Invoke-WebRequest -Uri "https://$IP/HealthWebServerApp/api/server/maintenance/0" -Method GET -UseDefaultCredentials -ErrorAction Stop
        
  
    if ($response.StatusCode -eq 200) {
        $healthStatus = $response.Content
        Write-Output "$healthStatus"
    } else {
        Write-Output "Unhealthy (Status Code: $($response.StatusCode))"
    }
} catch {
    Write-Output "Unhealthy (Error: $($_.Exception.Message))"
}
        }
        $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = $Result -replace '\s+', ' '
        }
    }
    catch {
       $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = "Error: $_"
        }
    }
}
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
write-host -foregroundcolor green '==============================WCF Targets Health Check=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "Current Status of WCF Targets "
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

$ServerTypeList = @('wcf')
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

foreach ($Server in $ServerList) {
    try {
        $Result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
            Import-Module -Name WebAdministration

            
            $IP = (Get-WebBinding "Webserver" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = $IP.Substring(0,$IP.Length-5)

            class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
                [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                             [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                             [System.Net.WebRequest] $c,
                                             [int] $d) {
                    return $true
                }
            }
            [System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

             try {
            $response = Invoke-WebRequest -Uri "https://$IP/HealthWCFApp/api/server/health" -Method GET -UseDefaultCredentials -ErrorAction Stop
            
    if ($response.StatusCode -eq 200) {
        $healthStatus = $response.Content
        Write-Output "$healthStatus"
    } else {
        Write-Output "Unhealthy (Status Code: $($response.StatusCode))"
    }
} catch {
    Write-Output "Unhealthy (Error: $($_.Exception.Message))"
}
        }
        $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = $Result -replace '\s+', ' '
        }
    }
    catch {
       $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = "Error: $_"
        }
    }
}
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
write-host -foregroundcolor green '==============================WCF Targets Maintenance=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "WCF Targets Maintenance"
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
Write-host "* doesn't support anymore"
Break
}

$AvailabilityZone

$ServerTypeList = @('wcf')
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

foreach ($Server in $ServerList) {
    try {
        $Result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
            Import-Module -Name WebAdministration

            
            $IP = (Get-WebBinding "Webserver" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = $IP.Substring(0,$IP.Length-5)

            class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
                [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                             [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                             [System.Net.WebRequest] $c,
                                             [int] $d) {
                    return $true
                }
            }
            [System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

             try {
            $response = Invoke-WebRequest -Uri "https://$IP/HealthWCFApp/api/server/maintenance/1" -Method GET -UseDefaultCredentials -ErrorAction Stop
                       
    if ($response.StatusCode -eq 200) {
        $healthStatus = $response.Content
        Write-Output "$healthStatus"
    } else {
        Write-Output "Unhealthy (Status Code: $($response.StatusCode))"
    }
} catch {
    Write-Output "Unhealthy (Error: $($_.Exception.Message))"
}
        }
        $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = $Result -replace '\s+', ' '
        }
    }
    catch {
       $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = "Error: $_"
        }
    }
}
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
write-host -foregroundcolor green '==============================WEB Targets Maintenance Disable=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "WCF Targets Maintenance Disable"
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
Write-host "* doesn't support anymore"
Break
}

$AvailabilityZone

$ServerTypeList = @('wcf')
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
$Results = @()

foreach ($Server in $ServerList) {
    try {
        $Result = Invoke-Command -ComputerName $Server -SessionOption $option -ScriptBlock {
            Import-Module -Name WebAdministration

            
            $IP = (Get-WebBinding "Webserver" |Select-Object -ExpandProperty bindingInformation|Select-Object -Last 1)
            $IP = $IP.Substring(0,$IP.Length-5)

            class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
                [bool] CheckValidationResult([System.Net.ServicePoint] $a,
                                             [System.Security.Cryptography.X509Certificates.X509Certificate] $b,
                                             [System.Net.WebRequest] $c,
                                             [int] $d) {
                    return $true
                }
            }
            [System.Net.ServicePointManager]::CertificatePolicy = [TrustAllCertsPolicy]::new()
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

           try {
            $response = Invoke-WebRequest -Uri "https://$IP/HealthWCFApp/api/server/maintenance/0" -Method GET -UseDefaultCredentials -ErrorAction Stop
             
    if ($response.StatusCode -eq 200) {
        $healthStatus = $response.Content
        Write-Output "$healthStatus"
    } else {
        Write-Output "Unhealthy (Status Code: $($response.StatusCode))"
    }
} catch {
    Write-Output "Unhealthy (Error: $($_.Exception.Message))"
}
        }
        $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = $Result -replace '\s+', ' '
        }
    }
    catch {
       $Results += [PSCustomObject]@{
            'Server Name' = $Server
            'Status'      = "Error: $_"
        }
    }
}
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
write-host -foregroundcolor green '==============================WEB Targets Maitinance Disabled=============================='
""
write-host -foregroundcolor green ======================================================================
Write-Host "WEB Targets Maitinance Disabled"
write-host -foregroundcolor green ======================================================================
""
$Servers = Read-Host "Please Specify the Path and Name of Servers List File"
$ServerListFile = $Servers
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($Servers in $ServerList) {
Write-host -foregroundcolor Darkcyan "========================================="
Write-Host Fetching Current Support Cipers on $Servers...
$option = New-PSSessionOption -ProxyAccessType NoProxyServer
Invoke-Command -ComputerName $Servers -SessionOption $option -ErrorAction inquire -ScriptBlock {
$HostName = HostName
    $TLSCipers = Get-TlsCipherSuite | Format-Table -Property CipherSuite, Exchange, Name
    $TLSCipers 
}
}
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