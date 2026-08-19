#=========================================================
# Application Variable Validation | Developed By : Mahendra Dwivedi
# Date - 3-Aug-2026
#=========================================================

#=========================================================
# Select Environment
#=========================================================
Clear-Host

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "      Application Variable Validation"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Select Environment" -ForegroundColor Yellow
Write-Host "1. POD2 QA"
Write-Host "2. POD2 DEV"
Write-Host "3. POD2 UAT"
Write-Host "4. POD2 PATQA"
Write-Host "5. POD2 PATUAT"
Write-Host "6. POD2 PERF"
Write-Host "7. POD2 PROD"
Write-Host "8. POD4 PROD"
Write-Host "9. POD1 QA"
Write-Host "10. POD1 DEV"
Write-Host "11. POD1 UAT"
Write-Host "12. POD1 PATQA"
Write-Host "13. POD1 PATUAT"
Write-Host "14. POD1 PERF"
Write-Host "15. POD1 PROD"
Write-Host ""

do
{
    $EnvChoice = Read-Host "Enter your choice"

    switch($EnvChoice)
    {
        "1" {
            $EnvironmentName = "POD2-QA"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD2-QA"
            $Valid = $true
        }

        "2" {
            $EnvironmentName = "POD2-DEV"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD2-DEV"
            $Valid = $true
        }

        "3" {
            $EnvironmentName = "POD2-UAT"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD2-UAT"
            $Valid = $true
        }

        "4" {
            $EnvironmentName = "POD2-PATQA"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD2-PATQA"
            $Valid = $true
        }

        "5" {
            $EnvironmentName = "POD2-PATUAT"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD2-PATUAT"
            $Valid = $true
        }

        "6" {
            $EnvironmentName = "POD2-PERF"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD2-PERF"
            $Valid = $true
        }

        "7" {
            $EnvironmentName = "POD2-PROD"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD2-PROD"
            $Valid = $true
        }

        "8" {
            $EnvironmentName = "POD4-PROD"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD4-PROD"
            $Valid = $true
        }

        "9" {
            $EnvironmentName = "POD1-QA"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD1-QA"
            $Valid = $true
        }

        "10" {
            $EnvironmentName = "POD1-DEV"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD1-DEV"
            $Valid = $true
        }

        "11" {
            $EnvironmentName = "POD1-UAT"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD1-UAT"
            $Valid = $true
        }

        "12" {
            $EnvironmentName = "POD1-PATQA"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD1-PATQA"
            $Valid = $true
        }

        "13" {
            $EnvironmentName = "POD1-PATUAT"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD1-PATUAT"
            $Valid = $true
        }

        "14" {
            $EnvironmentName = "POD1-PERF"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD1-PERF"
            $Valid = $true
        }

        "15" {
            $EnvironmentName = "POD1-PROD"
            $ExcelRoot = "D:\CC_Scripts\Powershell_MD\Others\Application-Variable\POD1-PROD"
            $Valid = $true
        }
        default {
            Write-Host "Invalid Selection" -ForegroundColor Red
            $Valid = $false
        }
    }

} until ($Valid)

Write-Host ""
Write-Host "Selected Environment : $EnvironmentName" -ForegroundColor Green
Write-Host ""

#=========================================================
# Select Blue / Green
#=========================================================

Write-Host ""
Write-Host "Select Region / Stack" -ForegroundColor Yellow
Write-Host "1. EAST BLUE"
Write-Host "2. EAST GREEN"
Write-Host "3. WEST"
Write-Host ""

do
{
    $Choice = Read-Host "Enter your choice"

    switch($Choice)
    {
        "1"
        {
            $Region = "EAST"
            $Stack  = "Blue"
            $Valid  = $true
        }

        "2"
        {
            $Region = "EAST"
            $Stack  = "Green"
            $Valid  = $true
        }

        "3"
        {
            $Region = "WEST"
            $Stack  = ""
            $Valid  = $true
        }

        default
        {
            Write-Host "Invalid Selection" -ForegroundColor Red
            $Valid = $false
        }
    }

} until($Valid)

#=========================================================
# Excel File
#=========================================================

#=========================================================
# Select Validation Type
#=========================================================

Write-Host ""
Write-Host "Select Validation Type" -ForegroundColor Yellow
Write-Host "1. SetupCI.bat"
Write-Host "2. SetupCIPy.ini"
Write-Host "3. SetUp.py"
Write-Host "4. CoreAuthSetup.bat"
Write-Host ""

