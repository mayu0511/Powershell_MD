$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock   {
        write-host  $computername
        Import-Module WebAdministration
        $userName = "CC-POD2-PERF\ccgs-app-svc"
        $password = "password"      
        Set-ItemProperty "IIS:\AppPools\WCF" -name processModel -value @{userName = $userName; password = $password; identitytype = 3 }
        #Set-ItemProperty "IIS:\AppPools\CoreCardServices" -name processModel -value @{userName = $userName; password = $password; identitytype = 3 }
    }
}