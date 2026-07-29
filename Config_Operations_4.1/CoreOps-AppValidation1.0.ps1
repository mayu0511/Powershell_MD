######################################################################################################################
# CoreOps Application Validation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Date:: 1-July-2025
#======================================================================================================================
Get-ChildItem D:\ -Recurse | Unblock-File
Clear-Host
$Module = "CoreOps-AppValidation"
$ServerType = 'cccoa'
$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
$ShortRegion = 'w2'
} else {
    throw "Unable to determine region: hostname '$ThisServer' does not match 'e1' or 'w2'."
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$ThisServer" "Name=availability-zone,Values=*" --region $Region | ConvertFrom-Json)

if($null -eq $AWSVarialbes -or $AWSVarialbes.Count -eq 0){
    throw "No running EC2 instance found matching tag:Name=$ThisServer in region $Region (i.e. the host this script is running on). Check the AWS CLI credentials/region before continuing."
}

$EnvironmentName = if($AWSVarialbes[0].Environment){ $AWSVarialbes[0].Environment.ToLower() } else { $null }
$EnvironmentName
$Environmentattributon = if($AWSVarialbes[0].Attribution){ $AWSVarialbes[0].Attribution.ToLower() } else { $null }
$Environmentattributon
$EnvironmentStack = if($AWSVarialbes[0].Stack){ ($AWSVarialbes[0].Stack.ToLower())[0] } else { $null }
$EnvironmentStack

if(-not $EnvironmentName -or -not $Environmentattributon -or -not $EnvironmentStack){
    throw "One or more required tags (environment/attribution/stack) are missing on the matched EC2 instance(s). Cannot continue."
}

if($null -eq $AWSVarialbes[0].Pod){
if($Environmentattributon -eq "jazz"){
$Environmentpod = $Environmentattributon
}else{
$S3bucketslist = $NULL
$S3bucketslist = aws s3 ls
if($S3bucketslist -match "corecard-pod2-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod2"}
elseif($S3bucketslist -match "corecard-pod4-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod4"}
elseif($S3bucketslist -match "corecard-pod5-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod5"}
elseif(($S3bucketslist -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($Environmentattributon -eq "jazz")) {$Environmentpod = "jazz"}
}

}
else{
$Environmentpod = $AWSVarialbes[0].Pod.ToLower()}
$Environmentpod

$ServerNamePattern = "*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*"
$ServerListRaw = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$ServerNamePattern" "Name=availability-zone,Values=*" --region $Region | ConvertFrom-Json)
$SplitKey = "$EnvironmentName$EnvironmentStack"

if(-not $ServerListRaw -or $ServerListRaw.Count -eq 0){
    $ServerNamePattern = "*$ServerType$ShortRegion$EnvironmentName*"
    $ServerListRaw = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$ServerNamePattern" "Name=availability-zone,Values=*" --region $Region | ConvertFrom-Json)
    $SplitKey = "$EnvironmentName"
}

$ServerList = ($ServerListRaw | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split $SplitKey)[1] } } | Sort-Object -Property serial).Name
$ServerList

if(-not $ServerList -or $ServerList.Count -eq 0){
    throw "No web servers found matching tag:Name=$ServerNamePattern. Cannot continue."
}

$MasterHost = $ServerList | Select-Object -First 1

If (Test-Connection $MasterHost -Quiet){
Write-Host "Master Host - " $MasterHost
}
else{
$MasterHost = $ServerList | Select-Object -Last 1
Write-Host "Master Host - " $MasterHost
}
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
try {
$MasterCoreOpsAPIHandlerVersion =  Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction Stop -ScriptBlock {
$MasterCoreOpsAPIHandlerVersion = (Get-Command D:\WebServer\CoreOpsAPI\CC.RSP.WebApi.exe).FileVersionInfo.FileVersion
$MasterCoreOpsAPIHandlerVersion}

$MasterCoreOpsAPIWebsiteHash = Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction Stop -ScriptBlock {

(Get-ChildItem -Path D:\WebServer\CoreOpsAPI\ -Recurse -Filter *.* -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\Serilogs\\' -and $_.Extension -notin '.log','.txt' } |
    Get-FileHash -ErrorAction SilentlyContinue).Hash | %{ $MasterCoreOpsAPIWebsiteHash += "$_"}
$MasterCoreOpsAPIWebsite_stream = [IO.MemoryStream]::new([byte[]][char[]]$MasterCoreOpsAPIWebsiteHash)
$MasterCoreOpsAPIWebsiteHash = (Get-FileHash -InputStream $MasterCoreOpsAPIWebsite_stream).Hash
$MasterCoreOpsAPIWebsiteHash}
} catch {
    throw "Failed to connect to master host '$MasterHost' to collect baseline CoreOpsAPI version/hash: $($_.Exception.Message)"
}

