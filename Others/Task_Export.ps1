$outputDir = "C:\ExportedTasks"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

$tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -eq "\" }

foreach ($task in $tasks) {
    $taskXml = Get-ScheduledTask -TaskName $task.TaskName | Export-ScheduledTask

    $safeTaskName = $task.TaskName -replace '[\\/:*?"<>|]', '_'
    $filePath = "$outputDir\$safeTaskName.xml"

    $taskXml | Out-File -FilePath $filePath

    Write-Host "Exported task: $task.TaskName to $filePath"
}

Write-Host "Task export completed."
