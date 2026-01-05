# Define paths
$path1 = "C:\Users\mahendra.dwivedi\Desktop\Packages2"
$path2 = "C:\Users\mahendra.dwivedi\Desktop\Packages3"
# Get all relative paths recursively
$items1 = Get-ChildItem -Path $path1 -Recurse | ForEach-Object {
    $_.FullName.Replace($path1, '').TrimStart('\')
}
$items2 = Get-ChildItem -Path $path2 -Recurse | ForEach-Object {
    $_.FullName.Replace($path2, '').TrimStart('\')
}

# Sort
$items1 = $items1 | Sort-Object
$items2 = $items2 | Sort-Object

# Compare
$comparison = Compare-Object -ReferenceObject $items1 -DifferenceObject $items2

# Get counts
$totalPath1 = $items1.Count
$totalPath2 = $items2.Count
$mismatched = $comparison.Count
$matched = [Math]::Min($totalPath1, $totalPath2) - $mismatched

# Output
Write-Host "================== Folder Comparison Report ==================" -ForegroundColor Cyan
Write-Host "Path 1: $path1" -ForegroundColor DarkGray
Write-Host "Path 2: $path2" -ForegroundColor DarkGray
Write-Host "---------------------------------------------------------------"
Write-Host "Total Items in Path 1 : $totalPath1" -ForegroundColor Yellow
Write-Host "Total Items in Path 2 : $totalPath2" -ForegroundColor Yellow
Write-Host "Matched Items         : $matched" -ForegroundColor Green
Write-Host "Mismatched Items      : $mismatched" -ForegroundColor Red
Write-Host "---------------------------------------------------------------"

if ($mismatched -eq 0) {
    Write-Host "✅ Matched: All folders and files are identical." -ForegroundColor Green
} else {
    Write-Host "❌ Mismatched items:" -ForegroundColor Red
    $comparison | ForEach-Object {
        $side = if ($_.SideIndicator -eq "<=") { "Only in Path 1" } else { "Only in Path 2" }
        Write-Host " - [$side] $($_.InputObject)" -ForegroundColor Red
    }
}
