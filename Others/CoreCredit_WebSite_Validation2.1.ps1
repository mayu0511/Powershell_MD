######################################################################################################################
# Corecredit  Validation Script   | Enhance by : Mahendra Dwivedi
# Version 2.1 | Date:: 30-March-2026
#======================================================================================================================

Clear-Host
$Module = "Web-CoreCredit"
$ServerType = 'ew'
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
if($NULL -eq ($AWSVarialbes.Pod)){
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
$ServerList

$Result = @() 



ForEach($computername in $ServerList) 
{
$computername
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$result += Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
$computername = hostname
Import-Module WebAdministration
$CoreCreditVersion = (Get-Command D:\WebServer\CoreCredit\bin\CoreCredit.dll).FileVersionInfo.FileVersion
#$ScaleServiceVersion = (Get-Command D:\WebServer\ScaleService\dbbScaleService.exe).FileVersionInfo.FileVersion
$enable32BitAppOnWin64 = (Get-ItemProperty IIS:\AppPools\CoreCredit).enable32BitAppOnWin64
$managedPipelineMode = (Get-ItemProperty IIS:\AppPools\CoreCredit).managedPipelineMode
$state = (Get-ItemProperty IIS:\AppPools\CoreCredit).state
$idleTimeoutAction = Get-ItemProperty "IIS:\AppPools\CoreCredit" -Name processModel.idleTimeoutAction
$maxProcesses = Get-ItemProperty "IIS:\AppPools\CoreCredit" -Name processModel.maxProcesses.Value
$AppPooluserName = Get-ItemProperty "IIS:\AppPools\CoreCredit" -Name processModel.userName.Value
$LoadUserProfile = Get-ItemProperty "IIS:\AppPools\CoreCredit" -Name processModel.LoadUserProfile.Value
$PrivateMemoryLimit = (Get-ItemProperty IIS:\apppools\CoreCredit -Name recycling.periodicrestart.privateMemory).value
$RecyclingPeriodicRestartTime = ((Get-ItemProperty -Path "IIS:\AppPools\CoreCredit" -Name Recycling.PeriodicRestart.Time).value.TotalMinutes)
$AnonymousAuthentication = (Get-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "CoreCredit" -Name userName).Value
if($AnonymousAuthentication -eq ""){$AnonymousAuthentication = "Application Pool Identity"}
$ConnectAs = (Get-WebConfiguration "/system.applicationHost/sites/site[@name='CoreCredit']/application[@path='/']/VirtualDirectory[@path='/']").UserName
if($ConnectAs -eq ""){$ConnectAs = "Pass-through Authentication"}
#$ConnectAs = (Get-WebConfiguration "/system.applicationHost/sites/site[@name='CoreCredit']/application[@path='/']/VirtualDirectory[@path='/']").UserName
$SiteBindingprotocol = (Get-IISSite "CoreCredit").bindings.protocol #| select-object protocol, bindingInformation
$SiteBindingInfo = (Get-IISSite "CoreCredit").bindings.bindingInformation
$CoreCreditSiteBindingIP = ((Get-IISSite "CoreCredit").bindings | where-Object protocol -eq "https").bindingInformation.split(':')[0]
$ReportServerPath = $NULL
$ReportServerPath = (Select-String -Path D:\WebServer\CoreCredit\Web.config -Pattern "ReportServerPath").ToString().Split('=')[2] -replace '[" >]',''
$ReportServerPath = $ReportServerPath.Substring(0,$ReportServerPath.Length-1)
$LetterServerPath = $NULL
$LetterServerPath = (Select-String -Path D:\WebServer\CoreCredit\Web.config -Pattern "LetterServerPath").ToString().Split('=')[2] -replace '[" >]',''
$LetterServerPath = $LetterServerPath.Substring(0,$LetterServerPath.Length-1)
$JSFileVersion = (Select-String -Path D:\WebServer\CoreCredit\Web.config -Pattern "JSFileVersion").ToString().Split('=')[2] -replace '[" />]',''
$AccessControlAllowOrigin = ((Select-String -Path D:\WebServer\CoreCredit\Web.config -Pattern "Access-Control-Allow-Origin").ToString().Split('=')[2] -replace '[" >]','').TrimEnd('/')
#$AccessControlAllowOrigin = $AccessControlAllowOrigin.Substring(0,$AccessControlAllowOrigin.Length-1)	

#$CDNUrl = ((Select-String -Path D:\WebServer\CoreCredit\Web.config -Pattern "CDNUrl").ToString().Split('=')[2] -replace '[" >]','')
#$CDNUrl = "https://" + (([System.Uri]$CDNUrl).Host)  
#$CDNUrlbaseURL = $CDNUrlbaseURL.Host
#$CDNUrlbaseURL = "https://" + "$CDNUrlbaseURL"

$WcfAPIEndPointDefault = ((Select-String -Path D:\WebServer\CoreCredit\Web.config -Pattern "CustomerService.ICustomerService").ToString().Split('=')[1]).Split('"')[1]
$DbbAPIEndPointDefault = ((Select-String -Path D:\WebServer\CoreCredit\Web.config -Pattern "dbbService.IdbbService").ToString().Split('=')[1]).Split('"')[1]

$CoreCreditSAMLTemp = (Select-String -Path "D:\WebServer\CoreCredit\log4net.config" -Pattern "_CoreSAML_").ToString().Split('=')[2].Split('"')[1]
$CoreCreditSAML = $CoreCreditSAMLTemp -replace '\\%.*$',''

$CoreCreditLogsTemp = (Select-String -Path "D:\WebServer\CoreCredit\log4net.config" -Pattern "_CoreCredit_").ToString().Split('=')[2].Split('"')[1]
$CoreCreditLogs = $CoreCreditLogsTemp -replace '\\%.*$',''
If((Test-Path $CoreCreditSAML) -and (Test-Path $CoreCreditLogs))
  {
  $HandlerLogs =  "Passed"
  } Else {
  $HandlerLogs =  "Failed" }


$resultvalue = @() 
$resultvalue = [PSCustomObject] @{ 
    ServerName = "$($computername)"
    CoreCreditVersion = "$($CoreCreditVersion)"
    enable32BitAppOnWin64 = "$($enable32BitAppOnWin64)"
    managedPipelineMode = "$($managedPipelineMode)"
    state = "$($state)"
    idleTimeoutAction = "$($idleTimeoutAction)"
    maxProcesses = "$($maxProcesses)"
    AppPooluserName = "$($AppPooluserName)"
    LoadUserProfile = "$($LoadUserProfile)"
    PrivateMemoryLimit = "$($PrivateMemoryLimit)"
    RecyclingPeriodicRestartTime = "$($RecyclingPeriodicRestartTime)"
    AnonymousAuthentication = "$($AnonymousAuthentication)"
    ConnectAs = "$($ConnectAs)"
    SiteBindingprotocol = "$($SiteBindingprotocol)"
    SiteBindingInfo = "$($SiteBindingInfo)"
    CoreCreditSiteBindingIP = "$($CoreCreditSiteBindingIP)"
    ReportServerPath = "$($ReportServerPath)"
    LetterServerPath = "$($LetterServerPath)"
    JSFileVersion = "$($JSFileVersion)"
    AccessControlAllowOrigin = "$($AccessControlAllowOrigin)"
    #CDNUrl = "$($CDNUrl)"
    WcfAPIEndPointDefault = "$($WcfAPIEndPointDefault)"
    DbbAPIEndPointDefault = "$($DbbAPIEndPointDefault)"
    CoreCreditSAMLLogs = "$($CoreCreditSAML)"
    CoreCreditLogs = "$($CoreCreditLogs)"
    HandlerLogs = "$($HandlerLogs)"
    
    }

$resultvalue
}
}
$Outputreport = "<HTML><TITLE> $Module Validation Report </TITLE>
                 <BODY background-color:peachpuff>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                 <H2>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</H2>
                 <H3>PLEASE VERIFY BELOW TABLE VALUES AND COMPARE WITH EXPECTED VALUES</H3></font>
                 <Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>WEB Server</B></TD>
                   <TD><B>CoreCredit Version</B></TD>
                   <TD><B>32Bit Enable</B></TD>
                   <TD><B>Pipeline Mode</B></TD>
                   <TD><B>AppPool State</B></TD>
                   <TD><B>Idle Timeout Action</B></TD>
                   <TD><B>Max Worker Processes</B></TD>
                   <TD><B>AppPool userName</B></TD>
                   <TD><B>Load User Profile</B></TD>
                   <TD><B>Private Memory Limit</B></TD>
                   <TD><B>Recycling Periodic Restart Time(in min)</B></TD>
                   <TD><B>Anonymous Authentication</B></TD>
                   <TD><B>ConnectAs</B></TD>
                   <TD><B>Site Protocols</B></TD>
                   <TD><B>Site Bindings</B></TD>
                   <TD><B>CoreCredit URL</B></TD>                   
                   <TD><B>Report Server URL</B></TD>
                   <TD><B>Letter Server URL</B></TD>
                   <TD><B>JSFileVersion</B></TD>
                   <TD><B>AccessControlAllowOrigin</B></TD>
                   <TD><B>WcfAPIEndPointDefault</B></TD>
                   <TD><B>DbbAPIEndPointDefault</B></TD>
                   <TD><B>CoreCreditSAML Logs</B></TD>
                   <TD><B>CoreCredit Logs</B></TD>
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


