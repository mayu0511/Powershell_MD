#<# To Install Certificate in Trusted Root #>
$ServerListFile = "D:\BKP\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach ($computername in $ServerList) {
    robocopy D:\BKP\Cert\1 \\$computername\C$\Temp\Cert\ /e
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock {
        hostname
        Import-Certificate -FilePath "C:\Temp\Cert\Goldman Sachs Root CA G2.cer" -CertStoreLocation 'Cert:\LocalMachine\Root' -Verbose
    }
}