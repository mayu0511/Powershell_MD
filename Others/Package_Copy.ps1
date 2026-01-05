$sourcePath = "E:\Trace\Soft"
$destinationPath = "C:\Users\mahendra.dwivedi\Desktop\12"

try {
    
    $itemsToCopy = Get-ChildItem -Path $sourcePath -Recurse
    $totalItems = $itemsToCopy.Count
    $currentItem = 0

       foreach ($item in $itemsToCopy) {
        $currentItem++
        $percentComplete = ($currentItem / $totalItems) * 100

        Write-Progress -Activity "Copying Files" -Status "Copying $($item.FullName)" -PercentComplete $percentComplete

        $destination = Join-Path -Path $destinationPath -ChildPath ($item.FullName -replace [regex]::Escape($sourcePath), "")
        
        if ($item.PSIsContainer) {
            
            if (!(Test-Path -Path $destination)) {
                New-Item -ItemType Directory -Path $destination | Out-Null
            }
        } else {
            
            Copy-Item -Path $item.FullName -Destination $destination -Force
        }
    }

    Write-Host "Files copied successfully from $sourcePath to $destinationPath." -ForegroundColor Green
} catch {
    
    Write-Host "An error occurred while copying files:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}
