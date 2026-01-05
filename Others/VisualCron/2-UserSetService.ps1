######################################################################################################################
# VisualCron Server User Set | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 11-April-2025
#=====================================================================================================================

$ServerListFile = "D:\CC_Scripts\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop

$username = "cc-pod2-dev\gMSA-batch-svc$"
$password = ""

ForEach ($computername in $ServerList) {
    Write-Host "Processing server: $computername"
    
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    
    try {
           Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            $serviceName = "VisualCron"
            $service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
            
            if ($service -ne $null) {
                $service.Change($null, $null, $null, $null, $null, $null, $using:username, $null) | Out-Null

                Restart-Service -Name $serviceName -Force
                Write-Host "Service '$serviceName' credentials updated and service restarted on $($env:COMPUTERNAME)"
            } else {
                Write-Host "Service '$serviceName' not found on $($env:COMPUTERNAME)" -ForegroundColor Yellow
            }
        }
    
    } catch {
        Write-Host "Error processing server: $computername. Error: $_" -ForegroundColor Red
    }
}	