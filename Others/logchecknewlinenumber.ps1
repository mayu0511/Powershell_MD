Clear-Host

$DATE = Get-date -Format MM-dd-yyyy-HH-mm-ss

start-transcript -path D:\Temp\TestPath$DATE.log

$ServerListFile = "D:\CC_Scripts\Servers.txt" 
    $ServerList = Get-Content $ServerListFile -ErrorAction inquire 

 

 $ServerList

 

ForEach($computername in $ServerList)

{

 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000

Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Continue -HideComputerName -ScriptBlock{

 

$report = hostname

 
#$report += Get-Content -Path C:\inetpub\logs\LogFiles\W3SVC2\u_ex230508_x.log | select -Last 2 | Select-String -Pattern "- 50*"
$report += Get-Content -Path C:\inetpub\logs\LogFiles\W3SVC2\u_ex230508_x.log | select -Last 20 | Select-String -Pattern "- 50*"
 

Write-output "********************************************************************************************************************************************"

$report

}

}


Stop-transcript