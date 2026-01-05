$ServerListFile = "D:\backup\LIST\servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop

# Define the credentials outside of the Invoke-Command block
$username = "cc-jazz-dev\gMSA-app-svc$"
$password = ""  # If no password is needed for gMSA, you can leave this blank.

ForEach ($computername in $ServerList) {
    Write-Host "Processing server: $computername"
    
    # Creating session options
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    
    try {
        # Invoke-Command to change the service logon credentials and restart service
        Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            $serviceName = "WEbServerAPI"
            
            # Get the service object
            $service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
            
            if ($service -ne $null) {
                # Set the credentials (no password needed for gMSA)
                $service.Change($null, $null, $null, $null, $null, $null, $using:username, $null) | Out-Null

                # Restart the service to apply the changes
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