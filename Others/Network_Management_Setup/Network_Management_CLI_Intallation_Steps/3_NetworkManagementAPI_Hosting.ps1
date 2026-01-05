#To Convert folder to an application 
        $ServerListFile = "D:\backup\LIST\servers.txt"
        $ServerList = Get-Content $ServerListFile -ErrorAction inquire
        ForEach ($computername in $ServerList) {
            $option = New-PSSessionOption -ProxyAccessType NoProxyServer
            write-host  $computername
            Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {

                Import-Module WebAdministration
                New-WebAppPool -Name "NetworkManagementAPI"
        $userName = "cc-jazz-prod\gmsa-app-svc$"
        $password = ""      
        Set-ItemProperty "IIS:\AppPools\NetworkManagementAPI" -name processModel -value @{userName = $userName; password = $password; identitytype = 3 }
        Set-ItemProperty "IIS:\AppPools\NetworkManagementAPI" -Name "processModel.loadUserProfile" -value "True"
        Set-ItemProperty -Path IIS:\AppPools\NetworkManagementAPI -Name "managedRuntimeVersion" -Value ""
		Set-ItemProperty "IIS:\AppPools\NetworkManagementAPI" -Name processModel.idleTimeoutAction -Value Suspend
        New-WebApplication -Name "NetworkManagementAPI" -Site "WebServer" -PhysicalPath "D:\WebServer\NetworkManagementAPI" -ApplicationPool "NetworkManagementAPI"
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication'  -PSPath 'IIS:\' -Location "WebServer/NetworkManagementAPI" -Name userName -value ""

            }        
        }