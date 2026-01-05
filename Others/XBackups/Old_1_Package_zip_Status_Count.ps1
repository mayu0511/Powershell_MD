######################################################################################################################
#Package ZIP | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$SourceFolderPath = "E:\Trace\Package\Base\PATQA- 24.8.2"
$destinationFolderPath = "C:\Users\mahendra.dwivedi\Desktop\as"

$subfolders = Get-ChildItem -Path $SourceFolderPath -Directory
$totalItems = $subfolders.Count
$currentItem = 0
$totalFilesZipped = 0

foreach ($folder in $subfolders) {
    $currentItem++
    $percentComplete = ($currentItem / $totalItems) * 100
    Write-Progress -Activity "Zipping Folders" -Status "Zipping $($folder.Name)" -PercentComplete $percentComplete
   
    $folderPath = $folder.FullName
    $folderName = Split-Path -Path $folderPath -Leaf
    $zipFileName = "$destinationFolderPath\$folderName.zip"

    $fileCount = (Get-ChildItem -Path $folderPath -Recurse -File).Count
    $totalFilesZipped += $fileCount

    Compress-Archive -Path $folderPath -DestinationPath $zipFileName -CompressionLevel Fastest
}

$totalSourceFiles = (Get-ChildItem -Path $SourceFolderPath -Recurse -File).Count
$totalDestinationFiles = (Get-ChildItem -Path $destinationFolderPath -File).Count

Write-Host "$currentItem folders zipped successfully." -ForegroundColor Green
Write-Host "A total of $totalFilesZipped files were zipped." -ForegroundColor Green
Write-Host "Source folder contains $totalSourceFiles files." -ForegroundColor Cyan
Write-Host "Destination folder contains $totalDestinationFiles zip files." -ForegroundColor Cyan
