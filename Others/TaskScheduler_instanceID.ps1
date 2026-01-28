######################################################################################################################
#Task Scheduled | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date::25-Jul-2025
#=====================================================================================================================

$ServerListFile = "D:\BCKUP\server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

foreach ($ComputerName in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    Invoke-Command -ComputerName $ComputerName -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        $action = New-ScheduledTaskAction -Execute "D:\DBBSetup\BatchScripts\CoreIssue\RunccCI.bat" -Argument "1 7012" -WorkingDirectory "D:\DBBSetup\BatchScripts\CoreIssue"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "cc-pod2-perf\gmsa-app-svc$" -LogonType Password -RunLevel Highest
        Register-ScheduledTask -TaskName "Task_TNP" -Action $action -Trigger $trigger -Principal $principal -Force

        Write-Host "Task_TNP created on $env:COMPUTERNAME" -ForegroundColor Green
    }
}
