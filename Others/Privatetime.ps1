$ServerListFile = "D:\CC_Scripts\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {

 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 

write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        $applicationPoolsPath = "/system.applicationHost/applicationPools"
        $appPoolPath = "$applicationPoolsPath/add[@name='Services']"
        
        Import-Module WebAdministration
        Set-WebConfiguration "$appPoolPath/Recycling/periodicRestart/@privateMemory" -Value 400000
        Get-WebConfiguration "$appPoolPath/recycling/periodicRestart/@privateMemory"
       
         }}


        