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
        New-WebAppPool -Name "HealthServiceApp"
        $userName = "cc-jazz-dev\gmsa-web-svc$"
        $password = ""      
        Set-ItemProperty "IIS:\AppPools\HealthServiceApp" -name processModel -value @{userName = $userName; password = $password; identitytype = 3 }
        Set-ItemProperty "IIS:\AppPools\HealthServiceApp" -Name "processModel.loadUserProfile" -value "True"
        Set-ItemProperty -Path IIS:\AppPools\HealthServiceApp -Name "managedRuntimeVersion" -Value ""
		Set-ItemProperty "IIS:\AppPools\HealthServiceApp" -Name processModel.idleTimeoutAction -Value Suspend
        New-WebApplication -Name "HealthWebServerApp" -Site "Services" -PhysicalPath "D:\WebServer\ServerHealth\API" -ApplicationPool "HealthServiceApp"
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "Services/HealthWebServerApp" -Name userName -value ""
        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -PSPath 'IIS:\' -Location "Services/HealthWebServerApp" -Name "enabled" -Value "True"	
        }        
        }