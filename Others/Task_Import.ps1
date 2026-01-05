$exportedTasksDir = "C:\ExportedTasks"

$userName = "newvisionsoft\mahendra.dwivedi"
$password = "Palak@#12345"

$taskFiles = Get-ChildItem -Path $exportedTasksDir -Filter *.xml

foreach ($taskFile in $taskFiles) {
    try {
        $xmlContent = Get-Content $taskFile.FullName | Out-String

        Register-ScheduledTask -Xml $xmlContent -TaskName $taskFile.BaseName -User $userName -Password $password

        Write-Host "Successfully imported task: $($taskFile.BaseName)"
    } catch {
        Write-Host "Failed to import task: $($taskFile.BaseName). Error: $_"
    }
}

Write-Host "Task import process completed."