$ExpectedWEBServerCount = 2
$Expectedenable32BitAppOnWin64 = "False"
$ExpectedidleTimeoutAction = "Terminate"
$ExpectedLoadUserProfile = "True"
$ExpectedmaxProcesses = "1"
$ExpectedPrivateMemoryLimit = "0"
$ExpectedRecyclingPeriodicRestartTime = "1740"
$ExpectedAnonymousAuthentication = "Application Pool Identity"
$ExpectedAppPooluserName = ((whoami).TOLOWER()).Split('\')[0] + '\gMSA-coa-svc$'
$ExpectedConnectAs = "Pass-through Authentication"
$ExpectedSiteBindingprotocol = "http https"
$ExpectedCoreOpsAPIWorking = "Working"

if (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "perf") -and ($Environmentattributon -eq "cookie")){
    $ExpectedmaxProcesses = "1"
}
elseif (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "uat2" -or $EnvironmentName -eq "mock") -and ($Environmentattributon -eq "jazz")){
    $ExpectedmaxProcesses = "1"
}
$ExpectedCoreOpsAPIHandlerLogs = "D:\LOGs\CoreOpsAPILogs"

$Outputreport = "<HTML><TITLE> $Module Validation Report </TITLE>
                 <BODY background-color:peachpuff>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                 <H2>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</H2>
                 <H3>PLEASE VERIFY BELOW TABLE VALUES AND COMPARE WITH EXPECTED VALUES</H3></font>
                 <Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>Master Host</B></TD>
                   <TD><B>CoreOpsAPI Handler Version</B></TD>
                   <TD><B>CoreOpsAPI Website Hash</B></TD>
                   <TD><B>32Bit Enable</B></TD>
                   <TD><B>Idle Timeout Action</B></TD>
                   <TD><B>Load User Profile</B></TD>
                   <TD><B>Max Worker Processes</B></TD>
                   <TD><B>Private Memory Limit</B></TD>
                   <TD><B>Recycling Periodic Restart Time (in min)</B></TD>
                   <TD><B>Anonymous Authentication</B></TD>
                   <TD><B>AppPool userName</B></TD>
                   <TD><B>ConnectAs</B></TD>
                   <TD><B>Site Protocols</B></TD>
                   <TD><B>CoreOpsAPI URL Status</B></TD>
                   <TD><B>CoreOpsAPI Handler Logs</B></TD>
                   </TR>"
                   

$Outputreport += "<TR align=center>"
$Outputreport += "<TD>$("$MasterHost".ToUpper())</TD>
                   <TD>$("$MasterCoreOpsAPIHandlerVersion")</TD>
                   <TD>$("True")</TD>
                   <TD>$("$Expectedenable32BitAppOnWin64")</TD>
                   <TD>$("$ExpectedidleTimeoutAction")</TD>
                   <TD>$("$ExpectedLoadUserProfile")</TD>
                   <TD>$("$ExpectedmaxProcesses")</TD>
                   <TD>$("$ExpectedPrivateMemoryLimit")</TD>
                   <TD>$("$ExpectedRecyclingPeriodicRestartTime")</TD>
                   <TD>$("$ExpectedAnonymousAuthentication")</TD>
                   <TD>$("$ExpectedAppPooluserName")</TD>
                   <TD>$("$ExpectedConnectAs")</TD>
                   <TD>$("$ExpectedSiteBindingprotocol")</TD>
                   <TD>$("$ExpectedCoreOpsAPIWorking")</TD>
                   <TD>$("$ExpectedCoreOpsAPIHandlerLogs")</TD>
                  </TR>"