Foreach($Entry in $Result){ 
 
#$IPAddress = (Resolve-DnsName $Entry.ServerName | Where-Object Type -eq "A").IpAddress
$IPAddress = $Entry.CoreCreditSiteBindingIP
$WCFAPIEndPointURL = $Entry.WcfAPIEndPointDefault
$WCFDBBIDAPIEndPointURL = $Entry.DbbAPIEndPointDefault
$ReportServerURL = $Entry.ReportServerPath
$ReportServerURL
$CoreCreditSSLURL = $Entry.AccessControlAllowOrigin
#$CDNBaseUrl = $Entry.CDNUrl
$CoreCreditSAMLLogs = $Entry.CoreCreditSAMLLogs
$CoreCreditLogs = $Entry.CoreCreditLogs


try {
$CoreCreditURL = "https://$IPAddress"
$CoreCreditRequest = Invoke-WebRequest $CoreCreditURL -UseBasicParsing
$CoreCarditSSLRequest = Invoke-WebRequest $CoreCreditSSLURL -UseBasicParsing

} catch{

    # Error caught but not needed for processing
    

}

$CoreCreditStatus = $CoreCreditRequest.StatusCode
$CoreCreditSSLStatus = $CoreCarditSSLRequest.StatusCode
$CoreCreditContent = $CoreCreditRequest.Content | Select-String "Version:" |ForEach-Object { $_.Matches.Value }
if (($CoreCreditContent -eq "Version:") -and ($CoreCreditStatus -eq 200) -and ($CoreCreditSSLStatus -eq 200))
{
$CoreCreditWorking="Working"
}
else
{
$CoreCreditWorking="Failure"
$CoreCreditContent = $NULL
}
$CoreCreditURL
$CoreCreditStatus
$CoreCreditContent

$WCFWebCall = $NULL

try
{

$WCFWebCall = Invoke-WebRequest  $WCFAPIEndPointURL -UseBasicParsing

}
Catch{
# Error caught but not needed for processing
}

if (($WCFWebCall.Content -match "You have created a service") -and ($WCFWebCall.StatusCode	-eq 200))
{
$WCFURLSTATUS = "Working"
}
else
{
$WCFURLSTATUS =  "Failure"
}

try
{

$WCFDBBIDWebCall = Invoke-WebRequest  $WCFDBBIDAPIEndPointURL -UseBasicParsing

}
Catch{
# Error caught but not needed for processing
}

if (($WCFDBBIDWebCall.Content -match "You have created a service") -and ($WCFDBBIDWebCall.StatusCode-eq 200))
{
$WCFDBBIBEURLSTATUS = "Working"
}
else
{
$WCFDBBIBEURLSTATUS =  "Failure"
}

try
{

$ReportServerPathbaseURL =$NULL
$ReportServerPathbaseURL = [System.Uri]$ReportServerURL
$ReportServerPathbaseURL = $ReportServerPathbaseURL.Host
$http = 'https://'
$reportfolder = '/reportserver'
$rpsurl = $http + $ReportServerPathbaseURL + $reportfolder

# Retrieve credentials 
$EnvName = $Env:USERDOMAIN.ToUpper().Split('-')[-1]
$SecretId = "$EnvName/web-rw-secret"
$SecretRaw = Get-SECSecretValue -SecretId $SecretId
$SecretJson = $SecretRaw.SecretString | ConvertFrom-Json

# Create PSCredential
$securePass = ConvertTo-SecureString $SecretJson.password -AsPlainText -Force
$cred = New-Object PSCredential ($SecretJson.username, $securePass)

# ========= 1. Report Server URL Accessibility ==========


    $ReportServerURLtest = Invoke-WebRequest -Uri $rpsurl -UseBasicParsing -Credential $cred -MaximumRedirection 5 -TimeoutSec 120 -ErrorAction Stop

    $statuscode = $ReportServerURLtest.StatusCode

    if ($statuscode -eq 200) {
        $ReportServerURLSTATUS = "Working"
    } else {
        $ReportServerURLSTATUS = "Failure"
    }
}
catch {
    $ReportServerURLSTATUS = "Failure"
}

Write-Output "Report Server Status: $ReportServerURLSTATUS"


$ExpectedAppPoolState = "Started"
$ExpectedPipelineMode = "Integrated"
$Expectedenable32BitAppOnWin64 = "True"
$ExpectedidleTimeoutAction = "Suspend"
$ExpectedLoadUserProfile = "True"
$ExpectedmaxProcesses = "1"
$ExpectedPrivateMemoryLimit = "0"
$ExpectedRecyclingPeriodicRestartTime = "1740"
$ExpectedAnonymousAuthentication = "Application Pool Identity"
$ExpectedAppPooluserName = ((whoami).TOLOWER()).Split('\')[0] + '\gMSA-web-svc$'
$ExpectedConnectAs = "Pass-through Authentication"
$ExpectedSiteBindingprotocol = "https"
$ExpectedCoreCreditStatus = "200"
$ExpectedCoreCreditWorking = "Working"
$ExpectedReportServerURLSTATUS = "Working"
$ExpectedWCFURLSTATUS = "Working"
$ExpectedWCFDBBIBEURLSTATUS = "Working"
$CoreCreditSAMLLogs = "D:\LOGs\CREDIT\CoreCredit"
$CoreCreditLogs = "D:\LOGs\CREDIT\CoreCreditLogs"

if(($Entry.managedPipelineMode -eq $ExpectedPipelineMode) `
-and ($Entry.state -eq $ExpectedAppPoolState) `
-and ($Entry.enable32BitAppOnWin64 -eq $Expectedenable32BitAppOnWin64) `
-and ($Entry.idleTimeoutAction -eq $ExpectedidleTimeoutAction) `
-and ($Entry.LoadUserProfile -eq $ExpectedLoadUserProfile) `
-and ($Entry.maxProcesses -eq $ExpectedmaxProcesses) `
-and ($Entry.PrivateMemoryLimit -eq $ExpectedPrivateMemoryLimit) `
-and ($Entry.RecyclingPeriodicRestartTime -eq $ExpectedRecyclingPeriodicRestartTime) `
-and ($Entry.AnonymousAuthentication -eq $ExpectedAnonymousAuthentication) `
-and ($Entry.AppPooluserName -eq $ExpectedAppPooluserName) `
-and ($Entry.ConnectAs -eq  $ExpectedConnectAs ) `
-and ($Entry.SiteBindingprotocol -eq $ExpectedSiteBindingprotocol) `
-and ($ReportServerURLSTATUS -eq $ExpectedReportServerURLSTATUS) `
-and ($CoreCreditStatus -eq $ExpectedCoreCreditStatus) `
-and ($CoreCreditWorking -eq $ExpectedCoreCreditWorking) `
-and ($WCFURLSTATUS -eq $ExpectedWCFURLSTATUS) `
-and ($WCFDBBIBEURLSTATUS -eq $ExpectedWCFDBBIBEURLSTATUS) `
-and ($Entry.CoreCreditSAMLLogs -eq $CoreCreditSAMLLogs) `
-and ($Entry.CoreCreditLogs -eq  $CoreCreditLogs ))


{
$Outputreport += "<TR align=center>" 
}else{
$Outputreport += "<TR bgcolor=LightSalmon align=center>"
}

$Outputreport += "<TD>$($Entry.ServerName)</TD>
      <TD align=center>$($Entry.CoreCreditVersion)</TD>
      <TD align=center>$($Entry.enable32BitAppOnWin64)</TD>
      <TD align=center>$($Entry.managedPipelineMode)</TD>
      <TD align=center>$($Entry.state)</TD>
      <TD align=center>$($Entry.idleTimeoutAction)</TD>
      <TD align=center>$($Entry.maxProcesses)</TD>
      <TD align=center>$($Entry.AppPooluserName)</TD>
      <TD align=center>$($Entry.LoadUserProfile)</TD>
      <TD align=center>$($Entry.PrivateMemoryLimit)</TD>
      <TD align=center>$($Entry.RecyclingPeriodicRestartTime)</TD>
      <TD align=center>$($Entry.AnonymousAuthentication)</TD>
      <TD align=center>$($Entry.ConnectAs)</TD>
      <TD align=center>$($Entry.SiteBindingprotocol)</TD>
      <TD align=center>$($Entry.SiteBindingInfo)</TD>
      <TD align=center>$CoreCreditURL $CoreCreditStatus </br> $CoreCreditWorking</TD>
      <TD align=center>$($Entry.ReportServerPath) $ReportServerURLSTATUS </TD>
      <TD align=center>$($Entry.LetterServerPath) $ReportServerURLSTATUS </TD>
      <TD align=center>$($Entry.JSFileVersion)</TD>
      <TD align=center>$($Entry.AccessControlAllowOrigin) </br> $CoreCreditWorking</TD>      
      <TD align=center>$($Entry.WcfAPIEndPointDefault) $WCFURLSTATUS</TD>
      <TD align=center>$($Entry.DbbAPIEndPointDefault) $WCFDBBIBEURLSTATUS</TD>
      <TD align=center>$($Entry.CoreCreditSAMLLogs)</TD>
     <TD align=center>$($Entry.CoreCreditLogs)</TD></TR>"


Clear-Variable CoreCreditURL
Clear-Variable CoreCreditStatus
Clear-Variable CoreCreditWorking
Clear-Variable WCFURLStatus
Clear-Variable WCFDBBIBEURLSTATUS
Clear-Variable ReportServerURLtest


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
Clear-Variable Outputreport
Clear-Variable Environmentpod
Clear-Variable ReportFileNamePrefix
Clear-Variable ReportFile
Clear-Variable WCFAPIEndPointURL
Clear-Variable WCFWebCall
Clear-Variable WCFAPIEndPointURL
Clear-Variable WCFDBBIDAPIEndPointURL
Clear-Variable ReportServerURL
Clear-Variable Entry
