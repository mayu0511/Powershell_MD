$ServerListFile = "C:\Users\Server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 

Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock{
$TaskName = "Task_*"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -Verbose
}