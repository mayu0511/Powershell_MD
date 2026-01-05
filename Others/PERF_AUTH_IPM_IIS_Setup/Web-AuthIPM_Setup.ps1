######################################################################################################################
# Web Server: Auth and IPM Setup-IIS Application Site and App-pool Creation  | DEVELOPED BY:: Netra Chettri
# Version 1.1 | Date:: 1-DEC-2025
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

# Create log folder
$LogFolder = "C:\Temp"
if (!(Test-Path $LogFolder)) { New-Item -Path $LogFolder -ItemType Directory -Force }

$Global:ResultList = @()   # Store results for HTML

$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

if ($EnvironmentAttribution -eq "cookie") {
    Clear-Host
    Write-Host "1. COOKIE - POD2"
    Write-Host "2. COOKIE - POD3 (POD4)"
    
    $PODNumberSelected = Read-Host "Enter your choice (1 or 2)"
    
    if ($PODNumberSelected -eq "1") { $PODName = "pod2" }
    elseif ($PODNumberSelected -eq "2") { $PODName = "pod4" }
    else { Write-Host "Invalid POD Name. Exiting..."; exit }
} elseif ($EnvironmentAttribution -eq "jazz") {
    $PODName = "jazz"
} else {
    Write-Host "Invalid Environment Attribution. Exiting..."
    exit
}

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"

$AvailabilityZones = (
    aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone}" `
    --filters "Name=instance-state-name,Values=running" `
             "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" `
    --region $Region | ConvertFrom-Json
).AvailabilityZone | Get-Unique

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all"

$ServerTypeList = @('web')
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "ServerType - $ServerType"

    $ServerList += (
        aws ec2 describe-instances `
        --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}" `
        --filters "Name=instance-state-name,Values=running" `
                 "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" `
                 "Name=availability-zone,Values='$AvailabilityZone'" `
        --region $Region | ConvertFrom-Json
    )
}

$ServerList | Out-Host

if ($ServerList -eq $NULL) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name | Sort-Object -Unique

if (-not $ServerList) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

Write-Host "`nFinal Server List:"
$ServerList
Read-Host "Please verify the server list and press enter to continue"

# ============================================
# IIS DEPLOYMENT - ONLY AuthAndIPMAutomationAPI
# ============================================

$AppName  = "AuthAndIPMAutomationAPI"
$AppPath  = "D:\WebServer\Services\AuthAndIPMAutomationAPI"
$SiteName = "Services"

$userName = "cc-pod2-perf\gmsa-web-svc$"
$password = ""

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

foreach ($computername in $ServerList) {

    $LogFile = "$LogFolder\IISDeploy_$computername.log"
    "===== LOG START: $(Get-Date) =====" | Out-File $LogFile -Append

    Write-Host "Processing server: $computername" -ForegroundColor Cyan

    $results = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Continue -ScriptBlock {

        param($AppName, $AppPath, $SiteName, $userName, $password)

        Import-Module WebAdministration

        $result = [PSCustomObject]@{
            Server  = $env:COMPUTERNAME
            AppName = $AppName
            AppPool = $AppName
            Path    = $AppPath
            Status  = "Failed"
        }

        try {
            # Create App Pool
            New-WebAppPool -Name $AppName -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty "IIS:\AppPools\$AppName" -Name processModel -Value @{ userName = $userName; password = $password; identitytype = 3 } | Out-Null
            Set-ItemProperty "IIS:\AppPools\$AppName" -Name "processModel.loadUserProfile" -Value "True" | Out-Null
            Set-ItemProperty "IIS:\AppPools\$AppName" -Name "managedRuntimeVersion" -Value "" | Out-Null

            # Create Application
            New-WebApplication -Name $AppName `
                               -Site $SiteName `
                               -PhysicalPath $AppPath `
                               -ApplicationPool $AppName `
                               -ErrorAction SilentlyContinue | Out-Null

            # Disable Anonymous Username
            Set-WebConfigurationProperty `
                -Filter "/system.webServer/security/authentication/anonymousAuthentication" `
                -PSPath "IIS:\" `
                -Location "$SiteName/$AppName" `
                -Name userName `
                -Value "" | Out-Null

            $result.Status = "Success"

        } catch {
            $result.Status = "Failed"
        }

        return $result

    } -ArgumentList $AppName, $AppPath, $SiteName, $userName, $password

    $Global:ResultList += $results

    "$($(Get-Date)) - SERVER: $($results.Server)  APP: $($results.AppName)  STATUS: $($results.Status)" | Out-File $LogFile -Append

    "===== LOG END =====`n" | Out-File $LogFile -Append
}

# ============================================
# HTML REPORT SECTION
# ============================================

$ReportFile = "C:\Temp\WEB_Auth_IPM_IIS_Report-$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$HtmlHeader = @"
<style>
body { font-family: Arial, sans-serif; margin: 20px; }
h2 { font-size: 26px; font-weight: bold; color: #0046ad; margin-bottom: 10px; }
table { border-collapse: collapse; width: 100%; margin-top: 10px; font-size: 15px; }
th { background-color: #003999; color: white; padding: 12px; text-align: left; border: 1px solid #cccccc; font-weight: bold; }
td { padding: 14px; border: 1px solid #cccccc; height: 38px; }
.Success { background-color: #d4edda !important; color: #155724; font-weight: bold; text-align: left; }
.Failed { background-color: #f8d7da !important; color: #721c24; font-weight: bold; text-align: left; }
.col-server { width: 20%; }
.col-app    { width: 15%; }
.col-pool   { width: 15%; }
.col-path   { width: 35%; }
.col-status { width: 15%; }
</style>
<h2>Web Server: Auth and IPM Setup-IIS Application Site and App-pool Creation</h2>
"@

# Filter out blank rows
$FilteredResults = $Global:ResultList |
    Where-Object { $_.AppName -and $_.Path } |
    Sort-Object Server, AppName -Unique

$HtmlRows = ""
foreach ($item in $FilteredResults) {
    $statusClass = if ($item.Status -eq "Success") { "Success" } else { "Failed" }

    $HtmlRows += @"
<tr>
    <td class='col-server'>$($item.Server)</td>
    <td class='col-app'>$($item.AppName)</td>
    <td class='col-pool'>$($item.AppPool)</td>
    <td class='col-path'>$($item.Path)</td>
    <td class='col-status $statusClass'>$($item.Status)</td>
</tr>
"@
}

$HtmlPage = @"
$HtmlHeader
<table>
<tr>
    <th class='col-server'>Server</th>
    <th class='col-app'>App Name</th>
    <th class='col-pool'>AppPool</th>
    <th class='col-path'>Physical Path</th>
    <th class='col-status'>Status</th>
</tr>
$HtmlRows
</table>
"@

$HtmlPage | Out-File $ReportFile -Encoding UTF8
Start-Process $ReportFile
Write-Host "`nHTML report created successfully!" -ForegroundColor Green
