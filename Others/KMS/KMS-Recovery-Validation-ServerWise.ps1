######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$serviceName = "KMSService"

$Service_FAILURE_ACTIONS = sc.exe qfailure $serviceName -FAILURE_ACTIONS

if ($Service_FAILURE_ACTIONS) {
    #Write-Output "Raw Output:"
    #Write-Output $Service_FAILURE_ACTIONS

    try {
        $lines = $Service_FAILURE_ACTIONS -split "`n"
        $resetPeriodLine = ($lines | Where-Object { $_ -match 'RESET_PERIOD' }) -replace '.*RESET_PERIOD \(in seconds\)\s*:\s*', ''
        $commandLines = ($lines | Where-Object { $_ -match 'RESTART' }) -replace '.*RESTART -- Delay = ', ''
    
        $Service_FAILURE_ACTIONS_RESET_PERIOD = [int]$resetPeriodLine
        $Service_FAILURE_ACTIONS_FIRST_Failure = ($commandLines[0] -replace ' milliseconds.', '') / 60000
        $Service_FAILURE_ACTIONS_SECOND_Failure = ($commandLines[1] -replace ' milliseconds.', '') / 60000

        $Service_FAILURE_ACTIONS_THIRD_Failure = $Service_FAILURE_ACTIONS_SECOND_Failure

        if ($Service_FAILURE_ACTIONS_RESET_PERIOD -eq 0 -and 
            $Service_FAILURE_ACTIONS_FIRST_Failure -eq 1 -and 
            $Service_FAILURE_ACTIONS_SECOND_Failure -eq 1 -and 
            $Service_FAILURE_ACTIONS_THIRD_Failure -eq 1) {
            
            Write-Output "PASSED"
        } else {
            Write-Output "FAILED"
        }
    } catch {
        Write-Output "FAILED: An error occurred while processing the output. Error: $_"
    }
} else {
    Write-Output "FAILED: No output from sc.exe command."
}
