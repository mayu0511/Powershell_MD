$ServerListFile = "D:\CC_Scripts\Servers.txt" 
    $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
    ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        $computername=hostname
       
      netsh winhttp show proxy

    }
    }