$Result = @() 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$result += Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction Stop -ScriptBlock {
$computername = hostname
Import-Module WebAdministration
$CoreOpsAPIHandlerVersion = (Get-Command D:\WebServer\CoreOpsAPI\CC.RSP.WebApi.exe).FileVersionInfo.FileVersion
$ServerCoreOpsAPIWebsiteHash = $NULL
(Get-ChildItem -Path D:\WebServer\CoreOpsAPI\ -Recurse -Filter *.* -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\Serilogs\\' -and $_.Extension -notin '.log','.txt' } |
    Get-FileHash -ErrorAction SilentlyContinue).Hash | %{ $ServerCoreOpsAPIWebsiteHash += "$_"}
$ServerCoreOpsAPIWebsite_stream = [IO.MemoryStream]::new([byte[]][char[]]$ServerCoreOpsAPIWebsiteHash)
$ServerCoreOpsAPIWebsiteHash = (Get-FileHash -InputStream $ServerCoreOpsAPIWebsite_stream).Hash
$enable32BitAppOnWin64 = (Get-ItemProperty IIS:\AppPools\CoreOpsAPI).enable32BitAppOnWin64
$managedPipelineMode = (Get-ItemProperty IIS:\AppPools\CoreOpsAPI).managedPipelineMode
$state = (Get-ItemProperty IIS:\AppPools\CoreOpsAPI).state
$idleTimeoutAction = Get-ItemProperty "IIS:\AppPools\CoreOpsAPI" -Name processModel.idleTimeoutAction
$LoadUserProfile = Get-ItemProperty "IIS:\AppPools\CoreOpsAPI" -Name processModel.LoadUserProfile.Value
$maxProcesses = Get-ItemProperty "IIS:\AppPools\CoreOpsAPI" -Name processModel.maxProcesses.Value
$PrivateMemoryLimit = (Get-ItemProperty IIS:\apppools\CoreOpsAPI -Name recycling.periodicrestart.privateMemory).value
$RecyclingPeriodicRestartTime = ((Get-ItemProperty -Path "IIS:\AppPools\CoreOpsAPI" -Name Recycling.PeriodicRestart.Time).value.TotalMinutes)
$AnonymousAuthentication = (Get-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "CoreOpsAPI" -Name userName).Value
if($AnonymousAuthentication -eq ""){$AnonymousAuthentication = "Application Pool Identity"}
$AppPooluserName = Get-ItemProperty "IIS:\AppPools\CoreOpsAPI" -Name processModel.userName.Value
$ConnectAs = (Get-WebConfiguration "/system.applicationHost/sites/site[@name='CoreOpsAPI']/application[@path='/']/VirtualDirectory[@path='/']").UserName
if($ConnectAs -eq ""){$ConnectAs = "Pass-through Authentication"}
$SiteBindingprotocol = (Get-IISSite "CoreOpsAPI").bindings.protocol #| select-object protocol, bindingInformation
$SiteBindingInfo = (Get-IISSite "CoreOpsAPI").bindings.bindingInformation
$CoreOpsAPISiteBindingIP = ((Get-IISSite "CoreOpsAPI").bindings | where-Object protocol -eq "https").bindingInformation.split(':')[0]

$CoreOpsAPIHandlerLogs = $null
$match = Select-String -Path "D:\WebServer\CoreOpsAPI\log4net.config" -Pattern '<file.*value="([^"]+)"'

if ($match) {
    $CoreOpsAPIHandlerLogsTemp = $match.Matches[0].Groups[1].Value
    $CoreOpsAPIHandlerLogs = $CoreOpsAPIHandlerLogsTemp -replace '\\\.log$',''
}
else {
    $CoreOpsAPIHandlerLogs = ""
}

$resultvalue = @() 
$resultvalue = [PSCustomObject] @{ 
    ServerName = "$($computername)"
    CoreOpsAPIHandlerVersion = "$($CoreOpsAPIHandlerVersion)"
#   ScaleServiceVersion = "$($ScaleServiceVersion)"
    ServerCoreOpsAPIWebsiteHash = "$($ServerCoreOpsAPIWebsiteHash)"
    enable32BitAppOnWin64 = "$($enable32BitAppOnWin64)"
    managedPipelineMode = "$($managedPipelineMode)"
    state = "$($state)"
    idleTimeoutAction = "$($idleTimeoutAction)"
    LoadUserProfile = "$($LoadUserProfile)"
    maxProcesses = "$($maxProcesses)"
    PrivateMemoryLimit = "$($PrivateMemoryLimit)"
    RecyclingPeriodicRestartTime = "$($RecyclingPeriodicRestartTime)"
    AnonymousAuthentication = "$($AnonymousAuthentication)"
    AppPooluserName = "$($AppPooluserName)"
    ConnectAs = "$($ConnectAs)"
    SiteBindingprotocol = "$($SiteBindingprotocol)"
    SiteBindingInfo = "$($SiteBindingInfo)"
    #IISLogging = "$($IISLogging)"
    CoreOpsAPISiteBindingIP = "$($CoreOpsAPISiteBindingIP)"
    CoreOpsAPIHandlerLogs = "$($CoreOpsAPIHandlerLogs)"
    #HandlerLogs = "$($HandlerLogs)"
	}
$resultvalue
}  

