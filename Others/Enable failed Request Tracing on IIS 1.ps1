$ServerListFile = "D:\service.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) {
$option = New-PSSessionOption -ProxyAccessType NoProxyServer 
write-host  $computername
 Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
 Import-Module WebAdministration
 Install-WindowsFeature -Name Web-Http-Tracing
$WebsiteName = "Services"
$psPath = "IIS:\Sites\$WebsiteName" 
$Path = "*"
$FailureStatusCodes = "500-600"
$providers = 'ASP', 'ASPNET', 'ISAPI Extension', 'WWW Server'

#Set-ItemProperty $psPath -Name traceFailedRequestsLogging.enabled -Value 1
 
Set-ItemProperty -PsPath $psPath -Name traceFailedRequestsLogging `
        -Value @{
        enabled     = $true
        #directory   = "%SystemDrive%\inetpub\logs\FailedReqLogFiles"
        #maxLogFiles = 50
        }
 
Clear-WebConfiguration "/system.webServer/tracing/traceFailedRequests" -PSPath $pspath
 
Add-WebConfigurationProperty -pspath $pspath -filter "system.webServer/tracing/traceFailedRequests" -name "." -value @{path = "$Path"}
Add-WebConfigurationProperty -pspath $pspath -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/traceAreas" -name "." -value @{provider = $providers -join ','}
Set-WebConfigurationProperty -pspath $pspath -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/failureDefinitions" -name "statusCodes" -value $FailureStatusCodes

}
}