$SourceFolderPath = "D:\Packages\COOKIE\POD2\PERF\CP5847_POD2-PAT-PERF_24.9.1_TO_24.10.2\Consolidated_Package"
$destinationFolderPath = "D:\Packages\COOKIE\POD2\PERF\CP5847_POD2-PAT-PERF_24.9.1_TO_24.10.2\Consolidated_Package"
$subfolders = Get-ChildItem -Path $SourceFolderPath -Directory
foreach ($folder in $subfolders) {
    $folderPath = $folder.FullName
    $folderName = Split-Path -Path $folderPath -Leaf
    $zipFileName = "$destinationFolderPath\$folderName.zip"
    Compress-Archive -Path $folderPath -DestinationPath $zipFileName -CompressionLevel Fastest
}
Write-Host "Zipping completed"