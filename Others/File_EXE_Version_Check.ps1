# Define the target folder and output HTML file
$FolderPath = "E:\Trace\Package\Base\PATQA- 24.8.2\filesplitter\DBBSetup\MonitoringScript"
$HtmlReportPath = "E:\EXE_Versions_Report.html"

# Check if the folder exists
if (Test-Path $FolderPath) {
    # Get all .exe files in the folder and subfolders
    $ExeFiles = Get-ChildItem -Path $FolderPath -Filter "*.exe" -Recurse -File

    # Create an array to store results
    $Results = @()

    # Loop through each .exe file
    foreach ($Exe in $ExeFiles) {
        $FileVersion = (Get-Item $Exe.FullName).VersionInfo.FileVersion
        $Results += [PSCustomObject]@{
            "EXE Name" = $Exe.Name
            "Version"  = $FileVersion
            "Path"     = $Exe.FullName
        }
    }

    # Generate HTML with styling
    $HtmlHeader = @"
    <html>
    <head>
        <title>EXE Version Report</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; padding: 20px; }
            h2 { text-align: center; color: #333; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
            th { background-color: #4CAF50; color: white; }
            tr:nth-child(even) { background-color: #f2f2f2; }
            tr:hover { background-color: #ddd; }
        </style>
    </head>
    <body>
    <h2>EXE Version Report</h2>
    <table>
    <tr><th>EXE Name</th><th>Version</th><th>Path</th></tr>
"@

    # Generate table rows
    $HtmlBody = $Results | ForEach-Object {
        "<tr><td>$($_.'EXE Name')</td><td>$($_.Version)</td><td>$($_.Path)</td></tr>"
    }

    $HtmlFooter = @"
    </table>
    </body>
    </html>
"@

    # Combine HTML parts and save the report
    $HtmlContent = $HtmlHeader + ($HtmlBody -join "`n") + $HtmlFooter
    $HtmlContent | Out-File -Encoding utf8 $HtmlReportPath

    # Open the HTML file after generation
    Invoke-Item $HtmlReportPath

    Write-Host "Report generated: $HtmlReportPath"
} else {
    Write-Host "Folder not found: $FolderPath"
}
