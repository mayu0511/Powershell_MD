######################################################################################################################
# Zip and Unzip| DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

#=============Zip===========
$sourceFolder = "C:\Path\To\Your\Folder"
$destinationZip = "C:\Path\To\Your\Destination\Archive.zip"
Compress-Archive -Path $sourceFolder -DestinationPath $destinationZip -Force
Write-Output "Folder zipped successfully to $destinationZip"

#======Unzip=======
<#

$zipFile = "C:\Path\To\Your\Archive.zip"
$destinationFolder = "C:\Path\To\Your\Destination\Folder"
Expand-Archive -Path $zipFile -DestinationPath $destinationFolder -Force
Write-Output "File unzipped successfully to $destinationFolder"

#>