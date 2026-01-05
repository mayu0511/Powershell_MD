
<# To View Secret Key #>
aws secretsmanager get-secret-value --secret-id PERF/cc-pod2-ssh-pkey --region us-east-1 
Get-SECSecretValue -SecretId PERF/cc-pod2-ssh-pkey

<# To Set Trace Flags #>
$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorActi6n inquire -ScriptBlock { hostname 
        D:\CC_Runtime\dt.exe -s ODBC 0
    }
}



<# To View Processes #>
$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\PERF-TNP-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
    write-host $computername 
    $processes = Get-WmiObject Win32_Process -Computer $computername -filter "Name LIKE '%rundbb_ETNP%.exe'" 
    write-host " $processes.ProcessName ($processid) "
}

<# To KILL Process#>
$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\PERF-TNP-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
    write-host $computername 
    $processes = Get-WmiObject Win32_Process -Computer $computername -filter "Name LIKE '%rundbb_ETNP%.exe'"  
    $processes.ProcessName 
    foreach ($process in $processes) { 
        $returnval = $process.terminate() 
        $processid = $process.handle 
        if ($returnval.returnvalue -eq 0) {
            write-host "THe process $ProcessName ($processid) terminated successfully" 
        } 
        else {
            write-host "THe process $ProcessName ($processid) termination has some problem" 
        } 
    } 
}


<# To START Process#>
 
$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\PERF-TNP-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock 
    {
        hostname 
        Get-ScheduledTask -TaskName "Start-TNP" | Start-ScheduledTask 
    } 
}  


schtasks /run /s \\$cn /TN $taskname

<# To Install Certificate in Trusted Root#>

$ServerListFile = "C:\Temp\WCFServers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    robocopy \\ccwcfelmockbl\C$\Temp\Cert\ \\$computername\C$\Temp\Cert\ /e 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock { 
        hostnamel 
        Import-Certificate -FilePath "C:\Temp\Cert\Corelssue.cer" -CertStoreLocation 'Cert:\LocalMachine\Root' -Verbose 
    }
} 



<# To Copy files#>
$ServerListFile = "C:\Temp\WCFServers.txt1"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    robocopy \\ccwcfelmockbl\D$\WebServer\WCF\configuration\ \\$computername\D$\WebServer\WCF\configuration\ /e 
    robocopy \\ccQcfelmockbl\D$\WebServer\CoreCardServices\ \\$computername\D$\WebServer\CoreCardServices\ /e 
    robocopy \\ccwcfelmockbl\C$\Temp\host\ \\$computername\C$\Windows\System32\drivers\etc\ /e
}




<# Create Sceduled Job #>
$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\PERF-SVC-Servers2.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        hostname 
        try { 
            $in_domain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain 
            $process_active = Get-Process rundbb -ErrorAction SilentlyContinue 
            Write-Output "[DEBUG] in_domain: $in_domain" 
            Write-Output "[DEBUG] process_active: $process_active" 
            if (($in_domain -eq $true) -and ($process_active -eq $null)) { 
                Write-Output "[DEBUG] Configuring Service Server"
                # Add-OdbcDsn -Name LISTPLAT -DriverName "ODBC Driver 17 for SQL Server" -DsnType System -Platform "32-bit" -SetPropertyValue @("Server=CCAppSQLAG1", "Description=CCAppSQLAG1", "Encrypt=No", "TrustServerCertificate=No", "Trusted_Connection=Yes", "MultiSubnetFailover=Yes") 

                # Read-53Object -BucketName corecard-pod2-perf-us-east-l-config-files -Key AppConfig/SetupCl.bat -File D:\DBBSetup\BatchScripts\Corelssue\SetupCl.bat 
                $SecretObj = (Get-SECSecretValue -Secretid "PERF/app-service-secret") 
                $Secret = $SecretObj.SecretString | ConvertFrom-Json 

                $A = New-ScheduledTaskAction -Execute "D:\DBBSetup\BatchScripts\CoreIssue\2.CIAppServerServices.bat" -WorkingDirectory "D:\DBBSetup\BatchScripts \Corelssue" -Argument "-passthru -NoNewWindow" 
                $T = New-ScheduledTaskTrigger -AtStartup 
                $P = New-ScheduledTaskPrincipal -Userid $Secret.username 
                $S = New-ScheduledTaskSettingsSet 
                $D = New-ScheduledTask -Action $A -Trigger $T -Principal $P -Settings $S
                Register-ScheduledTask -InputObject $D -Password $Secret.password -TaskName Start-svc -User $Secret.username 
                #Start-ScheduledTask -TaskName "Start-svc" -AsJobl Write-Output "[DEBUG] Completed Service Server" 
            }
            else { 
                Write-Output "[DEBUG] Domain value is $in_domain and process is $process_active (null)" 
            } 
        }
        Catch {
            Write-Error "[DEBUG] Unable to Start Core-Services" 
        } 
    } 

}



