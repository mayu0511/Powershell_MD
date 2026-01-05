######################################################################################################################
# Backup | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================

$sourcePath = "D:\Backup\BAT1\DBBSetup\Dump\Account_Deletion\FilePath\LogFile"
$destinationPath = "D:\Backup\5nov2024_backup"

$itemsToCopy = Get-ChildItem -Path $sourcePath -Recurse | Where-Object {
    -not ($_.Extension -eq ".log" -or $_.Extension -eq ".zip" -or $_.Extension -eq ".gpg" -or $_.Extension -eq ".pgp" -or $_.Extension -eq ".ipm" -or $_.Extension -eq ".out" -or $_.Extension -like ".A*" -or $_.Name -match "^ACH" -or $_.Name -match "^LogFileStep" -or $_.Name -match "^BulkFileResponse_")
}

$totalItems = $itemsToCopy.Count
$currentItem = 0

foreach ($item in $itemsToCopy) {
    $currentItem++
    $percentComplete = ($currentItem / $totalItems) * 100
    Write-Progress -Activity "Copying Files" -Status "Copying $($item.Name)" -PercentComplete $percentComplete

    $destItemPath = $item.FullName.Replace($sourcePath, $destinationPath)

    if ($item.PSIsContainer) {
        if (!(Test-Path -Path $destItemPath)) {
            New-Item -ItemType Directory -Path $destItemPath | Out-Null
        }
    } else {
        Copy-Item -Path $item.FullName -Destination $destItemPath
    }
}

Write-Output "Files copied successfully, excluding specified files."
