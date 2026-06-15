######################################################################################################################
# KMS Activation
# DEVELOPED BY: Mahendra Dwivedi
# Version 2.2
# Date: 08-Jun-2026
######################################################################################################################

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = "C:\Temp\KMS-Activation_$TimeStamp.html"

$Results = @()

$ServerListFile = "D:\CC_Scripts\Servers.txt"
$ServerList = Get-Content $ServerListFile

foreach ($ComputerName in $ServerList)
{
    Write-Host "Processing Server : $ComputerName" -ForegroundColor Cyan

    $option = New-PSSessionOption `
        -ProxyAccessType NoProxyServer `
        -OpenTimeout 20000

    $result = Invoke-Command `
        -ComputerName $ComputerName `
        -SessionOption $option `
        -ErrorAction Continue `
        -ScriptBlock {

        $LogFolder = "C:\Temp"

        if (!(Test-Path $LogFolder))
        {
            New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
        }

        $TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $LogFile = Join-Path $LogFolder "KMS_Activation_$TimeStamp.log"

        function Write-Log
        {
            param([string]$Message)

            $Entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') : $Message"

            Write-Host $Entry
            Add-Content -Path $LogFile -Value $Entry
        }

        try
        {
            Write-Log "Starting KMS Activation"

            $Params = @{
                UseDefaultCredentials = $true
                UseBasicParsing       = $true
            }

            $BaseUrl = "https://localhost:8081"

            # Master Key1
            $r1 = Invoke-WebRequest `
                -Uri "$BaseUrl/OrgK1/1" `
                -Method POST `
                -Body @{
                    OrgK1  = "plat"
                    OrgNum = "1"
                } `
                @Params

            # Master Key2
            $r2 = Invoke-WebRequest `
                -Uri "$BaseUrl/OrgK2/1" `
                -Method POST `
                -Body @{
                    OrgK2  = "corecard"
                    OrgNum = "1"
                } `
                @Params

            # Org2 Key1
            $r3 = Invoke-WebRequest `
                -Uri "$BaseUrl/OrgK1/2" `
                -Method POST `
                -Body @{
                    OrgK1  = "plat"
                    OrgNum = "2"
                } `
                @Params

            # Org2 Key2
            $r4 = Invoke-WebRequest `
                -Uri "$BaseUrl/OrgK2/2" `
                -Method POST `
                -Body @{
                    OrgK2  = "corecard"
                    OrgNum = "2"
                } `
                @Params

            if (
                $r1.StatusCode -eq 200 -and
                $r2.StatusCode -eq 200 -and
                $r3.StatusCode -eq 200 -and
                $r4.StatusCode -eq 200
            )
            {
                Write-Log "SUCCESS - KMS Activation Completed Successfully"

                [PSCustomObject]@{
                    ServerName = $env:COMPUTERNAME
                    Status     = "Activated"
                }
            }
            else
            {
                Write-Log "FAILURE - One Or More Requests Failed"

                [PSCustomObject]@{
                    ServerName = $env:COMPUTERNAME
                    Status     = "Failed"
                }
            }

            Write-Log "Script Completed"
        }
        catch
        {
            Write-Log "ERROR : $($_.Exception.Message)"

            [PSCustomObject]@{
                ServerName = $env:COMPUTERNAME
                Status     = "Failed"
            }
        }
    }

    $Results += $result
}

$SuccessCount = ($Results | Where-Object { $_.Status -eq "Activated" }).Count
$FailedCount  = ($Results | Where-Object { $_.Status -eq "Failed" }).Count

$Rows = $Results | ForEach-Object {
    "<tr><td>$($_.ServerName)</td><td>$($_.Status)</td></tr>"
}

$Rows = $Rows -join "`r`n"

$Html = @"
<html>
<head>
<title>KMS Activation Report</title>

<style>

body {
    font-family: Arial;
    font-size: 12px;
}

table {
    border-collapse: collapse;
    width: 70%;
}

th {
    background-color: #4472C4;
    color: white;
    border: 1px solid black;
    padding: 8px;
}

td {
    border: 1px solid black;
    padding: 8px;
}

</style>

</head>

<body>

<h2>KMS Activation Report</h2>

<p><b>Generated:</b> $(Get-Date)</p>

<p><b>Total Servers:</b> $($Results.Count)</p>
<p><b>Activated:</b> $SuccessCount</p>
<p><b>Failed:</b> $FailedCount</p>

<table>
<tr>
    <th>Server Name</th>
    <th>Activation Status</th>
</tr>

$Rows

</table>

</body>
</html>
"@

$Html | Out-File $ReportFile -Encoding UTF8

Invoke-Item $ReportFile

Write-Host ""
Write-Host "Report Generated: $ReportFile" -ForegroundColor Green