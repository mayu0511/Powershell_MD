$ServerListFile = "D:\ServerList.txt" 
    $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
    ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        hostname
        Import-Module WebAdministration
        $IdleTimeoutMinutes = "240"
        #Set-ItemProperty "IIS:\AppPools\DBBWEB" -Name processModel.idleTimeout -Value $IdleTimeoutMinutes
        Set-WebConfigurationProperty -filter "system.applicationHost/applicationPools/add[@name='Services']/processModel" -name "idleTimeout" -value "04:00:00"

    }
    }