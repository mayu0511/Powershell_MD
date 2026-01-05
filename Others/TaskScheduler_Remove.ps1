######################################################################################################################
# TaskScheduler Remove  | DEVELOPED BY:: Netra Chettri
# Version 1.0 | Initial Release | Date:: 24-Nov-2025
#=====================================================================================================================

$ServerListFile = "D:\Backup\LIST\servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

ForEach ($computername in $ServerList) {

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    Write-Host "`nRemoving Scheduled Task on $computername ..."

    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {

        $TaskName = "Task_Rundbb_BulkSOLDAPICall"

        # Check if the task exists
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "Task removed: $TaskName"
        }
        else {
            Write-Host "Task not found: $TaskName"
        }
    }
}
