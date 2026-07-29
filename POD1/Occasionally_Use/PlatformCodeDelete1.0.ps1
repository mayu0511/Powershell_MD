######################################################################################################################
# PlatFormCode Delete  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 04-April-2025
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

$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique
$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
Write-host "* doesn't support anymore"
Break
}

$AvailabilityZone

#$ServerTypeList = @('bat')
$ServerTypeList = @('svc','iss','aut','src','snk','tnp','awf')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { double[1] } } | Sort-Object -Property serial)
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$ResultList = @()

# Prompt user to select the deletion condition
Write-Host "Select the deletion condition:"
Write-Host "1. Delete CC-Runtime and shmem Memory file"
Write-Host "2. Delete a SpecificFile folder"
$ConditionSelected = Read-Host "Enter your choice (1 or 2)"

foreach ($server in $ServerList) {
    try {
        $DeletionResult = Invoke-Command -ComputerName $server -SessionOption $option -ScriptBlock {
            param($Condition, $CCRuntimePath, $ShmemFilePath, $FolderToDelete)
            
            switch ($Condition) {
                1 {
                    # Combined Condition: Delete CC-Runtime folder and shmem file
                    if (Test-Path $CCRuntimePath) {
                        Get-ChildItem -Path $CCRuntimePath | Remove-Item -Recurse -Force
                    }
                    if (Test-Path $ShmemFilePath) {
                        Remove-Item -Path $ShmemFilePath -Force
                    }

                    if ((Test-Path $CCRuntimePath) -or (Test-Path $ShmemFilePath)) {
                        return "Not Deleted"
                    } else {
                        return "Deleted"
                    }
                }
                2 {
                    # Delete a folder
                    Remove-Item -Path $FolderToDelete -Recurse -Force
                    if (Test-Path $FolderToDelete) {
                        return "Not Deleted"
                    } else {
                        return "Deleted"
                    }
                }
                default {
                    return "Invalid Condition"
                }
            }
        } -ArgumentList $ConditionSelected, "D:\CC_runtime\*", "C:\corecard_services\shmem.bin", "D:\BKP\1" -ErrorAction Stop

        $ResultList += [PSCustomObject]@{
            ServerName = $server
            Status     = $DeletionResult
        }
    }
    catch {
        $ResultList += [PSCustomObject]@{
            ServerName = $server
            Status     = "Error: $($_.Exception.Message)"
        }
    }
}


# HTML generation
$HtmlReport = @"
<html>
<head>
    <style>
        body { font-family: Arial; }
        table { border-collapse: collapse; width: 80%; margin: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .Deleted { color: green; font-weight: bold; }
        .Error, .NotDeleted, .FolderNotFound { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h2>File Deletion Report</h2>
    <table>
        <tr>
            <th>Server Name</th>
            <th>Status</th>
        </tr>
"@

foreach ($entry in $ResultList) {
    $statusClass = $entry.Status -replace '\s+', ''  # remove spaces for class compatibility
    $HtmlReport += "<tr><td>$($entry.ServerName)</td><td class='$statusClass'>$($entry.Status)</td></tr>`n"
}

$HtmlReport += @"
    </table>
</body>
</html>
"@

# Save the HTML report
$ReportPath = "C:\temp\FileDeletionReport.html"
$HtmlReport | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "HTML Report generated at: $ReportPath"

# Open the HTML report
Start-Process "C:\temp\FileDeletionReport.html"
