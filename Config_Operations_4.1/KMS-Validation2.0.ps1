######################################################################################################################
# KMS Servers  Validation  | Updated by : Mahendra Dwivedi
# Version 2.0 | Date:: 20-FEB-2025
#======================================================================================================================

Clear-Host
$Module = "KMS-Validation"
$ServerType = 'kms'
$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
$ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)


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
elseif($S3bucketslist -match "corecard-pod1-$EnvironmentName-$Region-config-files") {$Environmentpod = "pod1"}
elseif(($S3bucketslist -match "corecard-jazz-$EnvironmentName-$Region-config-files") -and ($Environmentattributon -eq "jazz")) {$Environmentpod = "jazz"}
}
}
else{
$Environmentpod = $AWSVarialbes.Pod.ToLower()}
$Environmentpod

$ServerList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial).Name

$MasterHost = $ServerList | Select-Object -First 1

If (Test-Connection $MasterHost -Quiet){
Write-Host "Master Host - " $MasterHost
}
else{
$MasterHost = $ServerList | Select-Object -Last 1
Write-Host "Master Host - " $MasterHost
}


$ExpectedKMSServerCount = 2
if (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "perf") -and ($Environmentattributon -eq "cookie")){$ExpectedKMSServerCount = "7"}
elseif (($EnvironmentName -eq "prod" -or $EnvironmentName -eq "uat2" -or $EnvironmentName -eq "mock") -and ($Environmentattributon -eq "jazz")){$ExpectedKMSServerCount = "7"}

if($Environmentattributon -eq "JAZZ"){$ExpectedDATABASENAME = "CCJAZZ_KMS"}
else{$ExpectedDATABASENAME = "CCGS_KMS"}
$ExpectedKMSVersion = "3.7"
$ExpectedKMSKEYSTATUS = "KMS is active"
$ExpectedIMPORTSETTINGS = "1"
$ExpectedDSNNAME = "LISTPLAT"
$ExpectedWEBPORT = "8081"
$ExpectedWEBHTTPS = "true"
$ExpectedKMserviceuserName = ((whoami).TOLOWER()).Split('\')[0]  + '\gmsa-kms-svc$'
$ExpectedKMSserviceRecoverySettings = "Passed"
$ExpectedKMSConnectionStatus = "True"
$ExpectedKMServiceStatus = "Running"
$ExpectedKMSServiceLogs = "D:\CoreCard\KMS\Service\Data"


$Outputreport = "<HTML><TITLE>KMS Validation Report</TITLE>
                 <BODY background-color:peachpuff>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                 <H2>$($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper()) - $Module Validation Report</H2>
                 <H3>PLEASE VERIFY BELOW TABLE VALUES AND COMPARE WITH EXPECTED VALUES</H3></font>
                 <Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>Master Host</B></TD>
                   <TD><B>KMS Version</B></TD>
                   <TD><B>KMS Hash</B></TD>                   
                   <TD><B>KMS Key Status</B></TD>
                   <TD><B>KMService UserName</B></TD>
                   <TD><B>KMSservice Recovery Settings</B></TD>
                   <TD><B>KMS Connection Status</B></TD>
                   <TD><B>IMPORT SETTINGS</B></TD>
                   <TD><B>DATABASE NAME</B></TD>
                   <TD><B>DSNNAME</B></TD>
                   <TD><B>WEB PORT</B></TD>
                   <TD><B>WEB HTTPS</B></TD>                  
                   <TD><B>KMService Status</B></TD>
                   <TD><B>KMService Logs</B></TD>
                   </TR>"
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$MasterKMSVersionValue =  Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
$MasterKMSVersionValueInternal =  (Get-Command D:\KMS\KMM\KMService.exe).FileVersionInfo.FileVersion
$MasterKMSVersionValueInternal
}

$MasterKMSHash = Invoke-Command -ComputerName $MasterHost -SessionOption $option -ErrorAction inquire -ScriptBlock {
(Get-ChildItem -Path D:\KMS\KMM\KMService.exe.config -Recurse | Get-FileHash).Hash | %{ $MasterKMSHash += "$_"}
$MasterKMS_stream = [IO.MemoryStream]::new([byte[]][char[]]$MasterKMSHash)
$MasterKMSHash = (Get-FileHash -InputStream $MasterKMS_stream).Hash
$MasterKMSHash}
$MasterKMSHash

