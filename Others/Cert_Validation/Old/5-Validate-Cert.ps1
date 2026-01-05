# Path to the text file containing the list of server names (one server per line).
$ServerListFile = "D:\BKP\Servers.txt"
try {
    $ServerList = Get-Content $ServerListFile -ErrorAction Stop
}
catch {
    Write-Host "Error: Could not find the server list file at '$ServerListFile'. Please check the path and try again." -ForegroundColor Red
    return
}

$ExpectedThumbprint = "73E38D4A41B176351105FD6AE73E6F5A5A297B3F"
$Results = @()

foreach ($computername in $ServerList) {
    
    Write-Host "Checking certificate on $computername ... " -ForegroundColor Cyan
    
       try {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer
        
            $cert = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            Get-ChildItem -Path "Cert:\LocalMachine\Root" |
            Where-Object { $_.Thumbprint -eq $using:ExpectedThumbprint } |
            Select-Object Subject, Thumbprint, NotAfter
        }

        if ($cert) {
            $Results += [PSCustomObject]@{
                Server     = $computername
                Thumbprint = $cert.Thumbprint
                Expiry     = $cert.NotAfter
                Status     = "✔ Found"
            }
        } else {

            $Results += [PSCustomObject]@{
                Server     = $computername
                Thumbprint = $ExpectedThumbprint
                Expiry     = ""
                Status     = "✖ Not Found"
            }
        }
    }
    catch {
        $Results += [PSCustomObject]@{
            Server     = $computername
            Thumbprint = $ExpectedThumbprint
            Expiry     = ""
            Status     = "⚠ Error: $($_.Exception.Message)"
        }
    }
}

Write-Host "`n--- Certificate Validation Summary ---`n"
$Results | Format-Table -AutoSize

$CsvFilePath = "C:\Temp\CertificateExpiryResults3.csv"
$Results | Export-Csv $CsvFilePath -NoTypeInformation -Force

Write-Host "Validation complete. Results saved to $CsvFilePath" -ForegroundColor Green