$ServerListFile = "D:\CC_Scripts\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList)
{ 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer
write-host  $computername
Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
Import-Module WebAdministration
#Enable-WindowsOptionalFeature -Online -FeatureName WCF-Services45
Enable-WindowsOptionalFeature -Online -FeatureName WAS-WindowsActivationService
Enable-WindowsOptionalFeature -Online -FeatureName WAS-ProcessModel
Enable-WindowsOptionalFeature -Online -FeatureName WAS-ConfigurationAPI
#Enable-WindowsOptionalFeature -Online -FeatureName WAS-WindowsActivationService
Enable-WindowsOptionalFeature -Online -FeatureName WCF-HTTP-Activation45

#Get-WindowsOptionalFeature -Online | where {$_.state -eq "Enabled"} | ft -Property featurename
#Enable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-PortSharing45


}                
}


#Install-WindowsFeature -ConfigurationFilePath "C:\temp\DeploymentConfigTemplate.xml"