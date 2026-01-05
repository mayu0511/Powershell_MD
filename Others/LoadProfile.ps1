$ServerListFile = "D:\CC_Scripts\Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {

 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
$appPoolName='Services'
write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        
        Import-Module WebAdministration
        
        #Set-ItemProperty IIS:\apppools\$using:appPoolName -Name enable32BitAppOnWin64 -Value 'False'
        Set-ItemProperty IIS:\apppools\$using:appPoolName -Name processModel.loadUserProfile -Value true
        #Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "CoreIssue" -Name userName -value ""
        
         }}

 