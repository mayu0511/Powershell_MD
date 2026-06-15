######################################################################################################################
#Updated for the POD1 and DB name as according to Environment| | DEVELOPED BY:: Netra Chettri
#Version 1.0 | Date:: 14-MAY-2026
#=====================================================================================================================

Clear-Host
$Module = "Web-NetworkManagementWebAPI"
$ServerType = 'wcf'
$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
$ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution,Pod:Tags[?Key=='pod']|[0].Value,Status:State.pod}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName
$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon
$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack
if(($AWSVarialbes.Pod) -eq $NULL){
if($Environmentattributon -eq "jazz"){
$Environmentpod = $Environmentattributon
}else{
$S3bucketslist = $NULL
$S3bucketslist = aws s3 ls
elseif($S3bucketslist -match "corecard-pod1-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod1"}
elseif($S3bucketslist -match "corecard-pod2-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod2"}
elseif($S3bucketslist -match "corecard-pod4-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod4"}
elseif($S3bucketslist -match "corecard-pod5-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod5"}
elseif(($S3bucketslist -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($Environmentattributon -eq "jazz")) {$Environmentpod = "jazz"}
}
}
else{
$Environmentpod = $AWSVarialbes.Pod.ToLower()}
$Environmentpod

$ServerList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial).Name
$ServerList

$MasterHost = $ServerList | Select-Object -First 1
#$MasterHost.ToUPPER()
If (Test-Connection $MasterHost -Quiet){
Write-Host "Master Host - " $MasterHost
}
else{
$MasterHost = $ServerList | Select-Object -Last 1
Write-Host "Master Host - " $MasterHost
}

$ExpectedWCFServerCount =$NULL
$ExpectedWCFServerCount = 2
if (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "perf") -and ($Environmentattributon -eq "cookie")){$ExpectedWCFServerCount = "45"}
elseif (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "uat2" -or $EnvironmentName -eq "mock") -and ($Environmentattributon -eq "jazz")){$ExpectedWCFServerCount = "15"}
$ExpectedNetworkManagementAPILogFolderPath = "D:\LOGs\NetworkManagementAPI"
$Expectedappsettingsjsonvalue = "True"
$Expectedenable32BitAppOnWin64 = "False"
$ExpectedidleTimeoutAction = "Suspend"
$ExpectedLoadUserProfile = "True"
$ExpectedmaxProcesses = "1"
$ExpectedPrivateMemoryLimit = "0"
$ExpectedRecyclingPeriodicRestartTime = "1740"
$ExpectedAnonymousAuthentication = "Application Pool Identity"
$ExpectedAppPooluserName = ((whoami).TOLOWER()).Split('\')[0] + '\gmsa-app-svc$'
$ExpectedConnectAs = "Pass-through Authentication"
$ExpectedSiteBindingprotocol = "https"
$ExpectedNetworkManagementAPICLRVersion = "No Manged Code"
$ExpectedNetworkManagementAPIURLSTATUS = "Method Not Allowed"



$Outputreport = "<HTML><TITLE> $Module Validation Report </TITLE>
                <BODY background-color:peachpuff>
                <font color =""#4682B4"" face=""Microsoft Tai le"">
                <H2>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</H2>
                <H3>PLEASE VERIFY BELOW TABLE VALUES AND COMPARE WITH EXPECTED VALUES</H3></font>
                <Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>Master Host</B></TD>
                   <TD><B>NetworkManagementAPI Version</B></TD>
                   <TD><B>NetworkManagementAPI Hash</B></TD>
                   <TD><B>AppPoolCLRVersion</B></TD>
                   <TD><B>NetworkManagementAPILog Folder Path</B></TD>  
                   <TD><B>AppsettingsJson</B></TD>                                                                             
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
                   <TD><B>NetworkManagementAPI URL & STATUS</B></TD>
                   </TR>"


$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$MasterNetworkManagementWebAPIValue =  Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
$MasterNetworkManagementWebAPIInternal =  (Get-Command D:\WebServer\NetworkManagementAPI\NetworkManagementWebAPI.exe).FileVersionInfo.FileVersion
$MasterNetworkManagementWebAPIInternal}

