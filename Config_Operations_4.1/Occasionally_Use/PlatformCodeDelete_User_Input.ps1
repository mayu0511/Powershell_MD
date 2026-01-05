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
$ServerTypeList = @('bat','svc','iss','aut','src','snk','tnp','awf')
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
Write-Host "`nSelect the deletion condition:"
Write-Host "1. Delete all files inside a folder (CC-Runtime)"
Write-Host "2. Delete a specific file (e.g., shmem memory file)"
Write-Host "3. Delete a folder entirely (SpecificFile folder)"
$ConditionSelected = Read-Host "Enter your choice (1, 2, or 3)"

# Initialize variables
$FolderPath = ""
$SpecificFilePath = ""
$FolderToDelete = ""

# Get input paths based on condition
switch ($ConditionSelected) {
    1 {
        $FolderPath = Read-Host "Enter full folder path to delete all files (e.g., D:\CC_runtime\*)"
    }
    2 {
        $SpecificFilePath = Read-Host "Enter full file path to delete (e.g., C:\corecard_services\shmem.bin)"
    }
    3 {
        $FolderToDelete = Read-Host "Enter full folder path to delete (e.g., D:\BKP)"
    }
    default {
        Write-Host "Invalid choice. Exiting..."
        exit
    }
}

# Loop through all servers and perform deletion
foreach ($server in $ServerList) {
    try {
        $DeletionResult = Invoke-Command -ComputerName $server -SessionOption $option -ScriptBlock {
            param($Condition, $FolderPath, $SpecificFilePath, $FolderToDelete)
            
            switch ($Condition) {
                1 {
                    if (Test-Path $FolderPath) {
                        Get-ChildItem -Path $FolderPath -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                        return "Deleted"
                    } else {
                        return "FolderNotFound"
                    }
                }
                2 {
                    if (Test-Path $SpecificFilePath) {
                        Remove-Item -Path $SpecificFilePath -Force -ErrorAction SilentlyContinue
                        return "Deleted"
                    } else {
                        return "FileNotFound"
                    }
                }
                3 {
                    if (Test-Path $FolderToDelete) {
                        Remove-Item -Path $FolderToDelete -Recurse -Force -ErrorAction SilentlyContinue
                        return "Deleted"
                    } else {
                        return "FolderNotFound"
                    }
                }
                default {
                    return "InvalidCondition"
                }
            }
        } -ArgumentList $ConditionSelected, $FolderPath, $SpecificFilePath, $FolderToDelete -ErrorAction Stop

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


# -------------------- Generate HTML Report --------------------
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
    $statusClass = $entry.Status -replace '\s+', ''
    $HtmlReport += "<tr><td>$($entry.ServerName)</td><td class='$statusClass'>$($entry.Status)</td></tr>`n"
}

$HtmlReport += @"
    </table>
</body>
</html>
"@

# Save the report
$ReportPath = "C:\Temp\FileDeletionReport.html"
$HtmlReport | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "`n✅ HTML Report generated at: $ReportPath"
Start-Process $ReportPath
