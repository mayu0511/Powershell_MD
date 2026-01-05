######################################################################################################################
# Code Deployment Comparison | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 18-June-2025
#=====================================================================================================================

# Source and destination root paths
$sourceFolder = "C:\Users\mahendra.dwivedi\Desktop\1"
$destinationFolder = "C:\Users\mahendra.dwivedi\Desktop\2"

# Output HTML file with date and time
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputFile = "C:\Temp\FileFolderComparison_$timestamp.html"

# Create arrays to hold HTML content
$htmlRows = @()

# HTML structure
$htmlHeader = @"
<html>
<head>
    <style>
        body { font-family: Consolas; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; }
        .match { color: green; }
        .mismatch { color: red; }
    </style>
</head>
<body>
<h2>File & Folder Comparison Report ($timestamp)</h2>
<table>
<tr><th>Path</th><th>Type</th><th>Status</th></tr>
"@

$htmlFooter = @"
</table>
</body>
</html>
"@

# Compare folders first
$sourceDirs = Get-ChildItem -Path $sourceFolder -Recurse -Directory

foreach ($srcDir in $sourceDirs) {
    $relativePath = $srcDir.FullName.Substring($sourceFolder.Length).TrimStart('\')
    $destDirPath = Join-Path $destinationFolder $relativePath

    if (Test-Path $destDirPath) {
        $htmlRows += "<tr><td>$relativePath</td><td>Folder</td><td class='match'>Exists</td></tr>"
    } else {
        $htmlRows += "<tr><td>$relativePath</td><td>Folder</td><td class='mismatch'>Missing</td></tr>"
    }
}

# Compare files with hash
$sourceFiles = Get-ChildItem -Path $sourceFolder -File -Recurse

foreach ($srcFile in $sourceFiles) {
    $relativePath = $srcFile.FullName.Substring($sourceFolder.Length).TrimStart('\')
    $destFilePath = Join-Path $destinationFolder $relativePath

    if (Test-Path $destFilePath) {
        # Compare hashes
        $srcHash = Get-FileHash -Path $srcFile.FullName -Algorithm SHA256
        $dstHash = Get-FileHash -Path $destFilePath -Algorithm SHA256

        if ($srcHash.Hash -eq $dstHash.Hash) {
            $htmlRows += "<tr><td>$relativePath</td><td>File</td><td class='match'>Identical</td></tr>"
        } else {
            $htmlRows += "<tr><td>$relativePath</td><td>File</td><td class='mismatch'>Mismatch</td></tr>"
        }
    } else {
        $htmlRows += "<tr><td>$relativePath</td><td>File</td><td class='mismatch'>Missing in Destination</td></tr>"
    }
}

# Combine and write HTML report
$htmlContent = $htmlHeader + ($htmlRows -join "`n") + $htmlFooter
$htmlContent | Out-File -FilePath $outputFile -Encoding UTF8

# Open the HTML file
Start-Process $outputFile