$MasterNetworkManagementAPIHash = Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
(Get-ChildItem -Path D:\WebServer\NetworkManagementAPI\ -Recurse -Filter *.* | Get-FileHash).Hash | %{ $MasterNetworkManagementAPIHash += "$_"}
$MasterNetworkManagementAPI_stream = [IO.MemoryStream]::new([byte[]][char[]]$MasterNetworkManagementAPIHash)
$MasterNetworkManagementAPIHash = (Get-FileHash -InputStream $MasterNetworkManagementAPI_stream).Hash
$MasterNetworkManagementAPIHash}


#$MasterNetworkManagementAPICLRVersion = Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
Import-Module WebAdministration
$MasterNetworkManagementAPICLRVersion = (Get-ItemProperty IIS:\AppPools\NetworkManagementAPI).managedRuntimeVersion
if($MasterNetworkManagementAPICLRVersion -eq ""){
$MasterAPICLRVersion = "No Manged Code"}
else{
$MasterAPICLRVersion = $MasterNetworkManagementAPICLRVersion}#}
$MasterAPICLRVersion


$LogPath = "D:\LOGs\NetworkManagementAPI"
if (Test-Path $LogPath)
{
$MasterNetworkManagementAPILogFolderPath = "D:\LOGs\NetworkManagementAPI"
}else{$MasterNetworkManagementAPILogFolderPath = "False"}
$MasterNetworkManagementAPILogFolderPath



$Outputreport += "<TR align=center>"
$Outputreport += "<TD>$("$MasterHost".ToUpper())</TD>
                   <TD>$("$MasterNetworkManagementWebAPIValue")</TD>
                   <TD>$("True")</TD>
                   <TD>$("$MasterAPICLRVersion")</TD>
                   <TD align=center>$($MasterNetworkManagementAPILogFolderPath)</TD>
                   <TD>$("$Expectedappsettingsjsonvalue")</TD>
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
                   <TD>$("$ExpectedNetworkManagementAPIURLSTATUS")</TD>
                   </TR>"



$Result = @() 