<# To list all EC2 instances#>

$Instance_details = (aws ec2 describe-instances --filters "Name=tag:Name,Values=*ccsvcw2*" "Name=tag:environment,Values=PROD" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].{Instance:InstanceId,IpAddress:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --region "us-west-2" ) | ConvertFrom-Json
$Instance_details.Name | Sort-Object $_.Name > C:\Serverlist.txt


aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*ccweb*'" "Name=availability-zone,Values=us-west-2c" "Name=tag:environment,Values=PROD" --region "us-west-2" --output table

aws ec2 describe-instances --query "Reservations[*].Instances[*].{InstanceId:InstanceId, AvailabilityZone:Placement.AvailabilityZone, IpAddress:PrivateIpAddress, Type:InstanceType, Name:Tags[?Key=='Name']|[0].Value, Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*ccweb*'" "Name=availability-zone,Values=us-west-2c" "Name=tag:environment,Values=PROD" --region "us-west-2" --output table


$Instance_details = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*ccweb*'" "Name=availability-zone,Values=us-west-2c" "Name=tag:environment,Values=PROD" --region "us-west-2" ) | ConvertFrom-Json
$Instance_details.Name | Sort-Object $_.Name > C:\Serverlist.txt

$totalServers = $Instance_details | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$env")[1] } } `
| Sort-Object -Property serial
#$totalServers
$totalServers_g1 = $totalServers.Name
$totalServers_g1 


$ServerType = Read-Host("Enter Server Type : SVC, AUT, ISS, SRC, SK, TNP, WF, WCF, BAT, WEB ")
$ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType*'" "Name=availability-zone,Values='*'" --region (Get-EC2InstanceMetadata -Category Region).SystemName | ConvertFrom-Json
$ServerList.Name

<# To STOP IIS #>

$ServerListFile = "C:\Users\ccgsconfig\Desktop\Test\WCF\WCF_A.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList) {
    write-host  $computername
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock { 
        IISRESET /STOP }
}



$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\Web-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock 
    {
        hostname 
        Stop-IISSite -Name "CoreCreditSiteName" 
    } 
}  




$ServerListFile = "C:\Users\ccgsconfig\Desktop\Test\Servers.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue 
ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock { hostname
        D:\CC_Runtime\dt.exe -s VirtualTime "Value"
    }
}

<# To Set Application pool user #>

$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock 
    {
        write-host  $computername
        Import-Module WebAdministration
        $userName = "CC-POD2-PERF\ccgs-app-svc"
        $password = "password"      
        Set-ItemProperty "IIS:\AppPools\WCF" -name processModel -value @{userName = $userName; password = $password; identitytype = 3 }
        Set-ItemProperty "IIS:\AppPools\CoreCardServices" -name processModel -value @{userName = $userName; password = $password; identitytype = 3 }
    }
}


<# To Set user in Basic Setting of Website and Applications #>

