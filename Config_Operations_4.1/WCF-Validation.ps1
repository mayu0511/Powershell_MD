Clear-Host
$Module = "Web-WCF"
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
if($S3bucketslist -match "corecard-pod2-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod2"}
elseif($S3bucketslist -match "corecard-pod4-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod4"}
elseif($S3bucketslist -match "corecard-pod5-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod5"}
elseif(($S3bucketslist -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($Environmentattributon -eq "jazz")) {$Environmentpod = "jazz"}
}
}
else{
$Environmentpod = $AWSVarialbes.Pod.ToLower()}
$Environmentpod

$ServerList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial).Name
#$ServerList

$MasterHost = $ServerList | Select-Object -First 1
#$MasterHost.ToUPPER()
If (Test-Connection $MasterHost -Quiet){
Write-Host "Master Host - " $MasterHost
}
else{
$MasterHost = $ServerList | Select-Object -Last 1
Write-Host "Master Host - " $MasterHost
}

$ExpectedWCFServerCount = 2
if (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "perf") -and ($Environmentattributon -eq "cookie")){$ExpectedWCFServerCount = "45"}
elseif (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "uat2" -or $EnvironmentName -eq "mock") -and ($Environmentattributon -eq "jazz")){$ExpectedWCFServerCount = "45"}
$ExpectedCoreIssueTestConnection = "True"
$Expectedenable32BitAppOnWin64 = "True"
$ExpectedidleTimeoutAction = "Suspend"
$ExpectedLoadUserProfile = "True"
$ExpectedmaxProcesses = "4"
$ExpectedPrivateMemoryLimit = "0"
$ExpectedRecyclingPeriodicRestartTime = "1740"
$ExpectedAnonymousAuthentication = "Application Pool Identity"
$ExpectedAppPooluserName = ((whoami).TOLOWER()).Split('\')[0] + '\gmsa-app-svc$'
$ExpectedConnectAs = "Pass-through Authentication"
$ExpectedSiteBindingprotocol = "https"
$ExpectedWCFURLSTATUS = "WORKING"
$ExpectedXRequestID = "X-Request-ID"
$ExpectedWCFLogs = "D:\LOGs\WCFLogs"



$Outputreport = "<HTML><TITLE> $Module Validation Report </TITLE>
                <BODY background-color:peachpuff>
                <font color =""#4682B4"" face=""Microsoft Tai le"">
                <H2>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</H2>
                <H3>PLEASE VERIFY BELOW TABLE VALUES AND COMPARE WITH EXPECTED VALUES</H3></font>
                <Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>Master Host</B></TD>
                   <TD><B>WCF Version</B></TD>
                   <TD><B>WCF Hash</B></TD>
                   <TD><B>KMS Value</B></TD>
                   <TD><B>Handler Value</B></TD>
                   <TD><B>Handler Test Connection</B></TD>
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
                   <TD><B>XRequestID</B></TD>
                   <TD><B>WCF URL STATUS</B></TD>
                   <TD><B>WCF Logs</B></TD>
                   </TR>"


$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$MasterWCFVersionValue =  Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
$MasterWCFVersionValueInternal =  (Get-Command D:\WebServer\WCF\bin\CC.CoreServices.common.dll).FileVersionInfo.FileVersion
$MasterWCFVersionValueInternal}

$MasterWCFHash = Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
(Get-ChildItem -Path D:\WebServer\WCF\ -Recurse -Filter *.* | Get-FileHash).Hash | %{ $MasterWCFHash += "$_"}
$MasterWCF_stream = [IO.MemoryStream]::new([byte[]][char[]]$MasterWCFHash)
$MasterWCFHash = (Get-FileHash -InputStream $MasterWCF_stream).Hash
$MasterWCFHash}

$MasterKMSValue = Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
$MasterKMSValue = (Select-String -Path D:\WebServer\WCF\configuration\appSettings.config -Pattern "KMSDefaultMachines").ToString().Split('=')[2] -replace '["/>]',''
$MasterKMSValue}

$MasterHandlerTagValue = Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
$MasterHandlerTagValue = ((Select-String -Path D:\WebServer\WCF\configuration\appSettings.config -Pattern "dbbHandlerRoot").ToString().Split('=')[2] -replace '[ "/>]','').split(':')
$MasterHandlerTagValue = $MasterHandlerTagValue[0] + "://" + $MasterHandlerTagValue[1]
$MasterHandlerTagValue}


$Outputreport += "<TR align=center>"
$Outputreport += "<TD>$("$MasterHost".ToUpper())</TD>
                   <TD>$("$MasterWCFVersionValue")</TD>
                   <TD>$("True")</TD>
                   <TD>$("$MasterKMSValue")</TD>
                   <TD align=center>$($MasterHandlerTagValue)</TD>
                   <TD>$("$ExpectedCoreIssueTestConnection")</TD>
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
                   <TD>$("$ExpectedXRequestID")</TD>
                   <TD>$("$ExpectedWCFURLSTATUS")</TD>
                   <TD>$("$ExpectedWCFLogs")</TD>
                   </TR>"



