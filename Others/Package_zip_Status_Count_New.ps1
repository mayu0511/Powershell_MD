######################################################################################################################
#Package ZIP | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.1 | Added error handling | Date:: 29-May-2025
#=====================================================================================================================
   Clear-Host
    Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
    } | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
    }

$SourceFolderPath = "D:\Packages\COOKIE\POD2\PATUAT\CP7029_POD2-PAT-UAT_24.12_TO_25.2.6\Consolidated_Package"
$destinationFolderPath = "C:\Users\configuser\Documents\dd"

# Create timestamp and log file
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFileName = "Packagezip_$timestamp.txt"
$logFilePath = "C:\Temp\$logFileName"

$logOutput = @()
$errorOutput = @()
$totalFilesZipped = 0

# Log basic info
$logOutput += "Log Timestamp: $timestamp"
$logOutput += "Source Folder Path: $SourceFolderPath"
$logOutput += "Destination Folder Path: $destinationFolderPath"
$logOutput += ""

# Get subfolders and process them
$subfolders = Get-ChildItem -Path $SourceFolderPath -Directory
$totalItems = $subfolders.Count
$currentItem = 0

foreach ($folder in $subfolders) {
    $currentItem++
    $percentComplete = ($currentItem / $totalItems) * 100
    Write-Progress -Activity "Zipping Folders" -Status "Zipping $($folder.Name)" -PercentComplete $percentComplete

    $folderPath = $folder.FullName
    $folderName = Split-Path -Path $folderPath -Leaf
    $zipFileName = "$destinationFolderPath\$folderName.zip"

    try {
        if (Test-Path -Path $zipFileName) {
            Remove-Item -Path $zipFileName -Force
        }

        $fileCount = (Get-ChildItem -Path $folderPath -Recurse -File).Count
        Compress-Archive -Path $folderPath -DestinationPath $zipFileName -CompressionLevel Fastest

        $totalFilesZipped += $fileCount
    }
    catch {
        $errorOutput += "ERROR: Failed to zip folder '$folderPath'"
        $errorOutput += "       Reason: $($_.Exception.Message)"
        continue
    }
}

# Final summary
$totalSourceFiles = (Get-ChildItem -Path $SourceFolderPath -Recurse -File).Count
$totalDestinationFiles = (Get-ChildItem -Path $destinationFolderPath -File).Count

$logOutput += "$currentItem folders processed."
$logOutput += "A total of $totalFilesZipped files were zipped."
$logOutput += "Source folder contains $totalSourceFiles files."
$logOutput += "Destination folder contains $totalDestinationFiles zip files."

# Display output
$logOutput | ForEach-Object { Write-Host $_ }
if ($errorOutput.Count -gt 0) {
    Write-Host "`nErrors encountered during zipping:" -ForegroundColor Red
    $errorOutput | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}

# Save to log file
$logOutput + "" + $errorOutput | Set-Content -Path $logFilePath
