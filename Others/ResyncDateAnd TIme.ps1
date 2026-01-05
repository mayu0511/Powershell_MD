$ServerListFile = "C:\Users\ccgs-app-svc\Desktop\Test\WCF-Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList) {
write-host $computername
$option = New-PSSessionOption -ProxyAccessType NoProxyServer
Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
Net stop w32time
Net start w32time
W32tm /resync
}