######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$ServerListFile = "D:\CC_Scripts\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop

ForEach ($computername in $ServerList) {
    Write-Host "Processing server: $computername"

    try {
        
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
        Invoke-Command -ComputerName $computername -SessionOption $option -ScriptBlock {
            $serviceName = "WebServerHealth"
            $binPath = 'D:\WebServer\ServerHealth\Service\WebServerHealth.exe'
            $displayName = 'Web Server Health'

            $createServiceCmd = "sc.exe create $serviceName binPath= '$binPath' DisplayName= '$displayName'"
            $createServiceCmd
            Invoke-Expression $createServiceCmd

            if (Get-Service -Name $serviceName -ErrorAction Continue) {
                Write-Host "Service '$serviceName' created successfully on $env:COMPUTERNAME" -ForegroundColor Green
            } else {
                Write-Host "Failed to create service '$serviceName' on $env:COMPUTERNAME" -ForegroundColor Red
            }
        } -ErrorAction Stop

    } catch {
        Write-Host "Error processing server: $computername. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}	