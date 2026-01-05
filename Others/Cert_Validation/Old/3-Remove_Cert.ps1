$ServerListFile = "D:\BKP\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList) {
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        hostname
        $thumbprint = "73E38D4A41B176351105FD6AE73E6F5A5A297B3F" # Replace with actual Thumbprint
        $cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $thumbprint }
        if ($cert) {
            Remove-Item -Path $cert.PSPath -Force
            Write-Host "Certificate with Thumbprint $thumbprint removed."
        } else {
            Write-Host "Certificate not found."
        }
    }
}