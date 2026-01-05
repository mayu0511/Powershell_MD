$ServerListFile = "E:\Servers.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

$option = New-PSSessionOption -ProxyAccessType NoProxyServer

$Results = @()  # Initialize an array to store results

ForEach ($computername in $ServerList) {
    Write-Host "Checking: $computername"

    $SystemInfo = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        $OS = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $Architecture = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }

        # Return a custom object
        [PSCustomObject]@{
            "Server Name"  = $env:COMPUTERNAME
            "OS Name"      = $OS.ProductName
            "Version"      = "$($OS.DisplayVersion) (Build $($OS.CurrentBuild))"
            "Architecture" = $Architecture
        }
    }

    # Store result
    $Results += $SystemInfo
}

# Display results in a tabular format
$Results | Format-Table -AutoSize
