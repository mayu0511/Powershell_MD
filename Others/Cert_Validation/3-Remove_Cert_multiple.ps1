$ServerListFile = "D:\BKP\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop

# List of thumbprints to remove
$Thumbprints = @(
    "73E38D4A41B176351105FD6AE73E6F5A5A297B3F",
    "1234567890ABCDEF1234567890ABCDEF12345678",  # example
    "ABCDEF1234567890ABCDEF1234567890ABCDEF12"   # example
)

ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
        param($Thumbprints)

        hostname

        foreach ($thumbprint in $Thumbprints) {
            $cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $thumbprint }
            if ($cert) {
                Remove-Item -Path $cert.PSPath -Force
                Write-Host "Certificate with Thumbprint $thumbprint removed."
            } else {
                Write-Host "Certificate with Thumbprint $thumbprint not found."
            }
        }
    } -ArgumentList $Thumbprints
}