$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock 
    {
        write-host  $computername
        $userName = "CC-POD2-PERF\ccgs-app-svc"
        $password = "password"
        
        Set-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/']/VirtualDirectory[@path='/']" -Value @{userName = $userName; password = $password }
        Set-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/WCF']/VirtualDirectory[@path='/']" -Value @{userName = $userName; password = $password }
        Set-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/CoreCardServices']/VirtualDirectory[@path='/']" -Value @{userName = $userName; password = $password }
    }
}






____________________________________________________________________________________________________________________
STOP   SERVICES
____________________________________________________________________________________________________________________
$ServerListFile = "C:\Users\ccgsconfig\Desktop\Test\WEBServers\WebServers3.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
    write-host  $computername
    $services = Get-WmiObject Win32_Service -Computer $computername -filter "Name = 'DbbScaleService'" 
    $services 
    foreach ($service in $services) {
        $service.stopservice()
    }
}

____________________________________________________________________________________________________________________
KILL PROCESSES
____________________________________________________________________________________________________________________

$ServerListFile = "C:\Users\ccgsconfig\Desktop\Test\WEBServers\WebServers3.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList) {
    write-host  $computername
    $Processes = Get-WmiObject Win32_Process -Computer $computername -filter "Name = 'dbbScaleService.exe'" 
    $Processes 
    foreach ($process in $processes) {
        $returnval = $process.terminate()
        $processid = $process.handle

        if ($returnval.returnvalue -eq 0) {
            write-host "The process $ProcessName `($processid`) terminated successfully"
        }
        else {
            write-host "The process $ProcessName `($processid`) termination has some problems"
        }
    }

}



$ServerListFile = "C:\Users\ccgsconfig\Desktop\Test\WEBServers\WebServers3.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
    write-host  $computername
    $services = Get-WmiObject Win32_Service -Computer $computername -filter "Name = 'DbbScaleService'" 
    $services 
    foreach ($service in $services) {
        $service.startservice()
    }
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock { hostname
        IISRESET }
}




<# To cceck site binding #>

