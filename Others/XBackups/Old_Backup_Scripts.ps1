$sourcePath = "C:\SourceFolder"
$destinationPath = "C:\DestinationFolder"
$itemsToCopy = Get-ChildItem -Path $sourcePath -Recurse | Where-Object {
    -not ($_.Extension -eq ".log" -or $_.Extension -eq ".txt")
}

foreach ($item in $itemsToCopy) {
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
