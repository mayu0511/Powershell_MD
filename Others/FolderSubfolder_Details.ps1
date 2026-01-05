# Define the folder path to exclude (use escaped backslashes)
$excludeFolder = "E:\\Trace\\Container"

# Define the output file path
$outputFile = "E:\FolderName55s.txt"

# Get all folder names in ascending order, excluding the specified folder and its subfolders, and write to a file
Get-ChildItem -Recurse "E:\Trace" | 
    Where-Object { 
        $_.PSIsContainer -and 
        ($_.FullName -notmatch [regex]::Escape($excludeFolder))  # Exclude folder and subfolders based on full folder path
    } | 
    Select-Object -ExpandProperty FullName |
    Sort-Object | 
    Out-File -FilePath $outputFile

Write-Host "Folder names have been written to $outputFile"
