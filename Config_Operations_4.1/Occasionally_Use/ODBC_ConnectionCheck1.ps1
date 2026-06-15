######################################################################################################################
# ODBC Connection | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

Clear-Host
$Module = "ODBC-Connection-Status"
#$ServerTypes = 'bat'
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
$ThisServer = (Hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value,Pod:Tags[?Key=='pod']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()
$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]

if ($AWSVariables.Pod -eq $null) {
    if ($EnvironmentAttribution -eq "jazz") {
        $EnvironmentPod = $EnvironmentAttribution
    } else {
        $S3BucketsList = aws s3 ls
        if ($S3BucketsList -match "corecard-pod2-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod2"
        } elseif ($S3BucketsList -match "corecard-pod4-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod4"
        } elseif ($S3BucketsList -match "corecard-pod5-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod5"
        } elseif (($S3BucketsList -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($EnvironmentAttribution -eq "jazz")) {
            $EnvironmentPod = "jazz"
        }
    }
} else {
    $EnvironmentPod = $AWSVariables.Pod.ToLower()
}

$AllResults = @()
$ServerTypeCounts = @{}

foreach ($ServerType in $ServerTypes) {
    Write-Host "Server Type: $ServerType" -ForegroundColor DarkYellow

    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value, Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json

    $ServerTypeCounts[$ServerType] = $ServerList.Count
    $Option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

    foreach ($Server in $ServerList) {
    $ServerName = $Server.Name
    Write-Host "Checking Server: $ServerName" -ForegroundColor Magenta
    try {
        $CommandResult = Invoke-Command -ComputerName $ServerName -SessionOption $Option -ErrorAction Stop -ScriptBlock {
            $DBBCDrive = Get-OdbcDriver
            $ODBCDSN = Get-OdbcDsn
            $DBBCDriveCheck = if ($DBBCDrive) { "ODBC Installed" } else { $null }
            # Check if Server attribute contains either CCAPPLIST1 or CCAPPSQLAG1
            $ServerCheck = ($ODBCDSN.Attribute.Server -like "*CCAPPLIST1*") -or ($ODBCDSN.Attribute.Server -like "*CCAPPSQLAG1*")
            
            # Check if Description attribute contains either CCAPPLIST1 or CCSQLAG1
            $DescriptionCheck = ($ODBCDSN.Attribute.Description -like "*CCAPPLIST1*") -or ($ODBCDSN.Attribute.Description -like "*CCSQLAG1*")
            
            if (($DBBCDriveCheck -eq "ODBC Installed") -and
                ($ODBCDSN.Name -contains "LISTPLAT" -or $ODBCDSN.Name -contains "LISTRPT") -and
                ($ODBCDSN.Platform -eq "32-bit") -and
                ($ODBCDSN.DriverName -eq "ODBC Driver 17 for SQL Server") -and
                ($ODBCDSN.Attribute.MultiSubnetFailover -eq "Yes") -and
                $ServerCheck -and 
                $DescriptionCheck) {
                "PASSED"
            } else {
                "FAILED"
            }
        }
    } catch {
        $CommandResult = "Connection Failed: $($_.Exception.Message)"
    }
    $StatusColor = if ($CommandResult -eq "PASSED") { "Green" } else { "Red" }
    Write-Host "Status: $CommandResult" -ForegroundColor $StatusColor
    $AllResults += [PSCustomObject]@{
        'Server Type' = $ServerType
        'Server Name' = $ServerName
        'Status'      = $CommandResult
    }
}}

$HtmlFile = "C:\ODBCTest.html"
$HtmlContent = """
<html>
<head>
<title>ODBC Installation Status</title>
<style>
  body { font-family: Arial, sans-serif; }
  table { width: 100%; border-collapse: collapse; }
  th, td { border: 1px solid black; padding: 8px; text-align: left; }
  th { background-color: #FFA500; color: white; }
  .purple { color: purple; font-weight: bold; }
  .green { color: green; font-weight: bold; }
  .red { color: red; font-weight: bold; }
</style>
</head>
<body>
<h2>ODBC Connection Status</h2>
<table>
<tr><th>Server Type</th><th>Server Name</th><th>Status</th></tr>
"""

foreach ($Result in $AllResults) {
    $ColorClass = if ($Result.Status -eq "PASSED") { "green" } else { "red" }
    $HtmlContent += "<tr><td class='orange'>$($Result.'Server Type')</td><td class='purple'>$($Result.'Server Name')</td><td class='$ColorClass'>$($Result.Status)</td></tr>"
}

$HtmlContent += "</table></body></html>"
$HtmlContent | Out-File $HtmlFile
Start-Process $HtmlFile