$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$result += Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction inquire -ScriptBlock {
$computername = hostname
Import-Module WebAdministration
$NetworkManagementAPIVersion = (Get-Command D:\WebServer\NetworkManagementAPI\NetworkManagementWebAPI.exe).FileVersionInfo.FileVersion

$ServerNetworkManagementAPIHash = $NULL
(Get-ChildItem -Path  D:\WebServer\NetworkManagementAPI\ -Recurse -Filter *.* | Get-FileHash).Hash | %{ $ServerNetworkManagementAPIHash += "$_"}
$ServerNetworkManagementAPI_stream = [IO.MemoryStream]::new([byte[]][char[]]$ServerNetworkManagementAPIHash)
$ServerNetworkManagementAPIHash = (Get-FileHash -InputStream $ServerNetworkManagementAPI_stream).Hash


$NMAPICLRVersion = (Get-ItemProperty IIS:\AppPools\NetworkManagementAPI).managedRuntimeVersion
if($NMAPICLRVersion -eq ""){
$CLRVersion = "No Manged Code"}
else{
$CLRVersion = $NMAPICLRVersion}
$CLRVersion

$AuthNetworkManagementAPILogPath = "D:\LOGs\NetworkManagementAPI"
if (Test-Path $AuthNetworkManagementAPILogPath)
{
$NMAPILogFolderPath = "D:\LOGs\NetworkManagementAPI"
}else{$NMAPILogFolderPath = "False"}
$NMAPILogFolderPath


$domain = ($Env:USERDNSDOMAIN.Split('-')[1] ).split('.')[0]

if($domain -eq "POD1"){$Environment = "pod1"}
if($domain -eq "POD2"){$Environment = "pod2"}
if($domain -eq "POD4"){$Environment = "pod4"}
if($domain -eq "Jazz"){$Environment = "Jazz"}

$Environment

$jsonFilePath = "D:\WebServer\NetworkManagementAPI\appsettings.json"
$jsonContent = Get-Content -Raw -Path $jsonFilePath | ConvertFrom-Json
$Log = $jsonContent.SeriLog.LogPath
$Log
$DefaultConnectionValue = $jsonContent.ConnectionStrings.DefaultConnection -split ';'| ForEach-Object { ($_ -split '=')[1].Trim() } | Select-Object -First 2
$DefaultConnectionValue
$CoreAuthConnectionValue = $jsonContent.ConnectionStrings.CoreAuthConnection -split ';'| ForEach-Object { ($_ -split '=')[1].Trim() } | Select-Object -First 2
$CoreAuthConnectionValue
$CoreIssueConnectionValue = $jsonContent.ConnectionStrings.CoreIssueConnection -split ';'| ForEach-Object { ($_ -split '=')[1].Trim() } | Select-Object -First 2
$CoreIssueConnectionValue

if(($Environment -eq "jazz") -and ($Log -eq "D:\LOGs\NetworkManagementAPI") -and 
   (($DefaultConnectionValue -eq "CCAPPSQLAG1" -or $DefaultConnectionValue -eq "CCAPPLIST1") -and $DefaultConnectionValue -eq "CCJAZZ_CoreIssue") -and 
   (($CoreAuthConnectionValue -eq "CCAPPSQLAG1" -or $CoreAuthConnectionValue -eq "CCAPPLIST1") -and $CoreAuthConnectionValue -eq "CCJAZZ_CoreAuth") -and 
   (($CoreIssueConnectionValue -eq "CCAPPSQLAG1" -or $CoreIssueConnectionValue -eq "CCAPPLIST1") -and $CoreIssueConnectionValue -eq "CCJAZZ_CoreIssue")) {
    $AppsettingsJson = "True"
}

elseif(($Environment -eq "pod1") -and ($Log -eq "D:\LOGs\NetworkManagementAPI") -and 
   (($DefaultConnectionValue -eq "CCAPPSQLAG1" -or $DefaultConnectionValue -eq "CCAPPLIST1") -and $DefaultConnectionValue -eq "CCGS_UATP_CoreIssue") -and 
   (($CoreAuthConnectionValue -eq "CCAPPSQLAG1" -or $CoreAuthConnectionValue -eq "CCAPPLIST1") -and $CoreAuthConnectionValue -eq "CCGS_UATP_CoreAuth") -and 
   (($CoreIssueConnectionValue -eq "CCAPPSQLAG1" -or $CoreIssueConnectionValue -eq "CCAPPLIST1") -and $CoreIssueConnectionValue -eq "CCGS_UATP_CoreIssue")) {

    $AppsettingsJson = "True"
}

elseif(($Environment -eq "pod1") -and ($Log -eq "D:\LOGs\NetworkManagementAPI") -and 
   (($DefaultConnectionValue -eq "CCAPPSQLAG1" -or $DefaultConnectionValue -eq "CCAPPLIST1") -and $DefaultConnectionValue -eq "CCGS_PTR_CoreIssue") -and 
   (($CoreAuthConnectionValue -eq "CCAPPSQLAG1" -or $CoreAuthConnectionValue -eq "CCAPPLIST1") -and $CoreAuthConnectionValue -eq "CCGS_PTR_CoreAuth") -and 
   (($CoreIssueConnectionValue -eq "CCAPPSQLAG1" -or $CoreIssueConnectionValue -eq "CCAPPLIST1") -and $CoreIssueConnectionValue -eq "CCGS_PTR_CoreIssue")) {

    $AppsettingsJson = "True"
}

elseif(($Environment -eq "pod1") -and ($Log -eq "D:\LOGs\NetworkManagementAPI") -and 
   (($DefaultConnectionValue -eq "CCAPPSQLAG1" -or $DefaultConnectionValue -eq "CCAPPLIST1") -and $DefaultConnectionValue -eq "CCGS_PERF1_CoreIssue") -and 
   (($CoreAuthConnectionValue -eq "CCAPPSQLAG1" -or $CoreAuthConnectionValue -eq "CCAPPLIST1") -and $CoreAuthConnectionValue -eq "CCGS_PERF1_CoreAuth") -and 
   (($CoreIssueConnectionValue -eq "CCAPPSQLAG1" -or $CoreIssueConnectionValue -eq "CCAPPLIST1") -and $CoreIssueConnectionValue -eq "CCGS_PERF1_CoreIssue")) {

    $AppsettingsJson = "True"
}

elseif(($Environment -eq "pod1") -and ($Log -eq "D:\LOGs\NetworkManagementAPI") -and 
   (($DefaultConnectionValue -eq "CCAPPSQLAG1" -or $DefaultConnectionValue -eq "CCAPPLIST1") -and $DefaultConnectionValue -eq "CCGS_CoreIssue") -and 
   (($CoreAuthConnectionValue -eq "CCAPPSQLAG1" -or $CoreAuthConnectionValue -eq "CCAPPLIST1") -and $CoreAuthConnectionValue -eq "CCGS_CoreAuth") -and 
   (($CoreIssueConnectionValue -eq "CCAPPSQLAG1" -or $CoreIssueConnectionValue -eq "CCAPPLIST1") -and $CoreIssueConnectionValue -eq "CCGS_CoreIssue")) {

    $AppsettingsJson = "True"
}

elseif(($Environment -eq "pod2") -and ($Log -eq "D:\LOGs\NetworkManagementAPI") -and 
   (($DefaultConnectionValue -eq "CCAPPSQLAG1" -or $DefaultConnectionValue -eq "CCAPPLIST1") -and $DefaultConnectionValue -eq "CCGS_CoreIssue") -and 
   (($CoreAuthConnectionValue -eq "CCAPPSQLAG1" -or $CoreAuthConnectionValue -eq "CCAPPLIST1") -and $CoreAuthConnectionValue -eq "CCGS_CoreAuth") -and 
   (($CoreIssueConnectionValue -eq "CCAPPSQLAG1" -or $CoreIssueConnectionValue -eq "CCAPPLIST1") -and $CoreIssueConnectionValue -eq "CCGS_CoreIssue")) {
    $AppsettingsJson = "True"
}

elseif(($Environment -eq "pod4") -and ($Log -eq "D:\LOGs\NetworkManagementAPI") -and 
   (($DefaultConnectionValue -eq "CCAPPSQLAG1" -or $DefaultConnectionValue -eq "CCAPPLIST1") -and $DefaultConnectionValue -eq "CCGS_CoreIssue") -and 
   (($CoreAuthConnectionValue -eq "CCAPPSQLAG1" -or $CoreAuthConnectionValue -eq "CCAPPLIST1") -and $CoreAuthConnectionValue -eq "CCGS_CoreAuth") -and 
   (($CoreIssueConnectionValue -eq "CCAPPSQLAG1" -or $CoreIssueConnectionValue -eq "CCAPPLIST1") -and $CoreIssueConnectionValue -eq "CCGS_CoreIssue")) {
    $AppsettingsJson = "True"
}

else {
    $AppsettingsJson = "False"
}

$AppsettingsJson


$enable32BitAppOnWin64 = (Get-ItemProperty IIS:\AppPools\NetworkManagementAPI).enable32BitAppOnWin64
$managedPipelineMode = (Get-ItemProperty IIS:\AppPools\NetworkManagementAPI).managedPipelineMode
$state = (Get-ItemProperty IIS:\AppPools\NetworkManagementAPI).state
$idleTimeoutAction = Get-ItemProperty "IIS:\AppPools\NetworkManagementAPI" -Name processModel.idleTimeoutAction
$loadUserProfile = Get-ItemProperty "IIS:\AppPools\NetworkManagementAPI" -Name processModel.LoadUserProfile.Value
$maxProcesses = Get-ItemProperty "IIS:\AppPools\NetworkManagementAPI" -Name processModel.maxProcesses.Value
$privateMemoryLimit = (Get-ItemProperty "IIS:\apppools\NetworkManagementAPI" -Name recycling.periodicrestart.privateMemory).value
$RecyclingPeriodicRestartTime = ((Get-ItemProperty -Path "IIS:\AppPools\NetworkManagementAPI" -Name Recycling.PeriodicRestart.Time).value.TotalMinutes)

$anonymousAuthentication = (Get-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "Webserver/NetworkManagementAPI" -Name userName).Value

if($anonymousAuthentication -eq ""){$anonymousAuthentication = "Application Pool Identity"}
$AppPooluserName = (Get-ItemProperty "IIS:\AppPools\NetworkManagementAPI" -Name processModel.userName.Value).TOLOWER()

#$ConnectAs = ((Get-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/WCF']/VirtualDirectory[@path='/']").UserName).TOLOWER()

$ConnectAs = (Get-WebConfiguration "/system.applicationHost/sites/site[@name='WebServer']/application[@path='/NetworkManagementAPI']/VirtualDirectory[@path='/']").UserName

if($ConnectAs -match ""){$ConnectAs = "Pass-through Authentication"}
$SiteBindingprotocol = (Get-IISSite "WebServer").bindings.protocol #| select-object protocol, bindingInformation
$SiteBindingInfo = (Get-IISSite "WebServer").bindings.bindingInformation


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

try{
$IPAddress = (Resolve-DnsName $computername | Where-Object Type -eq "A").IpAddress
#$option = New-PSSessionOption -ProxyAccessType NoProxyServer
$NetworkManagementAPIURL = "https://$IPAddress/NetworkManagementAPI/api/Reports/CheckTraffic"
#$WCFURL
$WebCall = Invoke-WebRequest  $NetworkManagementAPIURL
$WebCall.Content
} catch {

    $string_err = $_ | Out-String
}

$NetworkManagementAPIURLStatus = $string_err | Select-String "Method not allowed" |ForEach-Object { $_.Matches.Value }
if ($NetworkManagementAPIURLStatus -eq $NULL) {$NetworkManagementAPIURLStatus = "Not Working"}

$NetworkManagementAPIURLStatus


$resultvalue = @() 
$resultvalue = [PSCustomObject] @{ 
    ServerName = "$($computername)"
    NetworkManagementAPIVersion = "$($NetworkManagementAPIVersion)"
    ServerNetworkManagementAPIHash = "$($ServerNetworkManagementAPIHash)"
    CLRVersion = "$($CLRVersion)"
    NMAPILogFolderPath = "$($NMAPILogFolderPath)"
    AppsettingsJson = "$($AppsettingsJson)"
    enable32BitAppOnWin64 = "$($enable32BitAppOnWin64)"
    managedPipelineMode = "$($managedPipelineMode)"
    state = "$($state)"
    idleTimeoutAction = "$($idleTimeoutAction)"
    loadUserProfile = "$($loadUserProfile)"
    maxProcesses = "$($maxProcesses)"
    privateMemoryLimit = "$($privateMemoryLimit)"
    RecyclingPeriodicRestartTime = "$($RecyclingPeriodicRestartTime)"
    anonymousAuthentication = "$($anonymousAuthentication)"
    AppPooluserName = "$($AppPooluserName)"
    ConnectAs = "$($ConnectAs)"
    SiteBindingprotocol = "$($SiteBindingprotocol)"
    SiteBindingInfo = "$($SiteBindingInfo)"
    NetworkManagementAPIURL = "$($NetworkManagementAPIURL)"
    NetworkManagementAPIURLSTATUS = "$($NetworkManagementAPIURLStatus)"
	}
$resultvalue
}