$Outputreport += "<TR align=center>"
$Outputreport += "<TD>$("$MasterHost".TOUPPER())</TD>
                   <TD>$("$MasterKMSVersionValue")</TD>
                   <TD>True</TD>
                   <TD>$("$ExpectedKMSKEYSTATUS")</TD>
                   <TD>$("$ExpectedKMserviceuserName")</TD>
                   <TD>$("$ExpectedKMSserviceRecoverySettings")</TD>
                   <TD>$("$ExpectedKMSConnectionStatus")</TD>
                   <TD>$("$ExpectedIMPORTSETTINGS")</TD>
                   <TD>$("$ExpectedDATABASENAME")</TD>
                   <TD>$("$ExpectedDSNNAME")</TD>
                   <TD>$("$ExpectedWEBPORT")</TD>
                   <TD>$("$ExpectedWEBHTTPS")</TD>                  
                   <TD>$("$ExpectedKMServiceStatus")</TD>
                   <TD>$("$ExpectedKMSServiceLogs")</TD>
                  </TR>"


$Result = @() 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$result += Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction inquire -ScriptBlock {
$computername = hostname

$KMSVersion = (Get-Command D:\KMS\KMM\KMService.exe).FileVersionInfo.FileVersion
$ServerKMSHash = $NULL
(Get-ChildItem -Path D:\KMS\KMM\KMService.exe.config -Recurse | Get-FileHash).Hash | %{ $ServerKMSHash += "$_"}
$ServerKMS_stream = [IO.MemoryStream]::new([byte[]][char[]]$ServerKMSHash)
$ServerKMSHash = (Get-FileHash -InputStream $ServerKMS_stream).Hash
$KMserviceuserName = Get-WmiObject Win32_Service  -filter "Name = 'KMSService'"

$KMserviceuserName = ($KMserviceuserName).StartName
$IMPORTSETTINGS = (Select-String -Path D:\KMS\KMM\KMService.exe.config -Pattern "IMPORT_SETTINGS").ToString().Split('=')[2] -replace '[" />]',''
$DATABASENAME = (Select-String -Path D:\KMS\KMM\KMService.exe.config -Pattern "DATABASE_NAME").ToString().Split('=')[2] -replace '[" />]',''
#$DATABASEHOST = (Select-String -Path D:\KMS\KMM\KMService.exe.config -Pattern "DATABASE_HOST").ToString().Split('=')[2] -replace '[" />]',''
$DSNNAME = ([xml](Get-Content 'D:\KMS\KMM\KMService.exe.config')).configuration.appSettings.add | Where-Object { $_.key -eq 'CONNECTION_STRING' } | ForEach-Object { $_.value -replace '.*DSN=([^;]+).*','$1' }
$WEBPORT = (Select-String -Path D:\KMS\KMM\KMService.exe.config -Pattern "8081").ToString().Split('=')[2] -replace '[" />]',''
$WEBHTTPS = (Select-String -Path D:\KMS\KMM\KMService.exe.config -Pattern "WEB_HTTPS").ToString().Split('=')[2] -replace '[" />]',''
$KMServiceStatus = (Get-Service -name KMSService).Status


$Service_FAILURE_ACTIONS = sc.exe qfailure "KMSService" -FAILURE_ACTIONS

    if ($Service_FAILURE_ACTIONS) {
       
        $lines = $Service_FAILURE_ACTIONS -split "`n"
        $resetPeriodLine = ($lines | Where-Object { $_ -match 'RESET_PERIOD' }) -replace '.*RESET_PERIOD \(in seconds\)\s*:\s*', ''
        $commandLines = ($lines | Where-Object { $_ -match 'RESTART' }) -replace '.*RESTART -- Delay = ', ''
    
        $Service_FAILURE_ACTIONS_RESET_PERIOD = [int]$resetPeriodLine
        $Service_FAILURE_ACTIONS_FIRST_Failure = ($commandLines[0] -replace ' milliseconds.', '') / 60000
        $Service_FAILURE_ACTIONS_SECOND_Failure = ($commandLines[1] -replace ' milliseconds.', '') / 60000

        $Service_FAILURE_ACTIONS_THIRD_Failure = $Service_FAILURE_ACTIONS_SECOND_Failure

        if ($Service_FAILURE_ACTIONS_RESET_PERIOD -eq 0 -and 
            $Service_FAILURE_ACTIONS_FIRST_Failure -eq 1 -and 
            $Service_FAILURE_ACTIONS_SECOND_Failure -eq 1 -and 
            $Service_FAILURE_ACTIONS_THIRD_Failure -eq 1) {
    
    $KMSserviceRecoverySettings =  "Passed"
} else {
    $KMSserviceRecoverySettings =  "Failed"
}}

 

$KMSKEYSTATUS = $null

$logindata1_c = "C:\CoreCard\KMS\Service\Data\logindata1.dpapi"
$logindata2_c = "C:\CoreCard\KMS\Service\Data\logindata2.dpapi"
$logindata1_d = "D:\CoreCard\KMS\Service\Data\logindata1.dpapi"
$logindata2_d = "D:\CoreCard\KMS\Service\Data\logindata2.dpapi"

$logindata1_c_exists = Test-Path $logindata1_c
$logindata2_c_exists = Test-Path $logindata2_c
$logindata1_d_exists = Test-Path $logindata1_d
$logindata2_d_exists = Test-Path $logindata2_d

if (($logindata1_c_exists -and $logindata2_c_exists) -or ($logindata1_d_exists -and $logindata2_d_exists)) {
    $KMSKEYSTATUS = "KMS is active"
} else {
    $KMSKEYSTATUS = "KMS is not active"
}

$KMSConnectionStatus = (Test-NetConnection $computername -port 1111).TcpTestSucceeded

$KMSServiceLogsTemp = (Select-String -Path "D:\KMS\KMM\KMService.exe.config" -Pattern "DATA_DIRECTORY").ToString().Split('=')[2].Split('"')[1]
$KMSServiceLogs = $KMSServiceLogsTemp -replace '\\\\','\'

If(Test-Path $KMSServiceLogs){
    $KMSLogs = "Passed"
} Else {
    $KMSLogs = "Failed"
}


$resultvalue = @() 
$resultvalue = [PSCustomObject] @{ 
    ServerName = "$($computername)"
    KMSVersion = "$($KMSVersion)"
    ServerKMSHash = "$($ServerKMSHash)"
    KMSKEYSTATUS = "$($KMSKEYSTATUS)"
    KMserviceuserName = "$($KMserviceuserName)"
    KMSserviceRecoverySettings = "$($KMSserviceRecoverySettings)"    
    KMSConnectionStatus = "$($KMSConnectionStatus)"
    IMPORTSETTINGS = "$($IMPORTSETTINGS)"
    DATABASENAME = "$($DATABASENAME)"
    DSNNAME = "$($DSNNAME)"
    WEBPORT = "$($WEBPORT)"
    WEBHTTPS = "$($WEBHTTPS)"    
    KMServiceStatus = "$($KMServiceStatus)"
    KMSServiceLogs = "$($KMSServiceLogs)"


	}
$resultvalue
}


