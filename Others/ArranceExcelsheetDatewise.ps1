# Excel File Path
$ExcelFilePath = "C:\Users\mahendra.dwivedi\Desktop\EXcel\Jira_Status.xlsx"

# Initialize Excel COM Object
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $false
$Excel.DisplayAlerts = $false

# Open Workbook
$Workbook = $Excel.Workbooks.Open($ExcelFilePath)
$Worksheet = $Workbook.Sheets.Item(1)

# Get Used Range
$UsedRange = $Worksheet.UsedRange
$LastRow = $UsedRange.Rows.Count
$LastCol = $UsedRange.Columns.Count

# Sorting Range (entire used range)
$SortRange = $Worksheet.Range("A1").Resize($LastRow, $LastCol)

# Sort by Date Column (Column 1 => A)
$SortRange.Sort(
    [ref]$Worksheet.Cells.Item(1,1), # Key1: First Column (Date)
    1,                               # xlAscending (1)
    [Type]::Missing,                 # No second key
    [Type]::Missing,                 # No second order
    1,                               # Header: xlYes
    [Type]::Missing,                 # MatchCase
    [Type]::Missing,                 # Orientation
    1                                # SortMethod: xlPinYin
)

# Save & Close Workbook
$Workbook.Save()
$Workbook.Close()
$Excel.Quit()

# Cleanup COM Objects
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Worksheet) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Workbook) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Excel) | Out-Null

Write-Host "✅ Excel file sorted date-wise successfully!" -ForegroundColor Green
