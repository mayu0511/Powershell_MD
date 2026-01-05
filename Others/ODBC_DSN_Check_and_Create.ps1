Clear-Host
$Module = "Processes-Status"
$ServerTypes = 'bat'#, 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = (Hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution,Pod:Tags[?Key=='pod']|[0].Value,Status:State.pod}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName
$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon
$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack

if (($AWSVarialbes.Pod) -eq $NULL) {
    if ($Environmentattributon -eq "jazz") {
        $Environmentpod = $Environmentattributon
    } else {
        $S3bucketslist = $NULL
        $S3bucketslist = aws s3 ls
        if ($S3bucketslist -match "corecard-pod2-$EnvironmentName-$Region-config-files") {
            $Environmentpod = "pod2"
        } elseif ($S3bucketslist -match "corecard-pod4-$EnvironmentName-$Region-config-files") {
            $Environmentpod = "pod4"
        } elseif ($S3bucketslist -match "corecard-pod5-$EnvironmentName-$Region-config-files") {
            $Environmentpod = "pod5"
        } elseif (($S3bucketslist -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($Environmentattributon -eq "jazz")) {
            $Environmentpod = "jazz"
        }
    }
} else {
    $Environmentpod = $AWSVarialbes.Pod.ToLower()
}
$Environmentpod

$Result = @()
ForEach ($ServerType in $ServerTypes) {
    $ServerList = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)
    
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
    $ServerList | ForEach-Object {
        $Server = $_
        $ResultServerType = Invoke-Command -ComputerName $Server.Name -SessionOption $option -ErrorAction Inquire -ScriptBlock {
            # Ensure Microsoft.PowerShell.Management module is loaded
            if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.Management)) {
                Install-Module -Name Microsoft.PowerShell.Management -Force
            }
            Import-Module Microsoft.PowerShell.Management

            $DBBCDrive = Get-OdbcDriver
            $ODBCDSN = Get-OdbcDsn

            $DBBCDrivecheck = $null

            if ($DBBCDrive -ne $null) {
                $DBBCDrivecheck = "ODBC Installed"
            }

            $ODBCStatus = @{}
            $ODBCStatus.ComputerName = $env:COMPUTERNAME
            if (($DBBCDrivecheck -eq "ODBC Installed") -and ($ODBCDSN.Name -contains "LISTPLAT") -or ($ODBCDSN.Name -contains "LISTRPT") -and ($ODBCDSN.Platform -eq "32-bit") -and ($ODBCDSN.DriverName -eq "ODBC Driver 17 for SQL Server") -and ($ODBCDSN.Attribute.MultiSubnetFailover -eq "Yes") -and ($ODBCDSN.Attribute.Server -eq "CCAPPLIST1") -and ($ODBCDSN.Attribute.Description -eq "CCAPPLIST1")) {
                $ODBCStatus.Status = "Configured"
                $ODBCStatus.ODBCName = $ODBCDSN.Name
                $ODBCStatus.Server = $ODBCDSN.Attribute.Server
                $ODBCStatus.Description = $ODBCDSN.Attribute.Description
            } else {
                $ODBCStatus.Status = "Not Configured"
                $ODBCStatus.ODBCName = $ODBCDSN.Name
                $ODBCStatus.Server = $ODBCDSN.Attribute.Server
                $ODBCStatus.Description = $ODBCDSN.Attribute.Description

                # Create ODBC DSN if not found
                #New-OdbcDsn -Name "LISTPLAT" -DriverName "ODBC Driver 17 for SQL Server" -DsnType "System" -Platform "32-bit" -SetPropertyValue @("Server=CCAPPLIST1", "Description=CCAPPLIST1", "MultiSubnetFailover=Yes")
                #New-OdbcDsn -Name "LISTRPT" -DriverName "ODBC Driver 17 for SQL Server" -DsnType "System" -Platform "32-bit" -SetPropertyValue @("Server=CCAPPLIST1", "Description=CCAPPLIST1", "MultiSubnetFailover=Yes")

                add-OdbcDsn -Name "LISTPLAT" -DriverName "ODBC Driver 17 for SQL Server" -DsnType "System" -Platform "32-bit" -SetPropertyValue @("Server=CCAPPLIST1", "Description=CCAPPLIST1", "MultiSubnetFailover=Yes")
                add-OdbcDsn -Name "LISTRPT" -DriverName "ODBC Driver 17 for SQL Server" -DsnType "System" -Platform "32-bit" -SetPropertyValue @("Server=CCAPPLIST1", "Description=CCAPPLIST1", "MultiSubnetFailover=Yes")
                
                $ODBCStatus.Status = "Configured Now"
            }
            return $ODBCStatus
        }
        $Result += $ResultServerType
    }
}

# Convert the result to HTML
$Html = $Result | ConvertTo-Html -Property ComputerName, Status, ODBCName, Server, Description -Head "<style>table {width: 100%; border-collapse: collapse;} th, td {border: 1px solid black; padding: 8px; text-align: left;} th {background-color: #f2f2f2;}</style>" -Title "ODBC Status Report" | Out-String

# Save the HTML to a file
$Html | Out-File -FilePath "C:\tools\ODBCStatusReport.html"

# Open the HTML file in the default browser
Start-Process -FilePath "C:\tools\ODBCStatusReport.html"
