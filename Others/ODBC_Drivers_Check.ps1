######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 31-Jan-2025
#=====================================================================================================================
Clear-Host
$ThisServer = (Hostname).ToLower()

# Set region and short region based on server
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

# Fetch AWS instance details
$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables[0].Environment.ToLower()
Write-Host "Environment Name: $EnvironmentName"

$EnvironmentAttribution = $AWSVariables[0].Attribution.ToLower()
Write-Host "Environment Attribution: $EnvironmentAttribution"

# POD Selection based on Environment Attribution
if ($EnvironmentAttribution -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2"
    Write-Host "2. COOKIE - POD3 (POD4)"
    
    $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
    
    if ($PODNumberSelected -eq "1") {
        $PODName = "pod2"
    } elseif ($PODNumberSelected -eq "2") {
        $PODName = "pod4"
    } else {
        Write-Host "Invalid POD Name. Exiting..."
        exit
    }
} elseif ($EnvironmentAttribution -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attribution. Exiting..."
    exit
}

# Get stack info
$EnvironmentStack = ($AWSVariables[0].Stack.ToLower())[0]
Write-Host "Environment Stack: $EnvironmentStack"

# Fetch availability zones for servers
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique
$AvailabilityZones

# Set server types to check
$ServerTypeList = @('rps','rpd','bat','svc','iss','aut','tnp','awf','snk','src')
$ServerList = @()

# Fetch the servers
ForEach ($ServerType in $ServerTypeList) {
    Write-Host "Checking servers of type: $ServerType"
    
    $ServerList += (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial)
}

# Check if any server was found
if ($ServerList.Count -eq 0) {
    Write-Host "No servers found matching the criteria. Exiting..."
    exit
}

$ServerListNames = $ServerList.Name
#Write-Host "Servers found: $ServerListNames"
Read-Host "Please verify the server list and press enter to continue or press Ctrl+C to stop the script"

# Invoke commands on servers to check ODBC drivers
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$Result = @()

ForEach ($Server in $ServerListNames) {
    try {
        Write-Host "Connecting to $Server"
        $session = New-PSSession -ComputerName $Server -SessionOption $option
        $driverStatus = Invoke-Command -Session $session -ScriptBlock {
            $odbcDrivers = @(
                @{ Name = "ODBC Driver 17 for SQL Server"; Path = "C:\\Windows\\System32\\msodbcsql17.dll" },
                @{ Name = "ODBC Driver 13 for SQL Server"; Path = "C:\\Windows\\System32\\msodbcsql13.dll" },
                @{ Name = "SQL Server Native Client 11.0"; Path = "C:\\Windows\\System32\\sqlncli11.dll" }
            )

            # Check for installed and missing ODBC drivers
            $driverStatus = [ordered]@{}
            foreach ($driver in $odbcDrivers) {
                $driverExists = Test-Path -PathType Leaf $driver.Path
                $driverStatus[$driver.Name] = if ($driverExists) { "Installed" } else { "Not Installed" }
            }

            # Return results
            return [PSCustomObject]@{
                'Server Name'                        = $env:COMPUTERNAME
                'ODBC Driver 17 for SQL Server'      = $driverStatus["ODBC Driver 17 for SQL Server"]
                'ODBC Driver 13 for SQL Server'      = $driverStatus["ODBC Driver 13 for SQL Server"]
                'SQL Server Native Client 11.0'      = $driverStatus["SQL Server Native Client 11.0"]
            }
        }
        $Result += $driverStatus
        Remove-PSSession -Session $session
    } catch {
        Write-Host "Failed to create session for $Server" -ForegroundColor Red
    }
}

# Generate HTML report
$HtmlFile = "C:\\ODBCInstallation.html"
$Result | ConvertTo-Html -Property 'Server Name', 'ODBC Driver 17 for SQL Server', 'ODBC Driver 13 for SQL Server', 'SQL Server Native Client 11.0' -Title 'ODBC Installation Status' | Out-File $HtmlFile
Start-Process $HtmlFile