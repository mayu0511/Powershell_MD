$SourceFolder = "D:\Backup\Setup\Documents\Documents\Bill-Petrol_Telephone\26-27"

$Word = New-Object -ComObject Word.Application
$Word.Visible = $false

Get-ChildItem $SourceFolder -Filter *.docx | ForEach-Object {

    $PdfFile = [System.IO.Path]::ChangeExtension($_.FullName, ".pdf")

    $Doc = $Word.Documents.Open($_.FullName)
    $Doc.SaveAs([ref]$PdfFile, [ref]17)
    $Doc.Close()
    
    Write-Host "Converted: $($_.Name)"
}

$Word.Quit()