$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock 
    {
        write-host  $computername
        Import-Module WebAdministration
        Get-Children -Path IIS:\Sites | findstr 'CoreCredit'
    }


    <# To cceck site binding #>

    $ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
    $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
    ForEach ($computername in $ServerList) { 
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
        Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock 
        {
            write-host  $computername
            Import-Module WebAdministration
            Stop-IISSite -Name "Default Web Site"
        }



        <# To check all all IIS bindings #>

        $ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
        $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
        ForEach ($computername in $ServerList) { 
            $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
            Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
                write-host  $computername
                Import-Module -Name WebAdministration

                Get-ChildItem -Path IIS:SSLBindings | ForEach-Object -Process `
                {
                    if ($_.Sites) {
                        $certificate = Get-ChildItem -Path CERT:LocalMachine/My |
                        Where-Object -Property Thumbprint -EQ -Value $_.Thumbprint
        
                        [PsCustomObject]@{
                            Sites                   = $_.Sites.Value
                            CertificateFriendlyName = $certificate.FriendlyName
                            CertificateDnsNameList  = $certificate.DnsNameList
                            CertificateNotAfter     = $certificate.NotAfter
                            CertificateIssuer       = $certificate.Issuer
                        }
                    }
                }
            }
        }


        <# To verify app pool identity #>

        $ServerListFile = "C:\Users\jayesh.dholi\Desktop\Alert\server\server.txt"
        $ServerList = Get-Content $ServerListFile -ErrorAction inquire
        ForEach ($computername in $ServerList) {
            $option = New-PSSessionOption -ProxyAccessType NoProxyServer
            write-host  $computername
            Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
       
                Import-Module WebAdministration
    
                Get-ItemProperty IIS:\AppPools\WCF | select -ExpandProperty processModel | select -expand userName
            }        
        }"

# To Set the item propert of the app pool- enable 32 bit application to true
$ServerListFile = "C:\Users\jayesh.dholi\Desktop\Alert\server\server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {

 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$appPoolName='Dashboard'
write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        
        Import-Module WebAdministration
        
        Set-ItemProperty IIS:\apppools\$using:appPoolName -Name enable32BitAppOnWin64 -Value 'true'
        Set-ItemProperty IIS:\apppools\$using:appPoolName -Name processModel.maxProcesses -Value 64
         }}

 
 
 
 # To Get the item propert of the app pool- enable 32 bit application to true
$ServerListFile = "C:\Users\jayesh.dholi\Desktop\Alert\server\server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$appPoolName='Dashboard'
write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        
        Import-Module WebAdministration
        
        Get-ItemProperty IIS:\AppPools\$using:appPoolName | select *

         }}

 

 <# To set Custome log in site #>

$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    write-host  $computername
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
    
        Import-Module WebAdministration
        New-ItemProperty 'IIS:\Sites\Services' -Name logfile.customFields.collection -Value @{logFieldName='X-Request-ID';sourceType='RequestHeader';sourceName='X-Request-ID'}
        
}
}


 <# To resync time#>

 $ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
 $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
 ForEach ($computername in $ServerList) { 
     write-host  $computername
     $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
     Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        Net stop w32time
        Net start w32time
        W32tm /resync
 }
 
}

 <# To change time zone#>

 $ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
 $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
 ForEach ($computername in $ServerList) { 
     write-host  $computername
     $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
     Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        set-timezone -ID "Eastern Standard Time"
 }
 
 
  <# To compare time #>
net time \\CCSRCE1PERF1 | findstr time
net time \\CCSRCE1PERF2 | findstr time
net time \\CCSRCE1PERF3 | findstr time
net time \\CCSRCE1PERF4 | findstr time
net time \\CCSRCE1PERF5 | findstr time

#VERIFY PLATFORM
$ServerListFile = "C:Temp\servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach($computername in $ServerList)
{
Select-String -Path \\$computername\D$\CC_Runtime\appsys30.dsl -Pattern "Platform Release 4.2."
}


#VERIFY WCF and CoreCardServices
$ServerListFile = "C:Temp\servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach($computername in $ServerList)
{
(Get-Command \\$computername\D$\WebServer\WCF\bin\CC.CoreServices.common.dll).FileVersionInfo.FileVersion} >> C:\Temp\WCF-Version.txt
(Get-Command \\$computername\D$\WebServer\CoreCardServices\bin\CC.HP.Api.dll).FileVersionInfo.FileVersion} >> C:\Temp\CCS-Version.txt
}


<# To Install ARR#>

$ServerListFile = "C:\Users\ccgs-web-svc\Desktop\Test\Servers\WebServers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    write-host  $computername
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
$FilePath= "C:\Temp\ARRv3_setup_amd64_en-us.exe"
$silent= '/Q'
$PSpath= "MACHINE/WEBROOT/APPHOST"
$Filter= "/system.webServer/proxy"
Try{
   Start-Process -FilePath $FilePath -ArgumentList $silent -Wait -NoNewWindow
   Set-WebConfigurationProperty -pspath $PSpath -filter $Filter -name "." -value @{enabled="true"}
}
Catch{
   Write-Host $_
       Exit 1
}

}
}

<# To Check IsOnline API#>
$WebSiteListFile = "C:\Users\utsav.tyagi\Desktop\Test\7\SiteList.txt" 
$WebSiteList = Get-Content $WebSiteListFile -ErrorAction inquire 
ForEach ($WebSite in $WebSiteList) {

    write-host $WebSite
	$WebResponseObj = Invoke-WebRequest -Uri $WebSite
	
	


 if (($WebResponseObj.Content -eq "LoginFailure") -and ($WebResponseObj.StatusCode -eq 200)) {
            write-host "IsOnline API Working" 
        } 
        else {
            write-host "IsOnline API Failed" 
        } 
Clear-Variable -name WebResponseObj
}





<# Version Finder #>

#$scriptenv = 'prod'
$scriptenv = Read-Host "Enter Environment Name like : DEV, QA, UAT, PATQA, PATUAT, PERF, PROD "
$env = ($scriptenv).ToUpper()
$ec2region = Get-EC2InstanceMetadata -Category Region
$scriptregion = $ec2region.SystemName
$region =  $ec2region.SystemName
if($region -eq "us-west-2"){
$ShortRegion = "W"}
if($region -eq "us-east-1"){
$ShortRegion = "E"}
$ServerTypes = 'SVC', 'ISSU', 'AUTH', 'TNP', 'WKFW', 'SRC', 'SINK', 'BAT'
ForEach($ServerType in $ServerTypes)
{
$targets= (Get-ADComputer -Filter "Name -like '*$ServerType$ShortRegion*'")


#$targetjoin=$targets -join ','
$totalServers = $targets | Select-Object @{n="Name"; e={$_.Name}},@{n="serial"; e={[double]($_.Name -split "$env")[1]}} `
 | Sort-Object -Property serial
#$totalServers
#$totalServers_g1 = $totalServers.Name

ForEach($computername in $totalServers.Name)
{
Select-String -Path \\$computername\D$\CC_Runtime\appsys30.dsl -Pattern "Platform Release 4.2."
}
}

#<# to get binding information for a website #>

$ServerListFile = "C:\Temp\server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        
        Import-Module WebAdministration
        
        Get-IISSite -Name "CoreIssue"  | select Bingings
        
         }}

