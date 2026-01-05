$sourcePath = "C:\SourceFolder"
$destinationPath = "C:\DestinationFolder"

$itemsToCopy = Get-ChildItem -Path $sourcePath -Recurse | Where-Object {
    -not ($_.Extension -eq ".log" -or $_.Extension -eq ".txt")
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

Write-Output "Files copied successfully, excluding .log and .txt files."
