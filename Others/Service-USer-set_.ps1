$ServerListFile = "D:\backup\LIST\servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop

ForEach ($computername in $ServerList) {
    Write-Host "Processing server: $computername"
    
    # Creating session options
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    
    try {
        # Invoke-Command to change the service logon credentials and restart service
        Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            (Get-WmiObject -Class Win32_Service -Filter "Name='Spooler'").Change($null, $null, $null, $null, $null, $null, 'newvisionsoftware\mahendra.dwivedi', 'asnupam@#12345') | Out-Null
            Restart-Service -Name 'Spooler' -Force
        }
        Write-Host "Successfully updated and restarted service on $computername"
    } catch {
        Write-Host "Error processing server: $computername. Error: $_" -ForegroundColor Red
    }
}
