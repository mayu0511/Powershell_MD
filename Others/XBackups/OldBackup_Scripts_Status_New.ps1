$sourcePath = "C:\Users\mahendra.dwivedi\Desktop\Newfolder"
$destinationPath = "C:\Users\mahendra.dwivedi\Desktop\Newfolder\a"

$itemsToCopy = Get-ChildItem -Path $sourcePath -Recurse | Where-Object {
    -not ($_.Extension -eq ".log" -or $_.Extension -eq ".zip" -or $_.Extension -eq ".gpg" -or $_.Extension -eq ".pgp" -or $_.Extension -eq ".out" -or $_.Extension -like ".A*" )
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

Write-Output "Files copied successfully, excluding .log, .txt, and A00* files."
