######################################################################################################################
# Backup | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.2 | Fixed Folder Copy Issue | Date:: 24-Mar-2025
#=====================================================================================================================

$sourcePath = "E:\Backup\Data"
$destinationPath = "C:\Users\mahendra.dwivedi\Desktop\aa"

$itemsToCopy = Get-ChildItem -Path $sourcePath -Recurse -Force | Where-Object {
    -not ($_.Extension -eq ".log" -or $_.Extension -eq ".zip" -or $_.Extension -eq ".gpg" -or $_.Extension -eq ".pgp" -or $_.Extension -eq ".ipm" -or $_.Extension -eq ".out" -or $_.Extension -like ".A*" -or $_.Name -match "^ACH" -or $_.Name -match "^LogFileStep" -or $_.Name -match "^BulkFileResponse_")
}

$totalItems = $itemsToCopy.Count
$currentItem = 0

foreach ($item in $itemsToCopy) {
    $currentItem++
    $percentComplete = ($currentItem / $totalItems) * 100
    Write-Progress -Activity "Copying Files" -Status "Copying $($item.Name)" -PercentComplete $percentComplete

    $destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)
    $destFolderPath = [System.IO.Path]::GetDirectoryName($destItemPath)

    if (!(Test-Path -Path $destFolderPath)) {
        New-Item -ItemType Directory -Path $destFolderPath -Force | Out-Null
    }

    if ($item.PSIsContainer) {
        if (!(Test-Path -Path $destItemPath)) {
            New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null
        }
    } else {
        Copy-Item -Path $item.FullName -Destination $destItemPath -Force
    }
}

# Ensure all folders are copied
$sourceFolders = Get-ChildItem -Path $sourcePath -Directory -Recurse -Force
foreach ($folder in $sourceFolders) {
    $destFolder = $folder.FullName.Replace($sourcePath, $destinationPath)
    if (!(Test-Path -Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }
}

# Count folders in source and destination
$sourceFolderCount = (Get-ChildItem -Path $sourcePath -Directory -Recurse -Force).Count
$destinationFolderCount = (Get-ChildItem -Path $destinationPath -Directory -Recurse -Force).Count

Write-Output "Source Folder Count: $sourceFolderCount"
Write-Output "Destination Folder Count: $destinationFolderCount"

if ($sourceFolderCount -eq $destinationFolderCount) {
    Write-Host "Folder count matches." -ForegroundColor Green
} else {
    Write-Host "Folder count mismatch! Please verify the backup." -ForegroundColor Red
}
