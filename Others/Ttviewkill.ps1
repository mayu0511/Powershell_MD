$ServerListFile = "D:\SVC.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock { hostname 
Get-Process -Processname tview 
#Stop-Process -Processname tview
Write-Host "tview killed"
Start-Sleep -Seconds 3
#Remove-Item D:\CC_Runtime\* -Verbose -force
#Remove-Item C:\corecard_services\shmem.bin -Verbose -force
}
}