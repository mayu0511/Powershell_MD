######################################################################################################################
# KSM Recovery | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$ServerListFile = "D:\CC-Scripts\Servers.txt"
$OutputFile = "D:\CC-Scripts\log1248788.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

"Service Failure Actions Check - $(Get-Date)" | Out-File $OutputFile -Append

ForEach ($computername in $ServerList) {
    Write-Host "Checking service on $computername"
    
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        $serviceName = "KMSService"
        $failureActions = "restart/60000/restart/60000/restart/60000"

        sc.exe failure $serviceName reset=0 actions=$failureActions
        $Service_FAILURE_ACTIONS = sc.exe qfailure $serviceName

        $Service_FAILURE_ACTIONS_RESET_PERIOD = $null
        $Service_FAILURE_ACTIONS_FIRST_Failure = $null
        $Service_FAILURE_ACTIONS_SECOND_Failure = $null
        $Service_FAILURE_ACTIONS_THIRD_Failure = $null

        if ($Service_FAILURE_ACTIONS -and $Service_FAILURE_ACTIONS.Length -ge 9) {
            if ($Service_FAILURE_ACTIONS[3]) {
                $Service_FAILURE_ACTIONS_RESET_PERIOD = [int]($Service_FAILURE_ACTIONS[3].Split(':')[1].Trim())
            }

            if ($Service_FAILURE_ACTIONS[6]) {
                $firstFailureRaw = $Service_FAILURE_ACTIONS[6].Split('=')[1].Trim().Split(' ')[0]
                if ($firstFailureRaw) {
                    $Service_FAILURE_ACTIONS_FIRST_Failure = [int]$firstFailureRaw / 60000
                }
            }

            if ($Service_FAILURE_ACTIONS[7]) {
                $secondFailureRaw = $Service_FAILURE_ACTIONS[7].Split('=')[1].Trim().Split(' ')[0]
                if ($secondFailureRaw) {
                    $Service_FAILURE_ACTIONS_SECOND_Failure = [int]$secondFailureRaw / 60000
                }
            }

            if ($Service_FAILURE_ACTIONS[8]) {
                $thirdFailureRaw = $Service_FAILURE_ACTIONS[8].Split('=')[1].Trim().Split(' ')[0]
                if ($thirdFailureRaw) {
                    $Service_FAILURE_ACTIONS_THIRD_Failure = [int]$thirdFailureRaw / 60000
                }
            }

            # Check all conditions in a single if-else
            if ($Service_FAILURE_ACTIONS_RESET_PERIOD -eq 0 -and
                $Service_FAILURE_ACTIONS_FIRST_Failure -eq 1 -and
                $Service_FAILURE_ACTIONS_SECOND_Failure -eq 1 -and
                $Service_FAILURE_ACTIONS_THIRD_Failure -eq 1) {
                
                "[$env:COMPUTERNAME] PASSED" 
            } else {
                "[$env:COMPUTERNAME] FAILED"
            }
        } else {
            "[$env:COMPUTERNAME] ERROR: Failed to retrieve service failure actions for $serviceName."
        }
    } | Out-File $OutputFile -Append
}

Write-Host "Check completed. Results saved in $OutputFile"