if($Serverlist.Count -eq $ExpectedWEBServerCount){

$Outputreport += "</Table>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                   <H4>  CoreOpsAPI Website Validation Report - Server Count $($result.count) </H4></font>"

}else{

$Outputreport += "</Table>
                 <font color =""#CD5C5C"" face=""Microsoft Tai le"">
                   <H4>CoreOpsAPI Website Validation Report - Server Count $($result.count) is not matching with expected count $ExpectedWEBServerCount </H4></font>"
}

$Outputreport += "<Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>WEB Server</B></TD>
                   <TD><B>CoreOpsAPI Handler Version</B></TD>
                   <TD><B>CoreOpsAPI Website Hash</B></TD>
                    <TD><B>32Bit Enable</B></TD>
                   <TD><B>Idle Timeout Action</B></TD>
                   <TD><B>Load User Profile</B></TD>
                   <TD><B>Max Worker Processes</B></TD>
                   <TD><B>Private Memory Limit</B></TD>
                   <TD><B>Recycling Periodic Restart Time(in min)</B></TD>
                   <TD><B>Anonymous Authentication</B></TD>
                   <TD><B>AppPool userName</B></TD>
                   <TD><B>ConnectAs</B></TD>
                   <TD><B>Site Protocols</B></TD>
                   <TD><B>Site Bindings</B></TD>
                   <TD><B>CoreOpsAPI URL</B></TD>
                   <TD><B>CoreOpsAPI Handler Logs</B></TD>
                   </TR>"

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


