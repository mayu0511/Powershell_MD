$SourceFolderPath = "E:\Upload"
$destinationFolderPath = "C:\Users\mahendra.dwivedi\Desktop\as"

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

    Compress-Archive -Path $folderPath -DestinationPath $zipFileName -CompressionLevel Fastest
}

Write-Host "$currentItem folders zipped successfully." -ForegroundColor Green
