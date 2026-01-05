# Load Excel COM Object
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

# Open the Excel Workbook
$workbook = $excel.Workbooks.Open("C:\Users\mahendra.dwivedi\Desktop\EXcel\Jira_Status.xlsx")

# Get the Sheet (First Sheet)
$sheet = $workbook.Sheets.Item(1)

# Get Last Row
$LastRow = $sheet.UsedRange.Rows.Count

# Hashtable to track occurrences
$JiraTracker = @{}

# Loop through each row starting from Row 2
for ($i = 2; $i -le $LastRow; $i++) {
    $JiraNo = $sheet.Cells.Item($i, 1).Text.Trim()  # Column A (1)
    if ($JiraNo -ne "") {
        if ($JiraTracker.ContainsKey($JiraNo)) {
            # If Jira No already seen before, mark as Duplicate
            $sheet.Cells.Item($i, 2).Value2 = "Duplicate"  # Column B
        } else {
            # First occurrence, add to tracker, no marking
            $JiraTracker[$JiraNo] = $true
            $sheet.Cells.Item($i, 2).Value2 = ""
        }
    }
}

# Save and Close Excel
$workbook.Save()
$workbook.Close()
$excel.Quit()

# Release COM Objects
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($sheet) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

Write-Host "✅ Duplicates after first occurrence marked successfully."
