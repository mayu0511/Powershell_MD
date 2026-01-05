$serverlistfile= "C:\Ser.txt"
$serverlist= Get-Content $serverlistfile -ErrorAction Inquire
foreach ($computername in $serverlist){
Write-host $computername
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock{
$cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time'
$cpuPercentage = $cpuUsage.CounterSamples.CookedValue
Write-Host "CPU Usage: $cpuPercentage%"
$memoryUsage = Get-Counter '\Memory\% Committed Bytes In Use'
$memoryPercentage = $memoryUsage.CounterSamples.CookedValue
Write-Host "Memory Usage: $memoryPercentage%"
}
}