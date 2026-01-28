######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================


$ServerListFile = "D:\backup\LIST\servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    write-host  $computername
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
$FilePath= "D:\DotNetHostingBudle\dotnet-hosting-7.0.1-win.exe"
$silent= '/Q'
$PSpath= "MACHINE/WEBROOT/APPHOST"
$Filter= "/system.webServer/proxy"
Try{
   Start-Process -FilePath $FilePath -ArgumentList $silent -Wait -NoNewWindow
   Set-WebConfigurationProperty -pspath $PSpath -filter $Filter -name "." -value @{enabled="true"}
}
Catch{
   Write-Host $_
       Exit 1
}

 

}
}