if($Serverlist.Count -eq $ExpectedWCFServerCount)
{
$Outputreport += "</Table>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                   <H4>NetworkManagementWebAPI Validation Report - Server Count $($result.count)</H4></font>"


}else{
$Outputreport += "</Table>
                 <font color =""#CD5C5C"" face=""Microsoft Tai le"">
                 <H4>  NetworkManagementWebAPI Validation Report - Server Count $($result.count) is not matching with expected count $ExpectedWCFServerCount </H4></font>"
}




$Outputreport += "<Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>WCF Server</B></TD>
                   <TD><B>NetworkManagementAPI Version</B></TD>
                   <TD><B>NetworkManagementAPI Hash</B></TD>
                   <TD><B>AppPoolCLR Version</B></TD>
                   <TD><B>NetworkManagementAPILog Folder Path</B></TD>
                   <TD><B>AppsettingsJson</B></TD>
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
                   <TD><B>NetworkManagementAPI URL & STATUS</B></TD>
                   </TR>"

Foreach($ServerEntry in $Serverlist) 

    { 
     try{
    $Entry = $NULL

   $Entry =  $Result | Where-Object {$_.ServerName -eq $ServerEntry}

$Entry.NetworkManagementAPIURL
$Entry.NetworkManagementAPIURLSTATUS
$Entry.AppsettingsJson

if(($MasterNetworkManagementWebAPIValue -eq $Entry.NetworkManagementAPIVersion) -and ($MasterNetworkManagementAPIHash -eq $Entry.ServerNetworkManagementAPIHash) -and ($MasterAPICLRVersion -eq $Entry.CLRVersion) -and ($MasterNetworkManagementAPILogFolderPath -eq $Entry.NMAPILogFolderPath) -and ($Entry.AppsettingsJson -eq $Expectedappsettingsjsonvalue) -and ($Entry.enable32BitAppOnWin64 -eq $Expectedenable32BitAppOnWin64) -and ($Entry.loadUserProfile -eq $ExpectedLoadUserProfile) -and ($Entry.idleTimeoutAction -eq $ExpectedidleTimeoutAction) -and ($Entry.maxProcesses -eq $ExpectedmaxProcesses) -and ($Entry.privateMemoryLimit -eq $ExpectedPrivateMemoryLimit) -and ($Entry.RecyclingPeriodicRestartTime -eq $ExpectedRecyclingPeriodicRestartTime) -and ($Entry.anonymousAuthentication -eq $ExpectedAnonymousAuthentication) -and ($Entry.AppPooluserName -eq $ExpectedAppPooluserName) -and ($Entry.ConnectAs -eq  $ExpectedConnectAs ) -and ($Entry.SiteBindingprotocol -eq $ExpectedSiteBindingprotocol) -and ($Entry.NetworkManagementAPIURLSTATUS -eq $ExpectedNetworkManagementAPIURLSTATUS))
{
$Outputreport += "<TR align=center>" 
}else{
$Outputreport += "<TR bgcolor=LightSalmon align=center>"
}
$Outputreport += "<TD>$ServerEntry</TD>
                  <TD>$($Entry.NetworkManagementAPIVersion)</TD>
                  <TD>$($Entry.ServerNetworkManagementAPIHash -eq $MasterNetworkManagementAPIHash)</TD>
                  <TD>$($Entry.CLRVersion)</TD>                  
                  <TD></p>$($Entry.NMAPILogFolderPath)</p></TD>
                  <TD></p>$($Entry.AppsettingsJson)</p></TD>                  
                  <TD>$($Entry.enable32BitAppOnWin64)</TD>
                  <TD>$($Entry.idleTimeoutAction)</TD>
                  <TD>$($Entry.loaduserprofile)</TD>
                  <TD>$($Entry.maxProcesses)</TD>
                  <TD>$($Entry.privateMemoryLimit)</TD>
                  <TD>$($Entry.RecyclingPeriodicRestartTime)</TD>
                  <TD>$($Entry.anonymousAuthentication)</TD>
                  <TD>$($Entry.AppPooluserName)</TD>
                  <TD>$($Entry.ConnectAs)</TD>
                  <TD>$($Entry.SiteBindingprotocol)</TD>
                  <TD>$($Entry.SiteBindingInfo)</TD>
                  <TD><p>$($Entry.NetworkManagementAPIURL) <br> $($Entry.NetworkManagementAPIURLSTATUS)</p></TD></TR>"
}Catch{
$Outputreport += "<TR bgcolor=LightSalmon align=center>"
$Outputreport += "<TD>$ServerEntry</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD>
                  <TD>Problem</TD></TR>"
}
}

