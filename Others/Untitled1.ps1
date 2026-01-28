# Config File Comparison Script
# Compares two XML config files and generates a detailed report

param(
    [string]$MasterFile = "C:\Users\mahendra.dwivedi\Desktop\Ori\Web_Master.config",
    [string]$EnvFile = "C:\Users\mahendra.dwivedi\Desktop\bac\Web.config",
    [string]$OutputReport = "C:\Users\mahendra.dwivedi\Desktop\ConfigComparison_Report.html"
)

# Load XML files
try {
    [xml]$masterXml = Get-Content $MasterFile -Raw
    [xml]$envXml = Get-Content $EnvFile -Raw
} catch {
    Write-Error "Failed to load XML files: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Function to get all XML paths and values
function Get-XmlPaths {
    param([System.Xml.XmlNode]$Node, [string]$Path = "")
    
    $results = @{}
    
    if ($Node.HasChildNodes) {
        foreach ($child in $Node.ChildNodes) {
            if ($child.NodeType -eq "Element") {
                $currentPath = if ($Path) { "$Path/$($child.Name)" } else { $child.Name }
                
                # Store attributes
                if ($child.Attributes) {
                    foreach ($attr in $child.Attributes) {
                        $attrPath = "$currentPath[@$($attr.Name)]"
                        $results[$attrPath] = $attr.Value
                    }
                }
                
                # Store inner text if leaf node
                if ($child.ChildNodes.Count -eq 1 -and $child.FirstChild.NodeType -eq "Text") {
                    $results[$currentPath] = $child.InnerText
                }
                
                # Recurse
                $childResults = Get-XmlPaths -Node $child -Path $currentPath
                foreach ($key in $childResults.Keys) {
                    $results[$key] = $childResults[$key]
                }
            }
        }
    }
    
    return $results
}

# Get all paths from both files
$masterPaths = Get-XmlPaths -Node $masterXml.DocumentElement
$envPaths = Get-XmlPaths -Node $envXml.DocumentElement

# Get all unique paths
$allPaths = ($masterPaths.Keys + $envPaths.Keys) | Select-Object -Unique | Sort-Object

# Build comparison results
$results = @()
foreach ($path in $allPaths) {
    $masterValue = $masterPaths[$path]
    $envValue = $envPaths[$path]
    
    $status = if ($masterValue -eq $envValue) {
        "✓ Match"
    } elseif (-not $masterPaths.ContainsKey($path)) {
        "⚠ Only in Env"
    } elseif (-not $envPaths.ContainsKey($path)) {
        "⚠ Only in Master"
    } else {
        "✗ Different"
    }
    
    $results += [PSCustomObject]@{
        TagName = $path
        MasterValue = if ($masterValue) { $masterValue } else { "(not present)" }
        EnvValue = if ($envValue) { $envValue } else { "(not present)" }
        Status = $status
    }
}

# Generate HTML Report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Config Comparison Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { background: #f0f0f0; padding: 15px; margin: 20px 0; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background: #4CAF50; color: white; padding: 12px; text-align: left; }
        td { border: 1px solid #ddd; padding: 10px; }
        tr:nth-child(even) { background: #f9f9f9; }
        .match { color: green; }
        .different { color: red; font-weight: bold; }
        .only-master, .only-env { color: orange; }
        .value-cell { max-width: 300px; word-wrap: break-word; }
    </style>
</head>
<body>
    <h1>Configuration File Comparison Report</h1>
    <div class="summary">
        <p><strong>Master File:</strong> $MasterFile</p>
        <p><strong>Environment File:</strong> $EnvFile</p>
        <p><strong>Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Total Entries:</strong> $($results.Count)</p>
        <p><strong>Matches:</strong> $(($results | Where-Object {$_.Status -eq '✓ Match'}).Count)</p>
        <p><strong>Differences:</strong> $(($results | Where-Object {$_.Status -eq '✗ Different'}).Count)</p>
        <p><strong>Only in Master:</strong> $(($results | Where-Object {$_.Status -eq '⚠ Only in Master'}).Count)</p>
        <p><strong>Only in Env:</strong> $(($results | Where-Object {$_.Status -eq '⚠ Only in Env'}).Count)</p>
    </div>
    <table>
        <thead>
            <tr>
                <th>Tag Name / Path</th>
                <th>Master File Value</th>
                <th>Environment File Value</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
"@

foreach ($item in $results) {
    $statusClass = switch ($item.Status) {
        "✓ Match" { "match" }
        "✗ Different" { "different" }
        default { "only-master" }
    }
    
    $html += @"
            <tr>
                <td><strong>$($item.TagName)</strong></td>
                <td class="value-cell">$($item.MasterValue)</td>
                <td class="value-cell">$($item.EnvValue)</td>
                <td class="$statusClass">$($item.Status)</td>
            </tr>
"@
}

$html += @"
        </tbody>
    </table>
</body>
</html>
"@

# Save HTML report
$html | Out-File -FilePath $OutputReport -Encoding UTF8

# Also export to CSV for Excel
$csvPath = $OutputReport -replace '\.html$', '.csv'
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`n✓ Comparison complete!" -ForegroundColor Green
Write-Host "HTML Report: $OutputReport" -ForegroundColor Cyan
Write-Host "CSV Report: $csvPath" -ForegroundColor Cyan
Write-Host "`nOpening HTML report..." -ForegroundColor Yellow

# Open the report
Start-Process $OutputReport

# Display summary in console
Write-Host "`n=== SUMMARY ===" -ForegroundColor Magenta
Write-Host "Total Entries: $($results.Count)"
Write-Host "Matches: $(($results | Where-Object {$_.Status -eq '✓ Match'}).Count)" -ForegroundColor Green
Write-Host "Differences: $(($results | Where-Object {$_.Status -eq '✗ Different'}).Count)" -ForegroundColor Red
Write-Host "Only in Master: $(($results | Where-Object {$_.Status -eq '⚠ Only in Master'}).Count)" -ForegroundColor Yellow
Write-Host "Only in Env: $(($results | Where-Object {$_.Status -eq '⚠ Only in Env'}).Count)" -ForegroundColor Yellow