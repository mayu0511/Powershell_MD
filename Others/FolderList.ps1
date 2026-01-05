# Define the path
$path = "E:\Trace\Package\Base\PATUAT\filesplitter\DBBSetup\MonitoringScript\FileSplitter"

# Get all folders and files (non-recursive)
$items = Get-ChildItem -Path $path

# Get just the names
$names = $items | Select-Object -ExpandProperty Name

# Display in console
$names

# Export to file
$names | Out-File -FilePath "C:\Temp\FolderAndFileList.txt"
