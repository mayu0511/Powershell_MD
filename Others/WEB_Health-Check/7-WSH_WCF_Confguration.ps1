######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================


        $ServerListFile = "D:\CC_Scripts\server.txt"
        $ServerList = Get-Content $ServerListFile -ErrorAction inquire
        ForEach ($computername in $ServerList) {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer
        write-host  $computername
        Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {

        Import-Module WebAdministration
        New-WebAppPool -Name "HealthWCFApp"
        $userName = "cc-jazz-dev\gmsa-app-svc$"
        $password = ""      
        Set-ItemProperty "IIS:\AppPools\HealthWCFApp" -name processModel -value @{userName = $userName; password = $password; identitytype = 3 }
        Set-ItemProperty "IIS:\AppPools\HealthWCFApp" -Name "processModel.loadUserProfile" -value "True"
        Set-ItemProperty -Path IIS:\AppPools\HealthWCFApp -Name "managedRuntimeVersion" -Value ""
		Set-ItemProperty "IIS:\AppPools\HealthWCFApp" -Name processModel.idleTimeoutAction -Value Suspend
        New-WebApplication -Name "HealthWCFApp" -Site "Webserver" -PhysicalPath "D:\WebServer\ServerHealth\API" -ApplicationPool "HealthWCFApp"
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "Webserver/HealthWCFApp" -Name userName -value ""
        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -PSPath 'IIS:\' -Location "Webserver/HealthWCFApp" -Name "enabled" -Value "True"	
        }        
        }