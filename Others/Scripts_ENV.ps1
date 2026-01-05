____________________________________________________________________________________________________________________
STOP SERVICES
____________________________________________________________________________________________________________________
$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach($computername in $ServerList) 
{
write-host  $computername
$services = Get-WmiObject Win32_Service -Computer $computername -filter "Name = 'dbbStartupService' OR Name = 'SNMP' OR Name = 'filebeat' OR Name = 'winlogbeat' OR Name = 'metricbeat' "
$services 
foreach ($service in $services) {
$service.stopservice()
}
}

____________________________________________________________________________________________________________________
KILL PROCESSES
____________________________________________________________________________________________________________________

$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach($computername in $ServerList) 
{
write-host  $computername
$Processes = Get-WmiObject Win32_Process -Computer $computername -filter "Name = 'DbbAppServer.exe' OR Name = 'rundbb.exe'" 
$Processes 
foreach ($process in $processes) {
  $returnval = $process.terminate()
  $processid = $process.handle

if($returnval.returnvalue -eq 0) {
  write-host "The process $ProcessName `($processid`) terminated successfully"
}
else {
  write-host "The process $ProcessName `($processid`) termination has some problems"
}
}

}



____________________________________________________________________________________________________________________
DELETE SHARED MEMORY AND PLATFORM
____________________________________________________________________________________________________________________


$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach($computername in $ServerList) 
{
write-host  $computername
Remove-Item \\$computername\c$\corecard_services\shmem*.bin -Force

Remove-Item \\$computername\d$\CC_Runtime\* -Recurse -Force

}


____________________________________________________________________________________________________________________
UPGRADE CC_Runtime and CoreCard_Services
____________________________________________________________________________________________________________________

$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach($computername in $ServerList) 
{
$computername
robocopy \\qaFS01\Upgrade_Packages\UATP\15Apr2020\Platform_Package_4.2.40.32\Platform\ \\$computername\d$\CC_Runtime\ /e

robocopy \\qaFS01\Upgrade_Packages\UATP\15Apr2020\Platform_Package_4.2.40.32\Dbbstartup\ \\$computername\D$\corecard_services\ /e

}



____________________________________________________________________________________________________________________
CHANGE USER TO CCGSCONFIG
____________________________________________________________________________________________________________________

$password = ConvertTo-SecureString 'RNZ8Ef#:Q2' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ('QA-PLAT\ccgsconfig', $password)

$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt"  
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


____________________________________________________________________________________________________________________
CHANGE USER TO NODOWNTIME
____________________________________________________________________________________________________________________


$password = ConvertTo-SecureString 'Zx(U5CR&Q#' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ('QA-PLAT\nodowntime', $password)

$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt"  
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


____________________________________________________________________________________________________________________
START SERVICES
____________________________________________________________________________________________________________________

$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach($computername in $ServerList) 
{
write-host  $computername
$services = Get-WmiObject Win32_Service -Computer $computername -filter "Name = 'dbbStartupService' OR Name = 'SNMP' OR Name = 'filebeat' OR Name = 'winlogbeat' OR Name = 'metricbeat' "
$services 
foreach ($service in $services) {
$service.startservice()
}
}



@echo off
for /f "tokens=*" %%B  in (Servers.txt) do (
schtasks /run /s %%B /tn Start-DbbAppservers_services
)

pause

Kill--------------

@echo off
for /f "tokens=*" %%B  in (Servers.txt) do (

ECHO Killing on Machine %%B...
taskkill /s%%B /FI "IMAGENAME eq DbbAppServer*" /f

)

==========================
PING
-----------------
$names=Get-Content "Y:\ip.txt"
foreach ($name in $names){
if(Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue){
Write-Host "$name is UP" -ForegroundColor Green
$Output+="$name is UP"+"`n"
}
else{
Write-Host "$name is DOWN" -ForegroundColor Red
$Output+="$name is DOWN"+"`n"
}
}
$Output | Out-File "Y:\pingtest.txt"
Start-Sleep -s 10 

