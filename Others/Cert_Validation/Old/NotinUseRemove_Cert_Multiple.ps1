$ServerListFile = "D:\BKP\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Inquire

# List of thumbprints you want to remove
$Thumbprints = @(
    "73E38D4A41B176351105FD6AE73E6F5A5A297B3F",
    "73E38D4A41B176351105FD85E73E6F5A5A297B3F",
    "73E38D4A41B176351107896AE73E6F5A5A297B3F"
)

ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer

    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Inquire -ScriptBlock {
        param($Thumbprints)

        hostname

        foreach ($tp in $Thumbprints) {
            $cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $tp }
            if ($cert) {
                Remove-Item -Path $cert.PSPath -Force
                Write-Host "✔ Certificate with Thumbprint $tp removed."
            } else {
                Write-Host "✖ Certificate with Thumbprint $tp not found."
            }
        }

    } -ArgumentList ($Thumbprints)
}