$Result = @() 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$result += Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction inquire -ScriptBlock {
$computername = hostname
Import-Module WebAdministration
$WCFVersion = (Get-Command D:\WebServer\WCF\bin\CC.CoreServices.common.dll).FileVersionInfo.FileVersion
$ServerWCFHash = $NULL
(Get-ChildItem -Path D:\WebServer\WCF\ -Recurse -Filter *.* | Get-FileHash).Hash | %{ $ServerWCFHash += "$_"}
$ServerWCF_stream = [IO.MemoryStream]::new([byte[]][char[]]$ServerWCFHash)
$ServerWCFHash = (Get-FileHash -InputStream $ServerWCF_stream).Hash
$KMSDefaultMachinesTag = (Select-String -Path D:\WebServer\WCF\configuration\appSettings.config -Pattern "KMSDefaultMachines").ToString().Split('=')[2] -replace '["/>]',''
$dbbHandlerRoot = ((Select-String -Path D:\WebServer\WCF\configuration\appSettings.config -Pattern "dbbHandlerRoot").ToString().Split('=')[2] -replace '[ "/>]','').split(':')
$CoreIssueTestConnection = (Test-NetConnection -computername $dbbHandlerRoot[1] -port 443).TcpTestSucceeded
$dbbHandlerRoot = $dbbHandlerRoot[0] + "://" + $dbbHandlerRoot[1]
$enable32BitAppOnWin64 = (Get-ItemProperty IIS:\AppPools\WCF).enable32BitAppOnWin64
$managedPipelineMode = (Get-ItemProperty IIS:\AppPools\WCF).managedPipelineMode
$state = (Get-ItemProperty IIS:\AppPools\WCF).state
$idleTimeoutAction = Get-ItemProperty "IIS:\AppPools\WCF" -Name processModel.idleTimeoutAction
$loadUserProfile = Get-ItemProperty "IIS:\AppPools\WCF" -Name processModel.LoadUserProfile.Value
$maxProcesses = Get-ItemProperty "IIS:\AppPools\WCF" -Name processModel.maxProcesses.Value
$privateMemoryLimit = (Get-ItemProperty "IIS:\apppools\WCF" -Name recycling.periodicrestart.privateMemory).value
$RecyclingPeriodicRestartTime = ((Get-ItemProperty -Path "IIS:\AppPools\WCF" -Name Recycling.PeriodicRestart.Time).value.TotalMinutes)
$anonymousAuthentication = (Get-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "Webserver/WCF" -Name userName).Value
if($anonymousAuthentication -eq ""){$anonymousAuthentication = "Application Pool Identity"}
$AppPooluserName = (Get-ItemProperty "IIS:\AppPools\WCF" -Name processModel.userName.Value).TOLOWER()
#$ConnectAs = ((Get-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/WCF']/VirtualDirectory[@path='/']").UserName).TOLOWER()
$ConnectAs = (Get-WebConfiguration "/system.applicationHost/sites/site[@name='WebServer']/application[@path='/WCF']/VirtualDirectory[@path='/']").UserName
if($ConnectAs -match ""){$ConnectAs = "Pass-through Authentication"}
$SiteBindingprotocol = (Get-IISSite "WebServer").bindings.protocol #| select-object protocol, bindingInformation
$SiteBindingInfo = (Get-IISSite "WebServer").bindings.bindingInformation
$XRequestID = (Get-ItemProperty 'IIS:\Sites\Webserver' -Name logfile.customFields.collection).logFieldName

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

$IPAddress = (Resolve-DnsName $computername | Where-Object Type -eq "A").IpAddress
#$option = New-PSSessionOption -ProxyAccessType NoProxyServer
$WCFURL = "https://$IPAddress/WCF/dbbService.svc"
#$WCFURL
$WebCall = Invoke-WebRequest  $WCFURL -UseBasicParsing
#$WebCall.Content
if (($WebCall.Content -match "You have created a service") -and ($WebCall.StatusCode	-eq 200))
{#$WebCall.StatusCode
$WCFURLSTATUS = "WORKING"
}
else
{#$WebCall.StatusCode
$WCFURLSTATUS =  "FAILURE"
}
#$WebCall.StatusCode

$WCFLogsTemp = (Select-String -Path "D:\WebServer\WCF\log4net.config" -Pattern "file type").ToString().Split('=')[2].Split('"')[1]
$WCFLogs = $WCFLogsTemp -replace '\\%.*$',''

If(Test-Path $WCFLogs){
    $WCFLogs1 = "Passed"
} Else {
    $WCFLogs1 = "Failed"
}


$resultvalue = @() 
$resultvalue = [PSCustomObject] @{ 
    ServerName = "$($computername)"
    WCFVersion = "$($WCFVersion)"
    ServerWCFHash = "$($ServerWCFHash)"
    KMSDefaultMachinesTag = "$($KMSDefaultMachinesTag)"
    dbbHandlerRoot = "$($dbbHandlerRoot)"
    CoreIssueTestConnection = "$($CoreIssueTestConnection)"
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
    XRequestID = "$($XRequestID)"
    WCFURL = "$($WCFURL)"
    WCFURLSTATUS = "$($WCFURLSTATUS)"
    WCFLogs = "$($WCFLogs)"
	}
$resultvalue
}