if($Serverlist.Count -eq $ExpectedKMSServerCount)
{
$Outputreport += "</Table>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                   <H2>  KMS Validation Report - Server Count $($result.count) </H2></font>"


}else{
$Outputreport += "</Table>
                 <font color =""#CD5C5C"" face=""Microsoft Tai le"">
                   <H2>  KMS Validation Report - Server Count $($result.count) is not matching with expected count $ExpectedKMSServerCount </H2></font>"


}


$Outputreport += "<Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                   <TD><B>KMS Server</B></TD>
                   <TD><B>KMS Version</B></TD>
                   <TD><B>KMS Hash</B></TD>
                   <TD><B>KMS Key Status</B></TD>
                   <TD><B>KMService UserName</B></TD>
                   <TD><B>KMSservice Recovery Settings</B></TD>                   
                   <TD><B>KMS Connection Status</B></TD>
                   <TD><B>IMPORT SETTINGS</B></TD>
                   <TD><B>DATABASE NAME</B></TD>
                   <TD><B>DSNNAME</B></TD>
                   <TD><B>WEB PORT</B></TD>
                   <TD><B>WEB HTTPS</B></TD>                  
                   <TD><B>KMService Status</B></TD> 
                   <TD><B>KMService Logs</B></TD> 
                                                     
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

 
$IPAddress = (Resolve-DnsName $Entry.ServerName | Where-Object Type -eq "A").IpAddress
$KMSURLStatusDetails = "https://$IPAddress" + ":8081"




