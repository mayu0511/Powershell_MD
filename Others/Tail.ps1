$DATE = Get-date -Format MM-dd-yyyy-HH-mm-ss

start-transcript -path D:\Temp\TestPath$DATE.log
$ServerListFile = "D:\CC_Scripts\Servers.txt" 
    $ServerList = Get-Content $ServerListFile -ErrorAction inquire 
    ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    write-host  $computername
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        $computername=hostname
       
      #GEt-content C:\inetpub\logs\LogFiles\W3SVC2\u_ex230508_x.log -tail 1000
      GEt-content D:\WebServer\ScaleService\Log\scaleservice.log -tail 100
      

    }
    }
    Stop-transcript