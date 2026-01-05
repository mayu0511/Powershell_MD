######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================
$ServerListFile = "D:\CC_Scripts\Server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 

$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction inquire -ScriptBlock {
hostname
Import-Module WebAdministration    
New-WebApplication -Name "CoreCardServicesGateway" -Site "Services" -PhysicalPath "D:\WebServer\Services\CoreCardServicesGateway" -ApplicationPool "Services"
}

 