=-=============
#VERIFY PLATFORM
$ServerListFile = "C:\Users\ccgsconfig\Desktop\list\servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue
ForEach($computername in $ServerList)
{
Select-String -Path \\$computername\D$\CC_Runtime\appsys30.dsl -Pattern "Platform Release 4.2."
}


======================
SELECT Program_name,count(distinct hostname) FROM SYSProcesses WHERE
program_name not in ('.Net Sq1Client Data Provider','KMS')
and program_name not like 'SQLAgent -%'
and program_name not like 'Repl-%'
and program_name not like 'Microsoft SQL Server Management%'
GROUP BY Program_name
order by count(distinct hostname) DESC

===========
SELECT Hostname,Program_name,hostprocess FROM SYSProcesses WHERE Program_name IS NOT NULL 
and Program_name <> '' 
and program_name not in ('.Net SqlClient Data Provider','KMS')
and program_name not like 'AlwaysOn%'
and program_name not like 'Repl-%'
and program_name not like 'SQL%'
and program_name not like 'Microsoft%'
and program_name not like 'DatabaseMail -%'
and program_name like '%ReceiveMessageFromCoreAuth%'
--and hostname like '%perf%'
GROUP BY Program_name,Hostname,hostprocess
order by hostname, program_name

====Delete Folder==
$ServerListFile = "E:\Server.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach($computername in $ServerList) 
{
write-host  $computername

Remove-Item \\$computername\e$\CC_Runtime* -Recurse -Force

}
---

TVIEW
$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach($computername in $ServerList)
{
write-host  $computername
$options=New-PSSessionOption -ProxyAccessType NoProxyServer
Invoke-Command -ComputerName $computername -SessionOption $options -ErrorAction Inquire -ScriptBlock { hostname
D:\CC_Runtime\dt.exe -s VirtualTime "04/30/2021"
}
}

==
--Space Chekc --
$ServerListFile = "C:\Users\mahendra.dwivedi\Desktop\as\asd.txt"
$convertToGB = (1024 * 1024 * 1024)
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach($computername in $ServerList)
{
$Disk = get-wmiobject win32_logicalDisk -ComputerName $computername -Filter "DeviceID='D:'" | Select-Object Deviceid,size,freespace
write-host "DiskSpace Size Freespace usedspace"
$out = $computername + " : " + ("{0:N1}" -f($Disk.size / $convertToGB)) + " : " +  ("{0:N1}" -f ($Disk.freespace / $convertToGB)) + " : " + ("{0:N1}" -f (($Disk.size - $Disk.freespace) / $convertToGB)) >> "E:\txt.txt"
}


=======
WITH CTEA AS(select distinct hostname,program_name,hostprocess from sysprocesses with(nolock) JOIN sys.databases ON(sys.databases.database_id=sysprocesses.dbid)where Program_name IS NOT NULL and program_name not in ('.Net SqlClient Data Provider','KMS')and program_name not like 'SQLAgent -%' and program_name not like 'Repl-%' and program_name not like 'Microsoft SQL Server Management%' and program_name not like 'EntityFramework%' and program_name not like 'Microsoft%'
--and Program_name like '%appp%'
--or Program_name like '%appp%'
)SELECT PROGRAM_NAME ,COUNT(1) ProcessCount FROM CTEA A GROUP BY A.Program_name

=============
HTTP Activation
$ServerListFile = "C:\temp\server.txt"Â Â Â Â Â Â Â  $ServerList = Get-Content $ServerListFile -ErrorAction inquireÂ Â Â Â Â Â Â  ForEach ($computername in $ServerList) {Â Â Â Â Â Â Â Â Â Â Â  $option = New-PSSessionOption -ProxyAccessType NoProxyServerÂ Â Â Â Â Â Â Â Â Â Â  write-hostÂ  $computernameÂ Â Â Â Â Â Â Â Â Â Â  Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  Import-Module WebAdministrationÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â  #Enable-WindowsOptionalFeature -Online -FeatureName WCF-Services45Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  Enable-WindowsOptionalFeature -Online -FeatureName WCF-HTTP-Activation45Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  #Enable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-PortSharing45Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  }Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  }

===
Adduser in Administrator Group
Add-LocalGroupMember -Group Administrators -Member TestUser -Verbose