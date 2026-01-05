######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$ServerListFile = "D:\Backup\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

ForEach ($computername in $ServerList) {
    Write-Host "Checking service on $computername"
    
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        $serviceName = "KMSService"
        $Service_FAILURE_ACTIONS = sc.exe qfailure $serviceName
        
        $Service_FAILURE_ACTIONS_RESET_PERIOD = $NULL
        $Service_FAILURE_ACTIONS_FIRST_Failure = $NULL
        $Service_FAILURE_ACTIONS_SECOND_Failure = $NULL
        $Service_FAILURE_ACTIONS_THIRD_Failure = $NULL

        foreach ($line in $Service_FAILURE_ACTIONS) {
            if ($line -match "RESET_PERIOD\s+: (\d+)") {
                $Service_FAILURE_ACTIONS_RESET_PERIOD = $matches[1]
            }
            if ($line -match "ACTION\[(\d+)\].*? (\d+) milliseconds") {
                if ($matches.Count -ge 2) {
                    switch ($matches[1]) {
                        0 { $Service_FAILURE_ACTIONS_FIRST_Failure = [int]$matches[2] / 60000 }
                        1 { $Service_FAILURE_ACTIONS_SECOND_Failure = [int]$matches[2] / 60000 }
                        2 { $Service_FAILURE_ACTIONS_THIRD_Failure = [int]$matches[2] / 60000 }
                    }
                }
            }
        }

        if ($Service_FAILURE_ACTIONS_RESET_PERIOD -ne 0) {
            Write-Output "[$env:COMPUTERNAME] FAILED: Reset Period is not defined."
        } else {
            Write-Output "[$env:COMPUTERNAME] PASSED: Reset Period = $Service_FAILURE_ACTIONS_RESET_PERIOD"
        }

        if ($Service_FAILURE_ACTIONS_FIRST_Failure -ne 1) {
            Write-Output "[$env:COMPUTERNAME] FAILED: No first failure action defined."
        } else {
            Write-Output "[$env:COMPUTERNAME] PASSED: First Failure = $Service_FAILURE_ACTIONS_FIRST_Failure min"
        }

        if ($Service_FAILURE_ACTIONS_SECOND_Failure -ne 1) {
            Write-Output "[$env:COMPUTERNAME] FAILED: No second failure action defined."
        } else {
            Write-Output "[$env:COMPUTERNAME] PASSED: Second Failure = $Service_FAILURE_ACTIONS_SECOND_Failure min"
        }

        if ($Service_FAILURE_ACTIONS_THIRD_Failure -ne 1) {
            Write-Output "[$env:COMPUTERNAME] FAILED: No third failure action defined."
        } else {
            Write-Output "[$env:COMPUTERNAME] PASSED: Third Failure = $Service_FAILURE_ACTIONS_THIRD_Failure min"
        }
    }
}