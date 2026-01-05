######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================
$ServerListFile = "D:\Backup\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

$results = @()

ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    Write-Host "Connecting to $computername"

    $frameworkDescription = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        
        if (Get-Command dotnet -ErrorAction SilentlyContinue) {
          
            $dotnetRuntimes = & dotnet --list-runtimes
           
            return $dotnetRuntimes
        } else {
          
            return "dotnet command not found"
        }
    }

    # Add the results into an array of custom objects
    $results += [PSCustomObject]@{
        ServerName        = $computername
        FrameworkVersion  = $frameworkDescription -join ", "
    }
}

$results | Format-Table -Property ServerName, FrameworkVersion
