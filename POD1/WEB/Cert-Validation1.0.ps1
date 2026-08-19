######################################################################################################################
# Certificate  Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Certificate  Validation | Date:: 19-Aug-2025
#======================================================================================================================

Get-ChildItem D:\ -Recurse | Unblock-File

Clear-Host

$ThisServer = (hostname).ToLower()   # or use $env:COMPUTERNAME
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{
    AvailabilityZone:Placement.AvailabilityZone,
    IpAddress:PrivateIpAddress,
    Type:InstanceType,
    Name:Tags[?Key=='Name']|[0].Value,
    Status:State.Name,
    Environment:Tags[?Key=='environment']|[0].Value,
    Stack:Tags[?Key=='stack']|[0].Value,
    Attribution:Tags[?Key=='attribution']|[0].Value
}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentName

$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()
$EnvironmentAttribution

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$EnvironmentStack

$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZone = $NULL
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones or * for all zones"

$AvailabilityZone

$ServerTypeList = @('web')
$ServerList = @()

ForEach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $ServerList += ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{
        AvailabilityZone:Placement.AvailabilityZone,
        IpAddress:PrivateIpAddress,
        Type:InstanceType,
        Name:Tags[?Key=='Name']|[0].Value,
        Status:State.Name
    }" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='$AvailabilityZone'" --region $Region | ConvertFrom-Json) |
    Select-Object @{n = "Name"; e = { $_.Name } },
                  @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } },
                  @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } |
    Sort-Object -Property serial)
}

$ServerList | Out-Host

if (-not $ServerList) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name
#[void](Read-Host "Please verify the server list and press Enter to continue or Ctrl+C to stop the script")

# ---------------- IIS SSL Certificate Check ----------------
$Results = @()

foreach ($computername in $ServerList) {
    try {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer
        $ServerResult = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            Import-Module WebAdministration -ErrorAction Stop
            $sites = Get-ChildItem IIS:\Sites
            $out = @()
            foreach ($site in $sites) {
                foreach ($binding in $site.bindings.Collection) {
                    if ($binding.CertificateHash) {
                        $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $binding.CertificateHash }
                        if ($cert) {
                            $out += [PSCustomObject]@{
                                SiteName       = $site.Name
                                Binding        = $binding.BindingInformation
                                IssuedTo       = ($cert.Subject -split ',')[0] -replace '^CN=', ''
                                IssuedBy       = ($cert.Issuer -split ',')[0] -replace '^CN=', ''
                                ExpirationDate = $cert.NotAfter.ToString("yyyy-MM-dd HH:mm:ss")
                                DaysRemaining  = (New-TimeSpan -Start (Get-Date) -End $cert.NotAfter).Days
                            }
                        }
                    }
                }
            }
            return $out
        }
        
        foreach ($row in $ServerResult) {
            $Results += [PSCustomObject]@{
                ServerName     = $computername
                SiteName       = $row.SiteName
                Binding        = $row.Binding
                IssuedTo       = $row.IssuedTo
                IssuedBy       = $row.IssuedBy
                ExpirationDate = $row.ExpirationDate
                DaysRemaining  = $row.DaysRemaining
            }
        }

    } catch {
        $Results += [PSCustomObject]@{
            ServerName     = $computername
            SiteName       = "-"
            Binding        = "-"
            IssuedTo       = "-"
            IssuedBy       = "-"
            ExpirationDate = "-"
            DaysRemaining  = "Error: $_"
        }
    }
}

# Create timestamped report
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = "C:\temp\IISCertReport_$TimeStamp.html"

# HTML Styling
$Head = @"
<style>
    body { font-family: Arial; }
    h2 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin-top: 10px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #4CAF50; color: white; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .expired { background-color: #ffcccc; }
    .warning { background-color: #fff3cd; }
    .ok { background-color: #d4edda; }
</style>
"@

$ReportHeader = "<h2>IIS SSL Certificate Expiration Report</h2><p>Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>"

# Convert to HTML rows
$Html = $Results | Sort-Object ServerName,SiteName |
    ForEach-Object {
        $class = if ($_.DaysRemaining -is [int]) {
                    if ($_.DaysRemaining -lt 0) { "expired" }
                    elseif ($_.DaysRemaining -lt 30) { "warning" }
                    else { "ok" }
                 } else { "" }

        "<tr class='$class'><td>$($_.ServerName)</td><td>$($_.SiteName)</td><td>$($_.Binding)</td><td>$($_.IssuedTo)</td><td>$($_.IssuedBy)</td><td>$($_.ExpirationDate)</td><td>$($_.DaysRemaining)</td></tr>"
    }

$Table = @"
<table>
<tr>
<th>Server Name</th><th>Site Name</th><th>Binding</th><th>Issued To</th><th>Issued By</th><th>Expiration Date</th><th>Days Remaining</th>
</tr>
$Html
</table>
"@

# Save report
$Report = ConvertTo-Html -Head $Head -Title "IIS SSL Certificate Expiration Report" -Body "$ReportHeader $Table"
$Report | Out-File $ReportFile -Encoding UTF8

Invoke-Item $ReportFile
Write-Host "Report generated: $ReportFile"
