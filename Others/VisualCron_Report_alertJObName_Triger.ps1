# Path to XML
$xmlPath = "E:\Upload\Testing\vstask\settings\jobs.xml"

# Load XML
[xml]$xmlData = Get-Content $xmlPath

# Extract Job Name and Trigger
$jobs = $xmlData.ArrayOfJobClass.JobClass | ForEach-Object {
    $trigger = $_.Triggers.TriggerClass.Description
    [PSCustomObject]@{
        "Job Name"     = $_.Name
        "Trigger Time" = if ($trigger) { $trigger } else { "No Trigger Description" }
    }
}

# Create HTML content
$htmlContent = @"
<html>
<head>
    <title>Job Trigger Report</title>
    <style>
        body { font-family: Segoe UI, sans-serif; background-color: #f4f4f4; padding: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #999; padding: 8px; text-align: left; }
        th { background-color: #333; color: white; }
        tr:nth-child(even) { background-color: #eaeaea; }
    </style>
</head>
<body>
    <h2>Job Trigger Report</h2>
    <table>
        <tr>
            <th>Job Name</th>
            <th>Trigger Time</th>
        </tr>
"@

# Add each job as a table row
foreach ($job in $jobs) {
    $htmlContent += "<tr><td>$($job.'Job Name')</td><td>$($job.'Trigger Time')</td></tr>`n"
}

# Close HTML
$htmlContent += @"
    </table>
</body>
</html>
"@

# Create file path with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$htmlFilePath = "C:\temp\JVJOBTrigertime-$timestamp.html"

# Save HTML file
$htmlContent | Out-File -FilePath $htmlFilePath -Encoding UTF8

# Open HTML file automatically
Start-Process $htmlFilePath
