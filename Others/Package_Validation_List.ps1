#==============Define package path and expected items file======================

#============Cookie=============================================================

$package = "D:\Packages\COOKIE\POD2\GSDEV\CP5985_POD2-GS-Dev_25.2.2_TO_25.2.6\Package"
$expectedItemsFile = "D:\Packages\Cookie_items.txt"

#============JAZZ==================================================================

#$package = "D:\Packages\JAZZ\PROD\CP5983_POD3-Jazz-Production_24.12_TO_25.2.2\Package"
#$expectedItemsFile = "D:\Packages\Jazz_items.txt"


#Read expected items
$expectedItems = Get-Content -Path $expectedItemsFile

# Get actual files and folders
$receivedFiles = Get-ChildItem -Path $package -File | Select-Object -ExpandProperty Name
$folderCount = (Get-ChildItem -Path $package -Directory).Count

# Display counts
Write-Host "Total expected items : $($expectedItems.Count)" -ForegroundColor Cyan
Write-Host "Total received files : $($receivedFiles.Count)" -ForegroundColor Cyan
#Write-Host "Total folders        : $folderCount" -ForegroundColor Cyan

# Find missing items
$missingItems = $expectedItems | Where-Object { $_ -notin $receivedFiles }

# Output results
if ($missingItems.Count -eq 0) {
    Write-Host "`n✅ All expected items are present in the package." -ForegroundColor Green
} else {
    Write-Host "`n❌ Missing items in the package:" -ForegroundColor Red
    $missingItems | ForEach-Object {
        Write-Host "- $_" -ForegroundColor Red
    }
}