do
{
    $FileChoice = Read-Host "Enter your choice (1-4)"

    switch($FileChoice)
    {
        "1"
        {
            $ExcelName      = "SetupCI"
            $DestinationFile = "D:\DBBSetup\BatchScripts\CoreIssue\SetupCI.bat"
            $Valid = $true
        }

        "2"
        {
            $ExcelName      = "SetupCIPy"
            $DestinationFile = "D:\DBBSetup\BatchScripts\CoreIssue\SetupCIPy.ini"
            $Valid = $true
        }

        "3"
        {
            $ExcelName      = "SetUp"
            $DestinationFile = "D:\DBBSetup\BatchScripts\CoreIssue\SetUp.py"
            $Valid = $true
        }

        "4"
        {
            $ExcelName      = "CoreAuthSetup"
            $DestinationFile = "D:\DBBSetup\BatchScripts\CoreAuth\CoreAuthSetup.bat"
            $Valid = $true
        }

        default
        {
            Write-Host "Invalid Selection." -ForegroundColor Red
            $Valid = $false
        }

    }

} until ($Valid)

#=========================================================
# Build File Paths
#=========================================================

if($Region -eq "WEST")
{
    $CsvFile = Join-Path $ExcelRoot "$EnvironmentName-WEST-$ExcelName.csv"
}
else
{
    $CsvFile = Join-Path $ExcelRoot "$EnvironmentName-EAST-$Stack-$ExcelName.csv"
}

$EnvFolder = $EnvironmentName -replace '^POD\d+-',''
$BatchFile = $DestinationFile

Write-Host ""
Write-Host "Environment : $EnvironmentName  (Env Folder: $EnvFolder)"
Write-Host "Stack       : $Stack"
Write-Host "Region      : $Region"
Write-Host "CSV File    : $CsvFile"
Write-Host "Batch File  : $BatchFile"
Write-Host ""

$ReportFolder = "C:\Temp"

if (!(Test-Path $ReportFolder))
{
    New-Item -ItemType Directory -Path $ReportFolder | Out-Null
}

$Date = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path $ReportFolder "ApplicationVariableReport_$Date.html"

#---------------------------------------------------------
# Read Excel
#---------------------------------------------------------

#=========================================================
# Read CSV
#=========================================================

