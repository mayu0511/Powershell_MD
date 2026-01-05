$ServerListFile = "C:\Users\Server.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 

Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock{

$Action = New-ScheduledTaskAction -WorkingDirectory D:\DBBSetup\BatchScripts\CoreIssue -Execute Rundbb_AccountCreation.bat 

$Trigger = New-ScheduledTaskTrigger -AtStartup

$Principal = New-ScheduledTaskPrincipal -UserId cc-jazz-qa\gmsa-batch-svc$ -LogonType Password -RunLevel Highest

Register-ScheduledTask Task_Rundbb_AccountCreation -Action $Action -Trigger $Trigger -Principal $Principal

}
}