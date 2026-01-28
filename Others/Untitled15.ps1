<#
.SYNOPSIS
Unified BAT file comparison and update tool
.DESCRIPTION
- Compares Original and Backup BAT files
- Generates HTML report
- Updates mismatched tags
- Inserts missing tags
- Section-based insert optional
- Backups original before any changes
- Logs all actions
- Supports rollback
#>

Clear-Host

# ------------------ CONFIG ------------------
$DefaultLogDir = "C:\temp"
if (!(Test-Path $DefaultLogDir)) { New-Item -ItemType Directory -Path $DefaultLogDir | Out-Null }

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile   = "$DefaultLogDir\BAT_Update_$TimeStamp.log"
$HtmlFile  = "$DefaultLogDir\BAT_Report_$TimeStamp.html"
$SectionMarker = "REM === CORE SETTINGS START ==="  # Optional section insert point

# ------------------ FUNCTIONS ------------------
function Write-Log {
    param($Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

function Get-BatTags {
    param($File)
    $Tags = @{}
    Get-Content $File | ForEach-Object {
        if ($_ -match '^\s*SET\s+([^=]+)=(.*)$') {
            $Tags[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return $Tags
}

# ------------------ USER INPUT ------------------
$OriginalFile = Read-Host "Enter full path to ORIGINAL BAT file"
$BackupFile   = Read-Host "Enter full path to BACKUP BAT file"

if (!(Test-Path $OriginalFile) -or !(Test-Path $BackupFile)) {
    Write-Host "One or both files not found. Exiting." -ForegroundColor Red
    Write-Log "Invalid file path provided"
    exit
}

Write-Log "Original file: $OriginalFile"
Write-Log "Backup file: $BackupFile"

# ------------------ READ TAGS ------------------
$OrigTags = Get-BatTags $OriginalFile
$BackTags = Get-BatTags $BackupFile
$AllTags  = ($OrigTags.Keys + $BackTags.Keys) | Sort-Object -Unique

$ReportData = @()
foreach ($Tag in $AllTags) {
    $InOrig = $OrigTags.ContainsKey($Tag)
    $InBack = $BackTags.ContainsKey($Tag)

    if ($InOrig -and $InBack) {
        $Status = if ($OrigTags[$Tag] -eq $BackTags[$Tag]) { "Matched" } else { "Difference" }
    }
    elseif (-not $InOrig -and $InBack) {
        $Status = "MissingInOriginal"
    }
    else {
        $Status = "MissingInBackup"
    }

    $ReportData += [PSCustomObject]@{
        TagName    = $Tag
        OrigValue  = if ($InOrig) { $OrigTags[$Tag] } else { "" }
        BackValue  = if ($InBack) { $BackTags[$Tag] } else { "" }
        Status     = $Status
        InOriginal = $InOrig
        InBackup   = $InBack
    }

    Write-Log "Tag [$Tag] status: $Status"
}

# ------------------ GENERATE HTML REPORT ------------------
$Html = @"
<html>
<head>
<style>
body { font-family: Segoe UI; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 6px; }
.Matched { background-color: #e2efda; }
.Difference { background-color: #fff2cc; }
.MissingInOriginal { background-color: #ddebf7; }
.MissingInBackup { background-color: #f4cccc; }
</style>
</head>
<body>
<h2>BAT File Comparison Report</h2>
<p>Generated on: $(Get-Date)</p>
<table>
<tr>
<th>Tag</th><th>Original</th><th>Backup</th><th>Status</th>
</tr>
"@

foreach ($R in $ReportData) {
    $Html += "<tr class='$($R.Status)'><td>$($R.TagName)</td><td>$($R.OrigValue)</td><td>$($R.BackValue)</td><td>$($R.Status)</td></tr>"
}

$Html += "</table></body></html>"
Set-Content $HtmlFile $Html -Encoding UTF8
Start-Process $HtmlFile
Write-Log "HTML report opened: $HtmlFile"

# ------------------ SELECT TAGS TO UPDATE/ADD ------------------
$Candidates = $ReportData | Where-Object { $_.Status -in @("Difference", "MissingInOriginal") }

if (!$Candidates) {
    Write-Log "No tags to update/add"
    Write-Host "No updates required. Script finished."
    exit
}

$Choice = Read-Host "Apply ALL updates/additions? (Y/N)"
if ($Choice -match '^[Yy]') {
    $ToUpdate = $Candidates
    Write-Log "User selected ALL eligible tags"
} else {
    $ToUpdate = $Candidates | Out-GridView -Title "Select tags to UPDATE/ADD (Ctrl+A selects all)" -PassThru
}

if (!$ToUpdate) {
    Write-Log "No tags selected for update"
    Write-Host "No updates selected. Script finished."
    exit
}

# ------------------ BACKUP ORIGINAL ------------------
$OrigBackup = "$OriginalFile.bak_$TimeStamp"
Copy-Item $OriginalFile $OrigBackup -Force
Write-Log "Original file backup created: $OrigBackup"

# ------------------ APPLY UPDATES ------------------
$Content = Get-Content $OriginalFile
$AddLines = @()

foreach ($Item in $ToUpdate) {

    $TagName  = $Item.TagName
    $NewValue = $Item.BackValue
    $Escaped  = [regex]::Escape($TagName)

    if ($Item.InOriginal) {
        # Update existing tag
        Write-Log "Updating tag [$TagName] to [$NewValue]"
        $Content = $Content | ForEach-Object {
            if ($_ -match "^\s*SET\s+$Escaped\s*=") { "SET $TagName=$NewValue" } else { $_ }
        }
    } else {
        # Add missing tag
        Write-Log "Adding missing tag [$TagName]=$NewValue"
        $AddLines += "SET $TagName=$NewValue"
    }
}

# ------------------ SECTION-BASED INSERT ------------------
if ($AddLines.Count -gt 0 -and $Content -contains $SectionMarker) {
    $Index = $Content.IndexOf($SectionMarker)
    $Content = $Content[0..$Index] + $AddLines + $Content[($Index+1)..($Content.Count-1)]
    Write-Log "Added missing tags under section [$SectionMarker]"
} elseif ($AddLines.Count -gt 0) {
    # Append at end if section not found
    $Content += ""
    $Content += "REM ---- Added from backup ----"
    $Content += $AddLines
    Write-Log "Added missing tags at end of file (section not found)"
}

$Content | Set-Content $OriginalFile -Encoding ASCII
Write-Log "Update/add operation completed successfully"
Write-Host "Updates applied successfully." -ForegroundColor Green

# ------------------ ROLLBACK OPTION ------------------
$RollbackChoice = Read-Host "Do you want to rollback to a previous backup? (Y/N)"
if ($RollbackChoice -match '^[Yy]') {
    $Backups = Get-ChildItem "$OriginalFile.bak_*" | Sort-Object LastWriteTime -Descending
    if ($Backups.Count -eq 0) {
        Write-Host "No backups available"
        Write-Log "Rollback attempted but no backups found"
        exit
    }
    $SelectedBackup = $Backups | Out-GridView -Title "Select backup to restore" -PassThru
    if ($SelectedBackup) {
        Copy-Item $SelectedBackup.FullName $OriginalFile -Force
        Write-Log "Rollback completed using $($SelectedBackup.FullName)"
        Write-Host "Rollback completed successfully"
    }
}

Write-Log "Script finished"