try
{
    $ExcelData = Import-Csv $CsvFile -Encoding UTF8
}
catch
{
    Write-Host "Unable to read CSV: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

if($ExcelData.Count -eq 0)
{
    Write-Host "CSV file is empty." -ForegroundColor Red
    exit
}

$Columns = $ExcelData[0].PSObject.Properties.Name

Write-Host "CSV Columns Found:"
$Columns | ForEach-Object { Write-Host " - $_" }

$VariableColumn = $Columns[0]
$ValueColumn    = $Columns[1]

Write-Host "Loaded $($ExcelData.Count) variable(s) from CSV." -ForegroundColor Cyan

#---------------------------------------------------------
# Read Batch / INI File
#---------------------------------------------------------

if (!(Test-Path $BatchFile))
{
    Write-Host "Batch/INI file not found: $BatchFile" -ForegroundColor Red
    exit
}

$BatchVariables = @{}

foreach($Line in Get-Content $BatchFile)
{
    $Line = $Line.Trim()

    if([string]::IsNullOrWhiteSpace($Line)){ continue }

    # Skip comments (ini/bat style: ; # REM @REM) - case-insensitive,
    # since -match is case-insensitive by default in PowerShell
    if($Line.StartsWith(";") -or
       $Line.StartsWith("#") -or
       $Line -match '^@?REM(\s|$)')
    {
        continue
    }

    # Skip INI sections
    if($Line.StartsWith("["))
    {
        continue
    }

    # Remove SET / @SET for BAT files
    if($Line -match '^\s*@?SET\s+(.+)$')
    {
        $Line = $matches[1]
    }

    # Handle the common batch pattern: SET "VarName=Value"
    # (quotes wrap the whole assignment, not just the value)
    if($Line -match '^"(.*)"$')
    {
        $Line = $matches[1]
    }

    if($Line -match '^\s*([^=]+?)\s*=\s*(.*)$')
    {
        $Name  = $matches[1].Trim() -replace '[^A-Za-z0-9_]',''
        $Name  = $Name.ToUpper()
        $Value = $matches[2].Trim()

        # Remove surrounding quotes on the value itself
        $Value = $Value.Trim('"').Trim("'")

        $BatchVariables[$Name] = $Value
    }
}

Write-Host "Loaded $($BatchVariables.Count) variable(s) from batch/ini file." -ForegroundColor Cyan

#---------------------------------------------------------
# Compare
#---------------------------------------------------------

$ServerName = $env:COMPUTERNAME

$Results = foreach($Item in $ExcelData)
{
    $DisplayVariable = "$($Item.$VariableColumn)".Trim()
    $ExpectedValue    = "$($Item.$ValueColumn)".Trim()

    # Strip "SET"/"@SET" prefix (allowing zero-or-more spaces after it),
    # remove any stray/non-breaking/odd characters, then drop a trailing '='
    $LookupVariable = $DisplayVariable `
        -replace '^\s*@?SET\s*','' `
        -replace '[^A-Za-z0-9_]','' `
        -replace '\s*=$',''

    $LookupVariable = $LookupVariable.Trim().ToUpper()

    if($BatchVariables.ContainsKey($LookupVariable))
    {
        $ActualValue = $BatchVariables[$LookupVariable].Trim()

        if($ActualValue.Trim('"') -ieq $ExpectedValue.Trim('"'))
        {
            $Status = "PASSED"
        }
        else
        {
            $Status = "FAILED"
        }
    }
    else
    {
        $ActualValue = ""
        $Status = "MISSING"
    }

    [PSCustomObject]@{
        "Server Name"    = $ServerName
        "Variable Name"  = $DisplayVariable
        "Expected Value" = $ExpectedValue
        "Actual Value"   = $ActualValue
        "Status"         = $Status
    }
}


#---------------------------------------------------------
# HTML Report
#---------------------------------------------------------

$Style = @"
<style>

body{
font-family:Segoe UI;
font-size:12px;
}

table{
border-collapse:collapse;
width:100%;
}

th{
background:#2F75B5;
color:white;
padding:6px;
border:1px solid black;
}

td{
padding:5px;
border:1px solid black;
}

.PASSED{
background:#C6EFCE;
}

.FAILED{
background:#FFC7CE;
}

.MISSING{
background:#FFD966;
}

</style>
"@

$html = @()

$html += "<html>"
$html += "<head>$Style</head>"
$html += "<body>"

$html += "<h2>Application Variable Validation Report</h2>"
$html += "<b>Server :</b> $ServerName<br>"
$html += "<b>Date :</b> $(Get-Date)<br><br>"

$html += "<table>"
$html += "<tr>"
$html += "<th>Server Name</th>"
$html += "<th>Variable Name</th>"
$html += "<th>Expected Value</th>"
$html += "<th>Actual Value</th>"
$html += "<th>Status</th>"
$html += "</tr>"

foreach($r in $Results)
{
    $html += "<tr>"
    $html += "<td>$($r.'Server Name')</td>"
    $html += "<td>$($r.'Variable Name')</td>"
    $html += "<td>$($r.'Expected Value')</td>"
    $html += "<td>$($r.'Actual Value')</td>"
    $html += "<td class='$($r.Status)'>$($r.Status)</td>"
    $html += "</tr>"
}

$html += "</table>"

$Passed  = ($Results | Where-Object { $_.Status -eq "PASSED" }).Count
$Failed  = ($Results | Where-Object { $_.Status -eq "FAILED" }).Count
$Missing = ($Results | Where-Object { $_.Status -eq "MISSING" }).Count

$html += "<br>"
$html += "<h3>Summary</h3>"
$html += "<table style='width:300px'>"
$html += "<tr><td>Passed</td><td>$Passed</td></tr>"
$html += "<tr><td>Failed</td><td>$Failed</td></tr>"
$html += "<tr><td>Missing</td><td>$Missing</td></tr>"
$html += "<tr><td>Total</td><td>$($Results.Count)</td></tr>"
$html += "</table>"

$html += "</body></html>"

$html | Out-File $ReportFile -Encoding UTF8

Invoke-Item $ReportFile

Write-Host ""
Write-Host "Report Generated:"
Write-Host $ReportFile -ForegroundColor Green
