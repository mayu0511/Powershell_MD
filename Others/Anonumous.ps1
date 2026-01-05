######################################################################################################################
#AnonymousAuthentication | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

     $ServerListFile = "D:\CC_Scripts\Servers.txt" 
     $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
     ForEach ($computername in $ServerList) {
     write-host  $computername

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
    Import-Module WebAdministration
    Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "CoreIssue" -Name userName -value ""
        
     }}

 