if(($MasterKMSVersionValue -eq $Entry.KMSVersion) -and ($Entry.ServerKMSHash -eq $MasterKMSHash) -and ($Entry.KMSKEYSTATUS -eq $ExpectedKMSKEYSTATUS) -and ($Entry.KMServiceUserName -eq $ExpectedKMserviceuserName) -and ($Entry.KMSConnectionStatus -eq $ExpectedKMSConnectionStatus) -and ($Entry.IMPORTSETTINGS -eq $ExpectedIMPORTSETTINGS) -and ($Entry.DATABASENAME -eq $ExpectedDATABASENAME) -and ($Entry.DSNNAME -eq $ExpectedDSNNAME) -and ($Entry.WEBPORT -eq $ExpectedWEBPORT)-and ($Entry.WEBHTTPS -eq $ExpectedWEBHTTPS) -and ($Entry.KMServiceStatus -eq $ExpectedKMServiceStatus) -and ($Entry.KMSserviceRecoverySettings -eq $ExpectedKMSserviceRecoverySettings) -and ($Entry.KMSServiceLogs -eq $ExpectedKMSServiceLogs))
{
$Outputreport += "<TR align=center>" 
}else{
$Outputreport += "<TR bgcolor=LightSalmon align=center>"
}

     

      $Outputreport += "<TD>$($Entry.ServerName)</TD>
                        <TD>$($Entry.KMSVersion)</TD>
                        <TD>$($Entry.ServerKMSHash -eq $MasterKMSHash)</TD>
                        <TD><p>$($Entry.KMSKEYSTATUS)</p></TD>
                        <TD>$($Entry.KMServiceUserName)</TD>
                        <TD>$($Entry.KMSserviceRecoverySettings)</TD>
                        <TD><p>$KMSURLStatusDetails <br> $($Entry.KMSConnectionStatus) </br> </p></TD>
                        <TD>$($Entry.IMPORTSETTINGS)</TD>
                        <TD>$($Entry.DATABASENAME)</TD>
                        <TD>$($Entry.DSNNAME)</TD>
                        <TD>$($Entry.WEBPORT)</TD>
                        <TD>$($Entry.WEBHTTPS)</TD>                       
                        <TD>$($Entry.KMServiceStatus)</TD> 
                        <TD>$($Entry.KMSServiceLogs)</TD> 
                        </TR>"
                        

Clear-Variable IPAddress
Clear-Variable KMSURLStatusDetails



 }
 $Outputreport += "</Table></BODY></HTML>" 

$ReportFileNamePrefix = $Module +"_Validation_"
$ReportFile = "C:\Temp\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | out-file "$ReportFile"
aws s3 cp $ReportFile "s3://corecard-$Environmentpod-$EnvironmentName-$Region-config-files/EnvironmentValidationReports/$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd).html"

if($host.Name -eq "Windows PowerShell ISE Host"){Invoke-Item $ReportFile}

Clear-Variable Module
Clear-Variable result
Clear-Variable Outputreport
Clear-Variable Environmentattributon
Clear-Variable MasterHost
Clear-Variable ExpectedKMSKEYSTATUS
Clear-Variable ExpectedKMSConnectionStatus
Clear-Variable MasterKMSVersionValue
Clear-Variable MasterKMSHash
Clear-Variable ExpectedKMSserviceRecoverySettings
Clear-Variable ExpectedKMSServiceLogs