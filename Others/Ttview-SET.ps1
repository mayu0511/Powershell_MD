$ServerListFile = "C:\Users\ccgsconfig\Documents\Mahendra\Servers1.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach($computername in $ServerList)
{
write-host  $computername
$options=New-PSSessionOption -ProxyAccessType NoProxyServer
Invoke-Command -ComputerName $computername -SessionOption $options -ErrorAction Inquire -ScriptBlock { hostname
D:\CC_Runtime\dt.exe -s VirtualTime "04/30/2021"
}
}
