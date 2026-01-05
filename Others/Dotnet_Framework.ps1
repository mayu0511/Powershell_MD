######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================
$ServerListFile = "D:\Backup\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

$results = @()

ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    write-host "Connecting to $computername"

    $frameworkDescription = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    }

    $results += [PSCustomObject]@{
        ServerName    = $computername
        FrameworkVersion = $frameworkDescription
    }
}

$results | Format-Table -Property ServerName, FrameworkVersion