#<# to remove http binding from website #>
$ServerListFile = "C:\Temp\server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        
        Import-Module WebAdministration
        
        Get-Website -Name "CoreIssue"  | Get-WebBinding -Protocol "http" -Port 80  | Remove-WebBinding
        
         }}
		 

#<# to get the ID of website  #>
$ServerListFile = "C:\Temp\server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        
        Import-Module WebAdministration
        
        Get-ItemProperty -Path 'IIS:\Sites\CoreIssue'  | select ID,PSChildname,physicalpath
        
         }}
		 
		 
#<# to disbale the IIS loging of Particular website  #>
$ServerListFile = "C:\Temp\server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {        
        Import-Module WebAdministration        
        Set-ItemProperty -Path 'IIS:\Sites\CoreIssue' -Name Logfile.enabled -Value $false
        
    }
}



$ServerListFile = "C:\Temp\WEbServer.txt"
 $ServerList = Get-Content $ServerListFile -ErrorAction inquire
 ForEach ($computername in $ServerList) {
 write-host  $computername
 $option = New-PSSessionOption -ProxyAccessType NoProxyServer
 $sess = New-PSSession -ComputerName $computername -SessionOption $option
 Enter-PSSession $sess
 Import-Module WebAdministration
 Set-ItemProperty -Path 'IIS:\Sites\Services' -Name Logfile.enabled -Value $false
 Exit-PSSession
 Remove-PSSession $sess
 }
         
		 
$ServerListFile = "C:\Temp\WEbServer.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList) {
write-host  $computername
$option = New-PSSessionOption -ProxyAccessType NoProxyServer
$sess = New-PSSession -ComputerName $computername -SessionOption $option
Enter-PSSession $sess
Import-Module WebAdministration
Set-ItemProperty -Path 'IIS:\Sites\VMPACKAGE02' -Name Logfile.enabled -Value $false
Exit-PSSession
Remove-PSSession $sess
}

#<# to disbale the IIS loging of Particular website  #>
$ServerListFile = "C:\Temp\server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
write-host  $computername
    Remove-Item \\$computername\c$\inetpub\logs\logfiles\w3svc1\* -Recurse -Force
        
         }}		 


 #<# To Find multiple patterns in a file  #>
Select-String -Path D:\PROJECTS\PLAT\Backup\POD2-PROD\4Jan2022\BAT1-VC-Settings\Jobs.xml -Pattern '(<Name>)|(CmdLine)|(Arguments)' > BAT1.txt

Select-String -Path D:\PROJECTS\PLAT\Backup\POD2-PROD\4Jan2022\BAT4-VC-Settings\Jobs.xml -Pattern '(<Name>)|(CmdLine)|(Arguments)' | select-object -ExpandProperty Line | out-file BAT4.txt





#<# ToCHANGE USER IN SERVICE #>