if($Serverlist.Count -eq $ExpectedWCFServerCount)
{
$Outputreport += "</Table>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                   <H4>WCF Servers Validation Report - Server Count $($result.count)</H4></font>"


}else{
$Outputreport += "</Table>
                 <font color =""#CD5C5C"" face=""Microsoft Tai le"">
                 <H4>  WCF Validation Report - Server Count $($result.count) is not matching with expected count $ExpectedWCFServerCount </H4></font>"
}

$Outputreport += "<Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>WCF Server</B></TD>
                   <TD><B>WCF Version</B></TD>
                   <TD><B>WCF Hash</B></TD>
                   <TD><B>KMS Value</B></TD>
                   <TD><B>Handler Value & Test Connectivity</B></TD>
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
                   <TD><B>XRequestID</B></TD>
                   <TD><B>WCF URL & STATUS</B></TD>
                   <TD><B>WCF Logs</B></TD>
                   </TR>"

Foreach($ServerEntry in $Serverlist) 

    { 
     try{
    $Entry = $NULL

   $Entry =  $Result | Where-Object {$_.ServerName -eq $ServerEntry}

$Entry.WCFURL
$Entry.WCFURLSTATUS


if(($MasterWCFVersionValue -eq $Entry.WCFVersion) -and ($MasterWCFHash -eq $Entry.ServerWCFHash) -and ($MasterKMSValue -eq $Entry.KMSDefaultMachinesTag) -and ($MasterHandlerTagValue -eq $Entry.dbbHandlerRoot) -and ($Entry.CoreIssueTestConnection -eq $ExpectedCoreIssueTestConnection) -and ($Entry.enable32BitAppOnWin64 -eq $Expectedenable32BitAppOnWin64) -and ($Entry.loadUserProfile -eq $ExpectedLoadUserProfile) -and ($Entry.idleTimeoutAction -eq $ExpectedidleTimeoutAction) -and ($Entry.maxProcesses -eq $ExpectedmaxProcesses) -and ($Entry.privateMemoryLimit -eq $ExpectedPrivateMemoryLimit) -and ($Entry.RecyclingPeriodicRestartTime -eq $ExpectedRecyclingPeriodicRestartTime) -and ($Entry.anonymousAuthentication -eq $ExpectedAnonymousAuthentication) -and ($Entry.AppPooluserName -eq $ExpectedAppPooluserName) -and ($Entry.ConnectAs -eq  $ExpectedConnectAs ) -and ($Entry.SiteBindingprotocol -eq $ExpectedSiteBindingprotocol) -and ($Entry.XRequestID -eq $ExpectedXRequestID)-and ($Entry.WCFURLSTATUS -eq $ExpectedWCFURLSTATUS) -and ($Entry.WCFLogs -eq $ExpectedWCFLogs))
{
$Outputreport += "<TR align=center>" 
}else{
$Outputreport += "<TR bgcolor=LightSalmon align=center>"
}
$Outputreport += "<TD>$ServerEntry</TD>
                  <TD>$($Entry.WCFVersion)</TD>
                  <TD>$($Entry.ServerWCFHash -eq $MasterWCFHash)</TD>
                  <TD>$($Entry.KMSDefaultMachinesTag)</TD>
                  <TD><p>$($Entry.dbbHandlerRoot)  <br>  $($Entry.CoreIssueTestConnection)</p></TD>
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
                  <TD>$($Entry.XRequestID)</TD>
                  <TD><p>$($Entry.WCFURL) <br> $($Entry.WCFURLSTATUS)</p></TD>
                  <TD>$($Entry.WCFLogs)</TD></TR>"
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
                  <TD>Problem</TD>
                  <TD>Problem</TD></TR>"
}
}

$Outputreport += "</Table></BODY>
                  </HTML>" 
$ReportFileNamePrefix = $Module +"_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | out-file "$ReportFile"
aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

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
Clear-Variable ExpectedWCFServerCount
Clear-Variable ExpectedCoreIssueTestConnection
Clear-Variable Expectedenable32BitAppOnWin64
Clear-Variable ExpectedidleTimeoutAction
Clear-Variable ExpectedmaxProcesses
Clear-Variable ExpectedAppPooluserName
Clear-Variable ExpectedConnectAs
Clear-Variable ExpectedSiteBindingprotocol
Clear-Variable ExpectedWCFURLSTATUS
Clear-Variable ExpectedLoadUserProfile
Clear-Variable ExpectedPrivateMemoryLimit
Clear-Variable ExpectedAnonymousAuthentication
Clear-Variable MasterHost
Clear-Variable MasterWCFHash
Clear-Variable ExpectedRecyclingPeriodicRestartTime
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable ExpectedXRequestID
Clear-Variable ExpectedWCFLogs