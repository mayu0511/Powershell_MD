$ServerListFile = "D:\backup\LIST\servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop

ForEach ($computername in $ServerList) {
    Write-Host "Processing server: $computername"
    
    try {
        # Invoke-Command to remotely create the service
        Invoke-Command -ComputerName $computername -ScriptBlock {
            $serviceName = "WebServerHealth"
            $binPath = '"D:\WebServer\ServersHealth\Service\WebServerHealth.exe"'
            $displayName = '"Web Server Health"'

            # Create the service using sc.exe
            $createServiceCmd = "sc.exe create $serviceName binPath= $binPath DisplayName= $displayName"
            Invoke-Expression $createServiceCmd

            # Check if the service was created successfully
            if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
                Write-Host "Service '$serviceName' created successfully on $env:COMPUTERNAME" -ForegroundColor Green
            } else {
                Write-Host "Failed to create service '$serviceName' on $env:COMPUTERNAME" -ForegroundColor Red
            }
        } -ErrorAction Stop
    
    } catch {
        Write-Host "Error processing server: $computername. Error: $_" -ForegroundColor Red
    }
}