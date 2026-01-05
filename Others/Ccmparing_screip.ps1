
$S3FilePath = "D:\DBBSetup\Dump\MasterCard\IPMSettlement\Incoming\Backup\Testing\S3.txt"
$outFilePath = "D:\DBBSetup\Dump\MasterCard\IPMSettlement\Incoming\Backup\Testing\Out.txt"

# Read the content of the text files
$S3FileContent = Get-Content $S3FilePath
$outFileContent = Get-Content $outFilePath

# Convert file names to lowercase for case-insensitive comparison
$S3FileContent = $S3FileContent.ToLower()
$outFileContent = $outFileContent.ToLower()

# Check if each file name from out.txt is present in S3.txt
$missingFiles = Compare-Object -ReferenceObject $outFileContent -DifferenceObject $S3FileContent -ExcludeDifferent

# Output the missing file names
if ($missingFiles.Count -gt 0) {
    Write-Output "The following files from out.txt are not present in S3.txt:"
    foreach ($file in $missingFiles) {
        Write-Output $file.InputObject
    }
} else {
    Write-Output "All files from out.txt are present in S3.txt"
}