$Outputreport += "</Table></BODY>
                  </HTML>" 
$ReportFileNamePrefix = $Module +"_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | out-file "$ReportFile"
#aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

if($host.Name -eq "Windows PowerShell ISE Host"){Invoke-Item $ReportFile}

Clear-Variable Module
Clear-Variable ServerType
Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable Environmentpod
Clear-Variable result
Clear-Variable ExpectedNetworkManagementAPILogFolderPath
Clear-Variable Expectedenable32BitAppOnWin64
Clear-Variable ExpectedidleTimeoutAction
Clear-Variable ExpectedLoadUserProfile
Clear-Variable ExpectedmaxProcesses
Clear-Variable ExpectedAppPooluserName
Clear-Variable ExpectedConnectAs
Clear-Variable ExpectedSiteBindingprotocol
Clear-Variable ExpectedLoadUserProfile
Clear-Variable ExpectedPrivateMemoryLimit
Clear-Variable ExpectedAnonymousAuthentication
Clear-Variable MasterHost
Clear-Variable MasterNetworkManagementWebAPIValue
Clear-Variable MasterNetworkManagementAPIHash
Clear-Variable LogPath
Clear-Variable MasterNetworkManagementAPILogFolderPath
Clear-Variable ExpectedRecyclingPeriodicRestartTime
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ExpectedWCFServerCount
Clear-Variable result