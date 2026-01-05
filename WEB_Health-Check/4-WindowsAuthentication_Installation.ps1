######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$ServerListFile = "D:\CC_Scripts\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList)
{ 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer
write-host  $computername
Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
Import-Module WebAdministration
Install-WindowsFeature Web-Windows-Auth


}                
}
