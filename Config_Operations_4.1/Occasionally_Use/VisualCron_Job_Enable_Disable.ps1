######################################################################################################################
# # Enable/Disable All VisualCron Jobs | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 22-Sep-2025
#=====================================================================================================================

$DateTimeStamp = (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
$ServerListFile = "E:\Servers.txt"
$LogFile = "C:\Temp\VC_Jobs_Log_$DateTimeStamp.log"
$HtmlReport = "C:\Temp\VC_Jobs_Report_$DateTimeStamp.html"

if (-not (Test-Path "C:\Temp")) { 
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null 
}

$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue
if (-not $ServerList -or $ServerList.Count -eq 0) {
    Write-Host "ERROR: Servers.txt file not found or is empty."
    exit 1
}

do {
    $Action = Read-Host "Do you want to Enable or Disable all jobs? (Enter Enable/Disable)"
} while ($Action -notmatch '^(Enable|Disable)$')

do {
    $AutoApproveInput = Read-Host "Do you want to automatically approve all jobs? (Y/N)"
} while ($AutoApproveInput -notmatch '^[YyNn]$')

$AutoApprove = $AutoApproveInput -match '^[Yy]$'

Write-Host "`nYou chose to $Action all VisualCron jobs."
if ($AutoApprove) { 
    Write-Host "All jobs will be auto-approved." 
} else { 
    Write-Host "You will be asked to confirm each job." 
}

$Report = @()
$TotalJobCount = 0

foreach ($computername in $ServerList) {
    Write-Host "`nProcessing server: $computername"

    $confirmServer = Read-Host "Do you want to proceed on $computername? (Y/N)"
    if ($confirmServer -notmatch '^[Yy]$') {
        Write-Host "Skipping $computername."
        Add-Content $LogFile "$(Get-Date) - Skipped $computername"
        continue
    }

    Add-Content $LogFile "`n$(Get-Date) - Starting processing for server: $computername"

    try {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer

        $ServerJobResults = @(Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Stop -ScriptBlock {
            param($LogFile, $Action, $AutoApprove, $ServerName)

            $JobReport = @()

            try {
                $vcDll = "C:\Program Files (x86)\VisualCron\VisualCron.dll"
                $vcApiDll = "C:\Program Files (x86)\VisualCron\VisualCronAPI.dll"

                if (-not (Test-Path $vcDll) -or -not (Test-Path $vcApiDll)) {
                    Add-Content $LogFile "$(Get-Date) - ERROR: VisualCron DLLs not found on $env:COMPUTERNAME"
                    return @()
                }

                [Reflection.Assembly]::LoadFrom($vcDll) | Out-Null
                [Reflection.Assembly]::LoadFrom($vcApiDll) | Out-Null

                
                $Client = New-Object -TypeName VisualCronAPI.Client
                $Conn = New-Object -TypeName VisualCronAPI.Connection
                $Conn.Address = "localhost"
                $Conn.Port = 16444
                $Conn.ConnectionType = 'Remote'

                $VCServer = $Client.Connect($Conn, $true)
                $allJobs = $VCServer.Jobs.GetAll()

                foreach ($job in $allJobs) {
                    $jobStatus = $VCServer.Jobs.Get($job.Id)
                    $alreadyState = if ($Action -eq 'Enable') { $jobStatus.Stats.Active } else { -not $jobStatus.Stats.Active }

                    if ($alreadyState) {
                        $Status = "Already $Action"
                        Add-Content $LogFile "$(Get-Date) - $($job.Name) already $Action on $env:COMPUTERNAME"
                    }
                    else {
                        try {
                            if ($Action -eq 'Enable') {
                                $VCServer.Jobs.Activate($job.Id)
                            } else {
                                $VCServer.Jobs.DeActivate($job.Id)
                            }

                            Start-Sleep -Milliseconds 500
                            $jobStatus = $VCServer.Jobs.Get($job.Id)
                            $statusCheck = if ($Action -eq 'Enable') { $jobStatus.Stats.Active } else { -not $jobStatus.Stats.Active }

                            if ($statusCheck) {
                                $Status = "Success"
                                Add-Content $LogFile "$(Get-Date) - SUCCESS: $($job.Name) ${Action}d on $env:COMPUTERNAME"
                            } else {
                                $Status = "Failed"
                                Add-Content $LogFile "$(Get-Date) - ERROR: $($job.Name) could not be ${Action}d on $env:COMPUTERNAME"
                            }
                        }
                        catch {
                            $Status = "Error - $($_.Exception.Message)"
                            Add-Content $LogFile "$(Get-Date) - ERROR: $($job.Name) failed to process on $env:COMPUTERNAME : $($_.Exception.Message)"
                        }
                    }

                    $JobReport += [PSCustomObject]@{
                        Server = $ServerName
                        JobName = $job.Name
                        Action = $Action
                        Status = $Status
                    }
                }

                
                $Client = $null
                $VCServer = $null
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()

            }
            catch {
                Add-Content $LogFile "$(Get-Date) - ERROR: $_"
            }

            return $JobReport
        } -ArgumentList $LogFile, $Action, $AutoApprove, $computername)

        $ServerJobResults = $ServerJobResults | Where-Object { $_ -and $_.JobName }

        if ($ServerJobResults) {
            $Report += $ServerJobResults
            $TotalJobCount += $ServerJobResults.Count
        }

    }
    catch {
        Add-Content $LogFile "$(Get-Date) - ERROR: Failed to connect to $computername : $($_.Exception.Message)"
    }

    Write-Host "Finished processing $computername"
}


Write-Host "`nGenerating HTML report..."

$HtmlBody = @"
<style>
body { font-family: Arial, sans-serif; margin: 20px; }
h2 { color: #333; }
table { border-collapse: collapse; width: 100%; margin-top: 20px; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #4CAF50; color: white; font-weight: bold; }
tr:nth-child(even) { background-color: #f2f2f2; }
</style>
<h2>VisualCron Job Report - $(Get-Date)</h2>
<p>Total Jobs Processed: $TotalJobCount</p>
<table>
<tr>
<th>Server</th>
<th>Job Name</th>
<th>Action</th>
<th>Status</th>
</tr>
"@

foreach ($entry in ($Report | Sort-Object Server, JobName)) {
    $HtmlBody += "<tr><td>$($entry.Server)</td><td>$($entry.JobName)</td><td>$($entry.Action)</td><td>$($entry.Status)</td></tr>`n"
}

$HtmlBody += "</table>"

$HtmlBody | Out-File $HtmlReport -Encoding UTF8
Write-Host "HTML report generated: $HtmlReport"
Write-Host "Log file generated: $LogFile"

try {
    Invoke-Item $HtmlReport
} catch {
    Write-Host "Could not automatically open report. Open manually: $HtmlReport"
}