Foreach($Entry in $Result){ 
 
$IPAddress = $Entry.CoreOpsAPISiteBindingIP

$CoreOpsAPIRequest = $null
$CoreOpsAPIURL = "https://$IPAddress"

try {
    $CoreOpsAPIRequest = Invoke-WebRequest $CoreOpsAPIURL -UseBasicParsing
    $CoreOpsAPIStatus = $CoreOpsAPIRequest.StatusCode
}
catch {
    if ($_.Exception.Response) {
        $CoreOpsAPIStatus = [int]$_.Exception.Response.StatusCode
    }
    else {
        $CoreOpsAPIStatus = $null
    }
}

$CoreOpsAPIContent = if($CoreOpsAPIRequest){
    $CoreOpsAPIRequest.Content
}
else{
    $null
}

if ($CoreOpsAPIStatus -eq 404)
{
    $CoreOpsAPIWorking = "Working"
}
else
{
    $CoreOpsAPIWorking = "Not Working"
    $CoreOpsAPIContent = $null
}

$CoreOpsAPIURL
$CoreOpsAPIStatus
$CoreOpsAPIContent
$CoreOpsAPIWorking
        
if(($Entry.CoreOpsAPIHandlerVersion -eq $MasterCoreOpsAPIHandlerVersion) `
-and ($Entry.ServerCoreOpsAPIWebsiteHash -eq $MasterCoreOpsAPIWebsiteHash) `
-and ($Entry.enable32BitAppOnWin64 -eq $Expectedenable32BitAppOnWin64) `
-and ($Entry.idleTimeoutAction -eq $ExpectedidleTimeoutAction) `
-and ($Entry.loadUserProfile -eq $ExpectedLoadUserProfile) `
-and ($Entry.maxProcesses -eq $ExpectedmaxProcesses) `
-and ($Entry.privateMemoryLimit -eq $ExpectedPrivateMemoryLimit) `
-and ($Entry.RecyclingPeriodicRestartTime -eq $ExpectedRecyclingPeriodicRestartTime) `
-and ($Entry.anonymousAuthentication -eq $ExpectedAnonymousAuthentication) `
-and ($Entry.AppPooluserName -eq $ExpectedAppPooluserName) `
-and ($Entry.ConnectAs -eq  $ExpectedConnectAs ) `
-and ($Entry.SiteBindingprotocol -eq $ExpectedSiteBindingprotocol) `
-and ($CoreOpsAPIWorking -eq $ExpectedCoreOpsAPIWorking)`
-and ($Entry.CoreOpsAPIHandlerLogs -eq $ExpectedCoreOpsAPIHandlerLogs))
{
$Outputreport += "<TR align=center>" 
}else{
$Outputreport += "<TR bgcolor=LightSalmon align=center>"
}

$Outputreport += "<TD>$($Entry.ServerName)</TD>
                  <TD align=center>$($Entry.CoreOpsAPIHandlerVersion)</TD>
                  <TD align=center>$($Entry.ServerCoreOpsAPIWebsiteHash -eq $MasterCoreOpsAPIWebsiteHash)</TD>
                  <TD align=center>$($Entry.enable32BitAppOnWin64)</TD>
                  <TD align=center>$($Entry.idleTimeoutAction)</TD>
                  <TD align=center>$($Entry.loadUserProfile)</TD>
                  <TD align=center>$($Entry.maxProcesses)</TD>
                  <TD align=center>$($Entry.privateMemoryLimit)</TD>
                  <TD align=center>$($Entry.RecyclingPeriodicRestartTime)</TD>
                  <TD align=center>$($Entry.anonymousAuthentication)</TD>
                  <TD align=center>$($Entry.AppPooluserName)</TD>
                  <TD align=center>$($Entry.ConnectAs)</TD>
                  <TD align=center>$($Entry.SiteBindingprotocol)</TD>
                  <TD align=center>$($Entry.SiteBindingInfo)</TD>
                  <TD align=center><p>$CoreOpsAPIURL </br> $CoreOpsAPIContent </br> $CoreOpsAPIStatus </br> $CoreOpsAPIWorking</p></TD>
                  <TD align=center>$($Entry.CoreOpsAPIHandlerLogs)</TD></TR>"


Clear-Variable CoreOpsAPIURL
Clear-Variable CoreOpsAPIStatus
Clear-Variable CoreOpsAPIWorking

 }

$Outputreport += "</Table></BODY>
                  </HTML>" 

$Outputreport += @"
    </table>
</body>
</html>
"@
$ReportFileNamePrefix = $Module +"_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | out-file "$ReportFile"
aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

if($host.Name -eq "Windows PowerShell ISE Host"){Invoke-Item $ReportFile}

Clear-Variable Module
Clear-Variable ServerType
Clear-Variable Thisserver
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable Environmentpod
Clear-Variable result
Clear-Variable Outputreport
Clear-Variable Environmentpod
Clear-Variable MasterHost
Clear-Variable ExpectedWEBServerCount
Clear-Variable MasterCoreOpsAPIHandlerVersion
Clear-Variable MasterCoreOpsAPIWebsiteHash
Clear-Variable Expectedenable32BitAppOnWin64
Clear-Variable ExpectedidleTimeoutAction
Clear-Variable ExpectedmaxProcesses
Clear-Variable ExpectedAppPooluserName
Clear-Variable ExpectedConnectAs
Clear-Variable ExpectedSiteBindingprotocol
Clear-Variable ExpectedCoreOpsAPIWorking
Clear-Variable ExpectedLoadUserProfile
Clear-Variable ExpectedPrivateMemoryLimit
Clear-Variable ExpectedAnonymousAuthentication
Clear-Variable ExpectedRecyclingPeriodicRestartTime
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ExpectedCoreOpsAPIHandlerLogs
