######################################################################################################################
# KMS Active Connection And Error Keyword | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.4 |Date:: 19-Sep-2025
######################################################################################################################

Clear-Host
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Create GUI Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "KMS Trace Log Checker"
$form.Size = New-Object System.Drawing.Size(600,300)
$form.StartPosition = "CenterScreen"

# --- Trace File Path ---
$lblFile = New-Object System.Windows.Forms.Label
$lblFile.Text = "Trace File Path:"
$lblFile.Location = New-Object System.Drawing.Point(10,20)
$lblFile.AutoSize = $true
$form.Controls.Add($lblFile)

$txtFile = New-Object System.Windows.Forms.TextBox
$txtFile.Location = New-Object System.Drawing.Point(120,18)
$txtFile.Size = New-Object System.Drawing.Size(350,20)
$txtFile.Text = "D:\CoreCard\KMS\Service\Data\kms-trace2025-09-16.txt"
$form.Controls.Add($txtFile)

# --- Number of Log Lines ---
$lblLines = New-Object System.Windows.Forms.Label
$lblLines.Text = "Log Lines to Check:"
$lblLines.Location = New-Object System.Drawing.Point(10,60)
$lblLines.AutoSize = $true
$form.Controls.Add($lblLines)

$txtLines = New-Object System.Windows.Forms.TextBox
$txtLines.Location = New-Object System.Drawing.Point(120,58)
$txtLines.Size = New-Object System.Drawing.Size(100,20)
$txtLines.Text = "1000"
$form.Controls.Add($txtLines)

# --- Keywords ---
$lblKeywords = New-Object System.Windows.Forms.Label
$lblKeywords.Text = "Keywords (comma separated):"
$lblKeywords.Location = New-Object System.Drawing.Point(10,100)
$lblKeywords.AutoSize = $true
$form.Controls.Add($lblKeywords)

$txtKeywords = New-Object System.Windows.Forms.TextBox
$txtKeywords.Location = New-Object System.Drawing.Point(200,98)
$txtKeywords.Size = New-Object System.Drawing.Size(270,20)
$txtKeywords.Text = "INFO Connection received from,Authenticated,Starting as a service,on address https://localhost:8081,GC about to start,GC done,Error Code,decrypt failed,Service Stop"
$form.Controls.Add($txtKeywords)

# --- Run Button ---
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Report"
$btnRun.Location = New-Object System.Drawing.Point(250,150)
$form.Controls.Add($btnRun)

# --- Event Handler ---
$btnRun.Add_Click({
    $filePath  = $txtFile.Text
    $tailCount = [int]$txtLines.Text
    $keywords  = $txtKeywords.Text -split ',' | ForEach-Object { $_.Trim() }

    if (-not (Test-Path $filePath)) {
        [System.Windows.Forms.MessageBox]::Show("Trace file not found: $filePath","Error","OK","Error")
        return
    }

    # Fetch server list using AWS CLI
    $ThisServer = (hostname).ToLower()
    if ($ThisServer -match 'e1') { $Region = "us-east-1"; $ShortRegion = 'e1' }
    elseif ($ThisServer -match 'w2') { $Region = "us-west-2"; $ShortRegion = 'w2' }

    $AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json)

    $EnvironmentName = $AWSVariables.Environment.ToLower()
    $EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

    if (-not $EnvironmentAttribution) {
        [System.Windows.Forms.MessageBox]::Show("Could not detect environment from AWS.","Error","OK","Error")
        return
    }

    # --- Build server list dynamically ---
    $ServerTypeList = @('kms')
    $ServerList = @()

    ForEach ($ServerType in $ServerTypeList) {
        $ServerList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial).Name
    }

    if (-not $ServerList) {
        [System.Windows.Forms.MessageBox]::Show("No servers found for given criteria.","Error","OK","Error")
        return
    }

    $results = @()
    foreach ($computername in $ServerList) {
        $option = New-PSSessionOption -ProxyAccessType NoProxyServer

        $logLines = Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction SilentlyContinue -ScriptBlock {
            param($filePath,$tailCount,$keywords)
            if (Test-Path $filePath) {
                Get-Content -Path $filePath -Tail $tailCount |
                Where-Object { $line = $_; $keywords | ForEach-Object { if ($line -match $_) { return $true } } }
            } else { "NO_LOG_FILE_FOUND" }
        } -ArgumentList $filePath,$tailCount,$keywords

        if ($logLines.Count -eq 0 -or $logLines -contains "NO_LOG_FILE_FOUND") {
            $results += [PSCustomObject]@{ "Server Name"=$computername; "Status Output"="NO_CONNECTION_FOUND"; "StatusClass"="error" }
        } else {
            foreach ($line in $logLines) {
                $statusClass = if ($line -match "Error Code|decrypt failed|Service Stop") { "error" } else { "ok" }
                $results += [PSCustomObject]@{ "Server Name"=$computername; "Status Output"=$line; "StatusClass"=$statusClass }
            }
        }
    }

    # --- Build HTML Report ---
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
    $htmlPath  = "C:\temp\KMSConnectionErrorKeyword-$timestamp.html"

    $htmlHeader = @"
<html>
<head>
<title>KMS Active Connections</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
th { background-color: #333; color: white; }
tr.ok { background-color: #e6ffe6; }
tr.error { background-color: #ffe6e6; font-weight: bold; }
</style>
</head>
<body>
<h2>KMS Active Connection And Error Keyword Report - $timestamp</h2>
<table>
<tr><th>Server Name</th><th>Status Output</th></tr>
"@

    $htmlRows = $results | ForEach-Object { "<tr class='$($_.StatusClass)'><td>$($_.'Server Name')</td><td>$($_.'Status Output')</td></tr>" }
    $htmlFooter = "</table></body></html>"

    $htmlContent = $htmlHeader + ($htmlRows -join "`n") + $htmlFooter
    $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
    Start-Process $htmlPath
})

$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
