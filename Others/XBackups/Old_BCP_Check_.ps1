Clear-Host
$ServerListFile="E:\Servers.txt"

$ServerList = Get-Content $ServerListFile -ErrorAction inquire

ForEach ($computername in $ServerList) {

$option = New-PSSessionOption -ProxyAccessType NoProxyServer

write-host $computername

Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {

$command = "bcp"

try {
    # Attempt to get the path of the bcp command
    $bcpPath = Get-Command $command -ErrorAction Stop
    
    Write-Host "bcp is installed. Location: $($bcpPath.Source)" -ForegroundColor Green
    $bcpVersion = & "$($bcpPath.Source)" -v

    Write-Host "bcp version: $bcpVersion" -ForegroundColor Cyan
    } 
    catch {
      Write-Host "bcp is not installed on this machine." -ForegroundColor Red
        
        }
    }
}