$password = ConvertTo-SecureString 'Test123!' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ('PERF-PLAT\ccgsconfig', $password)

$ServerListFile = "C:\Users\ccgsconfig\Desktop\Test\Servers.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach($computername in $ServerList) 
{
write-host  $computername
$services = Get-WmiObject Win32_Service -Computer $computername -filter "Name = 'dbbStartupService'" 
$services.Change($null,
   $null,
   $null,
   $null,
   $null,
   $null,
   $credential.UserName,
   $credential.GetNetworkCredential().Password,
   $null,
   $null,
   $null
 ) 
}

#<# TO DISABLE/ENABLE SERVICE #>

	$ServerListFile = "C:\Temp\WebServers3.txt"  
	$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
	ForEach($computername in $ServerList) 
	{
	write-host  $computername
	$services = Get-WmiObject Win32_Service -Computer $computername  -filter "Name = 'W3SVC'" 
	$services 
	foreach ($service in $services) {
	$service.stopservice()
	$service.ChangeStartMode("Disabled")    
	#$service.ChangeStartMode("Automatic")	
    #$service.startservice()
	}
	}
	


    #<# Change Application Pool Idle Time out Action #>
    $ServerListFile = "C:\Temp\server.txt" 
    $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
    ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        hostname
        Import-Module WebAdministration
        Set-ItemProperty "IIS:\AppPools\WCF" -Name processModel.idleTimeoutAction -Value Suspend
        
    }
    }

    #<# To Set System Environment Variable PATH #>
    if (($Env:PATH.Substring($Env:PATH.length - 1)) -eq "; "){
        [Environment]::SetEnvironmentVariable("PATH", $Env:PATH + "D:\CC_Python", [EnvironmentVariableTarget]::Machine)
        }else{
        [Environment]::SetEnvironmentVariable("PATH", $Env:PATH + "; D:\CC_Python", [EnvironmentVariableTarget]::Machine)}
        

    #<# To Check .NET framework version #>
    [System.Runtime.InteropServices.RuntimeInformation]::get_FrameworkDescription()
<<<<<<< .mine




#< TO FIND THE FILE>
Get-ChildItem -Path \\$Server\D$\CC_runtime\ -Include *_TRANSLATE_*.txt -File -Recurse -ErrorAction Inquire||||||| .r1521854
=======

# SQL Connection with Poweshell Command
# https://www.sqlshack.com/working-with-powershells-invoke-sqlcmd/

$SQLServer = "CCAPPSQLAG1"
$db3 = "CCJAZZ_CoreIssue"
#$droptable = "DROP TABLE invokeTable"
#$createtable = "CREATE TABLE invokeTable (Id TINYINT, IdData VARCHAR(5))"
#$insertdata = "INSERT INTO invokeTable VALUES (1,'A'), (2,'B'), (3,'C'), (4,'E'),(5,'F')"
#$updatedata = "UPDATE invokeTable SET IdData = 'D' WHERE Id = 4"
#$deletedata = "DELETE FROM invokeTable WHERE Id = 5"
#$selectdata = "SELECT top 1 *  FROM version with(nolock) order by entryid desc"
 
#Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db3 -Query $createtable
#Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db3 -Query $insertdata
#Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db3 -Query $updatedata
#Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db3 -Query $deletedata
Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db3 -Query $selectdata 
>>>>>>> .r1687831


<# To Set Load user Profile to true in Application pool user #>
<# To Get Load user Profile value of Application pool user #>

$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock 
    {
        write-host  $computername
        Import-Module WebAdministration
        $userName = "CC-POD2-PERF\ccgs-app-svc"
        $password = "password"      
        Set-ItemProperty "IIS:\AppPools\WCF" -Name "processModel.loadUserProfile" -value "True"
        #Get-ItemProperty "IIS:\AppPools\WCF" -Name "processModel.loadUserProfile.Name"
        #Get-ItemProperty "IIS:\AppPools\WCF" -Name "processModel.loadUserProfile.Value"
        
    }
}