######################################################################################################################
# KMS  Recovery | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$ServerListFile = "D:\CC-Scripts\Servers.txt"
$OutputFile = "D:\CC-Scripts\log17827578.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

"Service Failure Actions Check - $(Get-Date)" | Out-File $OutputFile -Append

ForEach ($computername in $ServerList) {
    Write-Host "Checking service on $computername"
    
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        $serviceName = "KMSService"
        $Service_FAILURE_ACTIONS = sc.exe qfailure $serviceName -FAILURE_ACTIONS

        $Output = @()
        $isFailed = $false

        if ($Service_FAILURE_ACTIONS -and $Service_FAILURE_ACTIONS.Length -gt 0) {
            
            $Service_FAILURE_ACTIONS_RESET_PERIOD = $null
            $Service_FAILURE_ACTIONS_FIRST_Failure = $null
            $Service_FAILURE_ACTIONS_SECOND_Failure = $null
            $Service_FAILURE_ACTIONS_THIRD_Failure = $null
            
            if ($Service_FAILURE_ACTIONS[3] -and $Service_FAILURE_ACTIONS[3].Contains(':')) {
                $Service_FAILURE_ACTIONS_RESET_PERIOD = $Service_FAILURE_ACTIONS[3].Split(':')[1].Trim()
            }
            if ($Service_FAILURE_ACTIONS[6] -and $Service_FAILURE_ACTIONS[6].Contains('=')) {
                $Service_FAILURE_ACTIONS_FIRST_Failure = [int]($Service_FAILURE_ACTIONS[6].Split('=')[1].Trim().Split(' ')[0]) / 60000
            }
            if ($Service_FAILURE_ACTIONS[7] -and $Service_FAILURE_ACTIONS[7].Contains('=')) {
                $Service_FAILURE_ACTIONS_SECOND_Failure = [int]($Service_FAILURE_ACTIONS[7].Split('=')[1].Trim().Split(' ')[0]) / 60000
            }
            if ($Service_FAILURE_ACTIONS[8] -and $Service_FAILURE_ACTIONS[8].Contains('=')) {
                $Service_FAILURE_ACTIONS_THIRD_Failure = [int]($Service_FAILURE_ACTIONS[8].Split('=')[1].Trim().Split(' ')[0]) / 60000
            }

            if ($Service_FAILURE_ACTIONS_RESET_PERIOD -ne 0 -or 
                $Service_FAILURE_ACTIONS_FIRST_Failure -ne 1 -or 
                $Service_FAILURE_ACTIONS_SECOND_Failure -ne 1 -or 
                $Service_FAILURE_ACTIONS_THIRD_Failure -ne 1) {
                $isFailed = $true
            }

            if ($isFailed) {
                $Output += "[$env:COMPUTERNAME] FAILED : Some Tags Value Are Incorrect"
            } else {
                $Output += "[$env:COMPUTERNAME] PASSED : All Tags Value Are Up To Date"
            }
        } else {
            $Output = "[$env:COMPUTERNAME] ERROR: Failed to retrieve service failure actions for $serviceName."
        }

        $Output
    } | Out-File $OutputFile -Append
}

Write-Host "Check completed. Results saved in $OutputFile"
