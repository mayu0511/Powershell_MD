# Load Excel COM Object
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

# Open First Workbook (Lenox Sheet)
$workbook1 = $excel.Workbooks.Open("C:\Users\mahendra.dwivedi\Desktop\EXcel\Jira_list_AssignTo_Lenox (1).xlsx")
$sheet1 = $workbook1.Sheets.Item(1)

# Open Second Workbook (Retro Sheet)
$workbook2 = $excel.Workbooks.Open("C:\Users\mahendra.dwivedi\Desktop\EXcel\Production Upgrade - Config Retro Sheet.xlsx")
$sheet2 = $workbook2.Sheets.Item(1)

# Get last row in both sheets
$lastRow1 = $sheet1.UsedRange.Rows.Count
$lastRow2 = $sheet2.UsedRange.Rows.Count

# Find column numbers for "Jira No" in both sheets
$headers1 = @{}
$headers2 = @{}

for ($col = 1; $col -le $sheet1.UsedRange.Columns.Count; $col++) {
    $value = $sheet1.Cells.Item(1, $col).Text.Trim()
    if ($value -ne "") { $headers1[$value] = $col }
}

for ($col = 1; $col -le $sheet2.UsedRange.Columns.Count; $col++) {
    $value = $sheet2.Cells.Item(1, $col).Text.Trim()
    if ($value -ne "") { $headers2[$value] = $col }
}

# Validate that "Jira No" column exists
if (-not $headers1.ContainsKey("Jira No") -or -not $headers2.ContainsKey("Jira No")) {
    Write-Host "❌ 'Jira No' column not found in one of the sheets."
    $excel.Quit()
    exit
}

$jiraCol1 = $headers1["Jira No"]
$jiraCol2 = $headers2["Jira No"]

# Read Jira numbers from Sheet2 into HashSet for quick lookup
$jiraNumbersSheet2 = @{}

for ($row = 2; $row -le $lastRow2; $row++) {
    $jira = $sheet2.Cells.Item($row, $jiraCol2).Text.Trim()
    if ($jira -ne "") {
        $jiraNumbersSheet2[$jira] = $true
    }
}

# Add 'Status' Header if not present
$statusCol = $headers1["Status"]
if (-not $statusCol) {
    $statusCol = $sheet1.UsedRange.Columns.Count + 1
    $sheet1.Cells.Item(1, $statusCol).Value() = "Status"
}

# Compare Jira numbers and mark duplicates
for ($row = 2; $row -le $lastRow1; $row++) {
    $jira = $sheet1.Cells.Item($row, $jiraCol1).Text.Trim()
    if ($jira -ne "" -and $jiraNumbersSheet2.ContainsKey($jira)) {
        $sheet1.Cells.Item($row, $statusCol).Value() = "Duplicate"
    } else {
        $sheet1.Cells.Item($row, $statusCol).Value() = "Unique"
    }
}

# Save and Close
$workbook1.Save()
$workbook1.Close()
$workbook2.Close()
$excel.Quit()

Write-Host "✅ Duplicate marking completed successfully."
