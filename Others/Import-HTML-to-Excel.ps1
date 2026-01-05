# Requires ImportExcel module
try {
    Import-Module ImportExcel -ErrorAction Stop
    Write-Host "ImportExcel module imported successfully. Version: $((Get-Module ImportExcel).Version)"
} catch {
    Write-Error "Failed to import ImportExcel module. Run: Install-Module ImportExcel -Force -Scope CurrentUser"
    return
}

# Verify key cmdlets
if (-not (Get-Command Export-Excel -ErrorAction SilentlyContinue)) {
    Write-Error "Export-Excel cmdlet not found. Reinstall ImportExcel module."
    return
}
if (-not (Get-Command Open-ExcelPackage -ErrorAction SilentlyContinue)) {
    Write-Error "Open-ExcelPackage cmdlet not found. Reinstall ImportExcel module."
    return
}
if (-not (Get-Command Close-ExcelPackage -ErrorAction SilentlyContinue)) {
    Write-Error "Close-ExcelPackage cmdlet not found. Reinstall ImportExcel module."
    return
}

$HtmlFile = "D:\GIT\Config_Comparision\Reports\ENVConfigComparisonReport_20251127_164155.html"
$ExcelFile = "D:\GIT\Config_Comparision\Reports\AWSENVConfigComparisonReport.xlsx"

# Validate file paths
if (-not (Test-Path -Path (Split-Path $ExcelFile -Parent))) {
    Write-Error "The directory for $ExcelFile does not exist."
    return
}
if (-not (Test-Path $HtmlFile)) {
    Write-Error "The HTML file $HtmlFile does not exist or is inaccessible."
    return
}

# Check if the Excel file is locked
function Test-FileLock {
    param ($FilePath)
    try {
        [IO.File]::OpenWrite($FilePath).Close()
        return $false
    } catch {
        return $true
    }
}

# Remove existing Excel file if not locked
if (Test-Path $ExcelFile) {
    if (Test-FileLock -FilePath $ExcelFile) {
        Write-Error "The file $ExcelFile is locked by another process. Please close it and try again."
        return
    }
    try {
        Remove-Item $ExcelFile -Force -ErrorAction Stop
        Write-Host "Removed existing Excel file: $ExcelFile"
    } catch {
        Write-Error "Failed to remove existing Excel file: $_"
        return
    }
}

# Load HTML using htmlfile COM object
$ie = New-Object -ComObject "htmlfile"
try {
    $htmlContent = Get-Content $HtmlFile -Raw -ErrorAction Stop
    $ie.IHTMLDocument2_write($htmlContent)
} catch {
    Write-Error "Failed to load HTML file: $_"
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie) | Out-Null
    return
}

$Tables = $ie.getElementsByTagName("table")
if ($Tables.length -eq 0) {
    Write-Warning "No tables found in HTML file."
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie) | Out-Null
    return
}
Write-Host "Found $($Tables.length) tables in HTML file."

# Initialize Excel package
$excelPackage = $null
$firstTableExported = $false

$tableIndex = 1
foreach ($Table in $Tables) {
    # Find the preceding 'File: ' text for Section and sheet name
    $node = $Table.previousSibling
    while ($node -and ($node.nodeType -eq 3) -and [string]::IsNullOrWhiteSpace($node.nodeValue)) {
        $node = $node.previousSibling
    }
    $fileText = if ($node -and $node.nodeType -eq 3) { $node.nodeValue.Trim() } else { "" }

    $worksheetName = "Sheet$tableIndex"
    if ($fileText -match '^File:\s*(.+)') {
        $fileName = $matches[1].Trim()
        $worksheetName = $fileName -replace '[\\/:*?"<>| ]', '_'
        $worksheetName = $worksheetName.Substring(0, [Math]::Min(31, $worksheetName.Length))
    } elseif ($tableIndex -eq 1) {
        $worksheetName = "Summary"
    }

    $Rows = @()
    $FirstRow = $Table.rows | Select-Object -First 1

    if (-not $FirstRow) {
        Write-Warning "Table $tableIndex is empty. Skipping..."
        $tableIndex++
        continue
    }

    # Get headers and insert 'Section' as the first column
    $Headers = @('Section')
    foreach ($cell in $FirstRow.cells) {
        $Headers += if ($null -ne $cell.innerText) { $cell.innerText.Trim() } else { "" }
    }

    if ($Headers.Count -le 1) {
        Write-Warning "No headers found in table $tableIndex. Skipping..."
        $tableIndex++
        continue
    }

    # Process data rows
    $DataRows = $Table.rows | Select-Object -Skip 1
    foreach ($Row in $DataRows) {
        if ($null -eq $Row) {
            Write-Warning "Skipping null row in table $tableIndex."
            continue
        }
        if ($null -eq $Row.cells -or $Row.cells.length -eq 0) {
            Write-Warning "Skipping row in table $tableIndex due to null or empty cells."
            continue
        }

        $Obj = [ordered]@{}
        $Obj['Section'] = $fileText
        for ($i = 0; $i -lt ($Headers.Count - 1); $i++) {
            $cellText = ""
            if ($i -lt $Row.cells.length) {
                $cell = $Row.cells.item($i)
                if ($null -ne $cell -and $null -ne $cell.innerText) {
                    $cellText = $cell.innerText.Trim()
                }
            }
            $Obj[$Headers[$i + 1]] = $cellText
        }
        $Rows += New-Object PSObject -Property $Obj
    }

    if ($Rows.Count -gt 0) {
        try {
            if (-not $firstTableExported) {
                # First table: Create file and get package
                $excelPackage = $Rows | Export-Excel -Path $ExcelFile -WorksheetName $worksheetName -AutoSize -FreezeTopRow -TableStyle Medium2 -PassThru -ErrorAction Stop
                $firstTableExported = $true
                Write-Host "Table $tableIndex exported as $worksheetName to new Excel file."
            } else {
                # Subsequent tables: Reuse package
                $excelPackage = $Rows | Export-Excel -ExcelPackage $excelPackage -WorksheetName $worksheetName -AutoSize -FreezeTopRow -TableStyle Medium2 -PassThru -ErrorAction Stop
                Write-Host "Table $tableIndex exported as $worksheetName to existing Excel file."
            }
        } catch {
            Write-Error "Failed to export Table $tableIndex ($worksheetName) to Excel: $_"
            $tableIndex++
            continue
        }
    } else {
        Write-Warning "Table $tableIndex has no data. Skipping export."
    }

    $tableIndex++
}

# Save and close the Excel package
if ($null -ne $excelPackage) {
    try {
        Close-ExcelPackage -ExcelPackage $excelPackage -ErrorAction Stop
        Write-Host "Excel file saved successfully at $ExcelFile"
    } catch {
        Write-Error "Failed to save Excel file: $_"
    }
} elseif ($firstTableExported) {
    Write-Warning "Excel package is null, but some tables were exported. File may be incomplete."
} else {
    Write-Warning "No tables were exported. Excel file was not created."
}

# Clean up COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie) | Out-Null
Write-Host "Script completed."