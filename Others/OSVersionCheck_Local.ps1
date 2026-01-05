$ServerName = $env:COMPUTERNAME  # Get the local computer name
$OS = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$Architecture = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }

# Create a custom object for structured output
$SystemInfo = [PSCustomObject]@{
    "Server Name"  = $ServerName
    "OS Name"      = $OS.ProductName
    "Version"      = "$($OS.DisplayVersion) (Build $($OS.CurrentBuild))"
    "Architecture" = $Architecture
}

# Display output in tabular format
$SystemInfo | Format-Table -AutoSize
