# <# To Install Certificate in Trusted Root and Generate HTML Report #>

$ServerListFile = "D:\BKP\Server.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop

# Certificate file to install
$CertFile = "D:\BKP\Cert\1\Goldman Sachs Root CA G2.cer"

$Results = @()

ForEach ($computername in $ServerList) {
    # Copy certificate to remote machine
    robocopy D:\BKP\Cert\1 \\$computername\C$\Temp\Cert\ /e

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
        param($CertFileName)

        $Result = @()
        try {
            $installed = Import-Certificate -FilePath ("C:\Temp\Cert\" + $CertFileName) -CertStoreLocation 'Cert:\LocalMachine\Root' -ErrorAction Stop
            if ($installed) {
                $Result += [PSCustomObject]@{
                    Server   = $env:COMPUTERNAME
                    CertName = [System.IO.Path]::GetFileNameWithoutExtension($CertFileName)
                    Status   = "Installed"
                    DateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
            }
        }
        catch {
            $Result += [PSCustomObject]@{
                Server   = $env:COMPUTERNAME
                CertName = [System.IO.Path]::GetFileNameWithoutExtension($CertFileName)
                Status   = "Failed: $($_.Exception.Message)"
                DateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        return $Result
    } -ArgumentList (Split-Path $CertFile -Leaf) | ForEach-Object {
        $Results += $_
    }
}

# Timestamped report filename
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = "D:\BKP\CertInstallReport_$TimeStamp.html"

# HTML style
$Head = @"
<style>
    body { font-family: Arial; }
    h2 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin-top: 10px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #4CAF50; color: white; }
    tr:nth-child(even) { background-color: #f9f9f9; }
</style>
"@

# Add header with timestamp
$ReportHeader = "<h2>Certificate Installation Report</h2><p>Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>"

$Results | Sort-Object Server, CertName |
ConvertTo-Html -Head $Head -Title "Certificate Installation Report" -PreContent $ReportHeader |
Out-File $ReportFile

# Open report automatically
Invoke-Item $ReportFile

Write-Host "HTML Report generated at: $ReportFile"
