######################################################################################################################
# RMP  Package Verification  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 04-April-2025
# Version 4.5 | Updated for the CoreOps | Netra Chettri | Date:: 10 April 2026
# Version 4.7 | Updated the PODID and Environment Name to remove the manaul location update | Netra Chettri | Date:: 5 May 2026
#=====================================================================================================================

    Clear-Host

    Write-Host "Forcefully closing all SMB sessions and open files..." -ForegroundColor Red

# --- Close all open files ---
    Get-SmbOpenFile | ForEach-Object {
    try {
        Close-SmbOpenFile -FileId $_.FileId -Force
        Write-Host "Closed file: $($_.Path)" -ForegroundColor Green
    } catch {
        Write-Host "Error closing file $($_.Path): $_" -ForegroundColor Yellow
    }
    }

# --- Close all SMB sessions ---
    Get-SmbSession | ForEach-Object {
    try {
        Close-SmbSession -SessionId $_.SessionId -Force
        Write-Host "Closed session: $($_.ClientUserName) from $($_.ClientComputerName)" -ForegroundColor Green
    } catch {
        Write-Host "Error closing session from $($_.ClientComputerName): $_" -ForegroundColor Yellow
    }
    }

    Write-Host "All SMB sessions and open files have been closed." -ForegroundColor Cyan

#------------Clear All Variable------

    Get-Variable | Where-Object {
    ($_.Options -band [System.Management.Automation.ScopedItemOptions]::Constant) -eq 0 -and
    $_.Name -notmatch '^PS(|Item|Cmd|Script|Version|Home|ISE|Console|Prompt)'
    } | ForEach-Object {
    Remove-Variable -Name $_.Name -Force -ErrorAction SilentlyContinue
    }

    # ------------------ Step 0: Ask for Package Type ------------------

    $packageType = Read-Host "Enter the package type (Full or Patch)"
    $packageType = $packageType.Trim().ToLower()

    # ------------------ Step 1: Common Input ------------------

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$logFile = "C:\Temp\Packagecreation_$timestamp.txt"
	New-Item -ItemType File -Path $logFile -Force | Out-Null
	
	function Log-Step {
	param ([string]$message)
	$logTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	Add-Content -Path $logFile -Value "$logTime - $message"
	}
	
	# ------------------ POD Selection ------------------
	Write-Host "Select POD:" -ForegroundColor Cyan
	Write-Host "1. POD1"
	Write-Host "2. POD2"
	Write-Host "3. POD4"
	
	$podChoice = Read-Host "Enter option number"
	
	switch ($podChoice) {
		"1" { $podName = "POD1" }
		"2" { $podName = "POD2" }
		"3" { $podName = "POD4" }
		default {
			Write-Host "Invalid POD selection!" -ForegroundColor Red
			return
		}
	}
	
	Log-Step "POD selected: $podName"
	# ----------------------------------------------------------------
	
	# Ask user to select environment
	Write-Host "Select Environment:" -ForegroundColor Cyan
	Write-Host "1. GSDEV"
	Write-Host "2. GSOA"
	Write-Host "3. GSUAT"
	Write-Host "4. PATQA"
	Write-Host "5. PATUAT"
	Write-Host "6. PERF"
	Write-Host "7. PROD"
	Write-Host "8. TRAIN"
	
	$envChoice = Read-Host "Enter option number"
	
	# Map selection to folder
	switch ($envChoice) {
		"1" { $envName = "GSDEV" }
		"2" { $envName = "GSOA" }
		"3" { $envName = "GSUAT" }
		"4" { $envName = "PATQA" }
		"5" { $envName = "PATUAT" }
		"6" { $envName = "PERF" }
		"7" { $envName = "PROD" }
		"8" { $envName = "TRAIN" }
		default {
			Write-Host "Invalid selection!" -ForegroundColor Red
			exit
		}
    }
	
	# Build dynamic package directory
	$packagedir = "D:\Packages\COOKIE\$podName\$envName\"
	
	# Continue existing logic
	$packagename = Read-Host "Step 1: Enter the RMP Package Name to zip"
	$sourceFolder = Join-Path $packagedir $packagename
	$destinationZip = Join-Path $packagedir "${packagename}_RMP.zip"
	
	Log-Step "Environment selected: $envName"
	Log-Step "Package name entered: $packagename"
	
	if ($packageType -eq 'full') {
		Write-Host "\FULL Package Selected. Executing all steps..." -ForegroundColor Cyan
	

    # ------------ Step 2: Always Delete FileSplitterUtility and IncomingOutgoingUtilities ---------------

$deleteConfirm = Read-Host "Step 2: Do you want to delete 'FileSplitterUtility' and 'IncomingOutgoingUtilities' folders? (Y/N)"

if ($deleteConfirm -match '^[Yy]$') {
    $foldersToDelete = @(
        Join-Path $sourceFolder "Consolidated_Package\FileSplitterUtility"
        Join-Path $sourceFolder "Consolidated_Package\IncomingOutgoingUtilities"
    )

    foreach ($folder in $foldersToDelete) {
        if (Test-Path $folder) {
            try {
                Remove-Item -Path $folder -Recurse -Force
                Write-Host "Deleted folder: $folder" -ForegroundColor Yellow
                Log-Step "Deleted folder: $folder"
            } catch {
                Write-Host "Failed to delete folder: $folder - $($_.Exception.Message)" -ForegroundColor Red
                Log-Step "Failed to delete folder: $folder - $($_.Exception.Message)"
            }
        } else {
            Write-Host "Folder not found: $folder" -ForegroundColor DarkYellow
            Log-Step "Folder not found: $folder"
        }
    }
} else {
    Write-Host "Skipping folder deletion..." -ForegroundColor Yellow
    Log-Step "Skipped folder deletion"
}

  # ------------------ Step 3: Confirm Zipping (With Root Folder) ------------------

function Compress-With7Zip {
    param (
        [string]$sourceFolder,
        [string]$destinationZip
    )

    $sevenZip = "C:\Program Files\7-Zip\7z.exe"

    if (-not (Test-Path $sevenZip)) {
        Write-Host "7-Zip not found at: $sevenZip" -ForegroundColor Red
        Log-Step "7-Zip not found at: $sevenZip"
        return
    }

    # Extract the parent folder and the folder name
    $parent = Split-Path $sourceFolder -Parent
    $folderName = Split-Path $sourceFolder -Leaf

    # ✅ Include the root folder (by zipping the folder name from its parent)
    $arguments = "a -tzip `"$destinationZip`" `"$folderName`" -r -mx=1 -mmt=on"

    try {
        Push-Location $parent

        $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "`ZIP created (includes root folder): $destinationZip" -ForegroundColor Green
            Log-Step "ZIP created (includes root folder): $destinationZip"
        } else {
            Write-Host "`7-Zip failed with exit code $($process.ExitCode)" -ForegroundColor Red
            Log-Step "7-Zip failed with exit code $($process.ExitCode)"
        }
    } catch {
        Write-Host "`Exception during 7-Zip compression: $($_.Exception.Message)" -ForegroundColor Red
        Log-Step "Exception during 7-Zip compression: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

# Ask user if they want to zip the folder
$zipConfirm = Read-Host "`Step 2: Do you want to ZIP the package now? (Y/N)"

if ($zipConfirm -match '^[Yy]$') {
    if (Test-Path $sourceFolder) {
        if (Test-Path $destinationZip) {
            Remove-Item $destinationZip -Force
            Write-Host "Deleted existing ZIP: $destinationZip" -ForegroundColor Yellow
            Log-Step "Deleted existing ZIP: $destinationZip"
        }

        Compress-With7Zip -sourceFolder $sourceFolder -destinationZip $destinationZip

    } else {
        Write-Host "Source folder not found: $sourceFolder" -ForegroundColor Red
        Log-Step "Source folder not found: $sourceFolder"
    }
} else {
    Write-Host "Skipping ZIP step..." -ForegroundColor Yellow
    Log-Step "Skipped ZIP step"
}
  

# ------------------ Step 4: Check ZIP File Status ------------------

    $zipPath = $destinationZip

    if (Test-Path $zipPath) {
    $fileInfo = Get-Item $zipPath
    if ($fileInfo.Length -gt 0) {
        Write-Host "`ZIP file created successfully: $zipPath" -ForegroundColor Green
        Log-Step "ZIP file size: $($fileInfo.Length) bytes"
    } else {
        Write-Host "`ZIP file is empty: $zipPath" -ForegroundColor Yellow
        Log-Step "ZIP file is empty"
    }
    } else {
    Write-Host "`ZIP file not found: $zipPath" -ForegroundColor Yellow
    Log-Step "ZIP file not found after skipping/attempt"
    }

# ------------------ Step 5: Validate ZIP File ------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
    Write-Host "`ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed"
    } catch {
    Write-Host "`ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }

# ------------------ Step 6: List ZIP Contents ------------------

    try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    Write-Host "`Contents of the ZIP archive:" -ForegroundColor Cyan

    foreach ($entry in $zip.Entries) {
        Write-Host " - $($entry.FullName)"
    }

    Write-Host "`Total Entries: $($zip.Entries.Count)" -ForegroundColor Cyan
    Log-Step "ZIP entries listed: $($zip.Entries.Count)"
    $zip.Dispose()
    } catch {
    Write-Host "Failed to read ZIP contents: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Error reading ZIP: $($_.Exception.Message)"
    }

    
    # ------------------ Step 3: Ensure subfolders inside DataBasePackage_KMS and DataBasePackage_PlatForm ------------------

    $confirmEnsureSubfolders = Read-Host "Step 3: Ensure subfolders inside DataBasePackage_KMS,DataBasePackage_PlatForm,CoreOPS,DataBasePackage_CoreOps and PostgreSQL_CoreOps ? (Y/N)"

    if ($confirmEnsureSubfolders -match '^[Yy]$') {
    $subFoldersToCheck = @(
    "Consolidated_Package\DataBasePackage_KMS",
    "Consolidated_Package\DataBasePackage_PlatForm",
    "Consolidated_Package\CoreOPS",
    "Consolidated_Package\DataBasePackage_CoreOps"
    "Consolidated_Package\PostgreSQL_CoreOps"
    )

    foreach ($relativePath in $subFoldersToCheck) {
    $fullPath = Join-Path $sourceFolder $relativePath
    if (Test-Path $fullPath) {
    $contents = Get-ChildItem -Path $fullPath -Force
    if ($contents.Count -eq 0) {
    Write-Host "`Folder '$relativePath' is empty." -ForegroundColor Yellow
    $confirmCreate = Read-Host "Do you want to create a '1' subfolder inside '$relativePath'? (Y/N)"

    if ($confirmCreate -match '^[Yy]$') {
    $nestedFolder = Join-Path $fullPath "1"
    if (!(Test-Path $nestedFolder)) {
    New-Item -Path $nestedFolder -ItemType Directory | Out-Null
    Write-Host "Created folder: $nestedFolder" -ForegroundColor Cyan
    Log-Step "Created subfolder: $nestedFolder inside empty $relativePath"
    } else {
    Write-Host "Subfolder already exists: $nestedFolder" -ForegroundColor Yellow
    Log-Step "Subfolder already exists: $nestedFolder"
    }
    } else {
    Write-Host "Skipped creating '1' folder inside: $relativePath" -ForegroundColor Yellow
    Log-Step "User skipped creating '1' in: $relativePath"
    }
    } else {
    Write-Host "$relativePath already contains files or folders. No need to create '1'." -ForegroundColor Green
    Log-Step "Skipped creation: $relativePath is not empty"
    }
    } else {
    Write-Host "Folder does not exist: $relativePath" -ForegroundColor Red
    Log-Step "Skipped: $relativePath not found"
    }
    }
    } else {
    Write-Host "Skipped Step 3 - Ensuring subfolders in KMS/Platform folders." -ForegroundColor Yellow
    Log-Step "User skipped Step 3 - Ensuring subfolders in KMS/Platform folders"
    }

    # ------------------ Step 4: Confirm Deletion of Unwanted Items ------------------

    $proceedDelete = Read-Host "Step 4: Do you want to delete unwanted files/folders from the package? (Y/N)"
    if ($proceedDelete -notmatch '^[Yy]$') {
    Write-Host "Skipping deletion step..."
    Log-Step "Skipped deletion step"
    } else {
    $deletedItems = @()
    $deleteList = @(
        "\Consolidated_Package\Delta_Changes",
        "\Consolidated_Package\FileSplitterUtility",
        "\Consolidated_Package\IncomingOutgoingUtilities",
        "\Consolidated_Package\Scale_Startup",
        "\Consolidated_Package\WCFServer\CoreCardServices\connectionStrings_Master.config",
        "\Consolidated_Package\WCFServer\CoreCardServices\Web_Master.config",
        "\Consolidated_Package\WCFServer\CoreCardServices\Web_WithValue.config",
        "\Consolidated_Package\WCFServer\CoreCardServices\Log",
        "\Consolidated_Package\WCFServer\WCF\Log",
        "\Consolidated_Package\WCFServer\WCF\Web_Master.config",
        "\Consolidated_Package\WCFServer\WCF\Web_WithValue.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\appSettings_Master.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\appSettings_WithValue.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\connectionStrings_Master.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\connectionStrings_WithValue.config",
        "\Consolidated_Package\WebServer\DBBWEB\Web_Master.config",
        "\Consolidated_Package\WebServer\Services\Web_Master.config",
        "\Consolidated_Package\WebServer\Services\CoreCardServicesGateway\Web_delta.config",
        "\Consolidated_Package\WebServer\Services\CoreCardServicesGateway\Web_Master.config",
        "\Consolidated_Package\WebServer\Services\CoreCardServicesGateway\Web_WithValue.config",
        "\Consolidated_Package\WebServer\CoreCredit\Web_Master.config",
        "\Consolidated_Package\WebServer\CoreCredit\Web_WithValue.config",
        "\Consolidated_Package\WebServer\CoreCredit\Log",
        "\Consolidated_Package\CoreCredit\Web_WithValue.config",
        "\Consolidated_Package\CoreCredit\Log",
        "\Consolidated_Package\WebServer\ScaleService",
        "\Consolidated_Package\BatchScripts\CoreAuth\Log",
        "\Consolidated_Package\BatchScripts\CoreAuth\CoreAuthSetup_Full.bat",
        "\Consolidated_Package\BatchScripts\CoreIssue\Log",
        "\Consolidated_Package\BatchScripts\CoreIssue\OrigionalFileBackup",
        "\Consolidated_Package\BatchScripts\CoreIssue\SetupCI_Full.bat",
        "\Consolidated_Package\BatchScripts\CoreIssue\SetupCIPy_Full.ini",
        "\Consolidated_Package\ReportDelivery\ReportDelivery\PDF_Kafka",
        "\Package\PlaceHolderFiles.zip",
        "\Package\PlaceHolderXlsFiles.zip",
        "\Package\ReleaseItem.zip",
        "\Package\KMS.zip",
        "\Package\CoreOPS.zip",
        "\Package\DataBasePackage_CoreOps.zip",
        "\Package\PostgreSQL_CoreOps.zip",
        "\Consolidated_Package_Delta_Merge.txt",
        "\Consolidated_Package\TraceFiles\CoreIssue\Log",
        "\Consolidated_Package\TraceFiles\CoreIssue\OrigionalFileBackup",
        "\Consolidated_Package\TraceFiles\CoreAuth\Log",
        "\Consolidated_Package\TraceFiles\CoreAuth\OrigionalFileBackup",
        "\Consolidated_Package\CoreCredit\Web_Master.config",
        "\Consolidated_Package\CoreCredit\Web_delta.config"
    )

    Write-Host "Deleting unwanted files/folders (confirmation required for each)..."
    Log-Step "Started deleting unwanted files"

    foreach ($relativePath in $deleteList) {
    $fullPath = Join-Path $sourceFolder $relativePath.TrimStart('\')
    if (Test-Path $fullPath) {
    $confirmDel = Read-Host "`Do you want to delete:$fullPath(Y/N)"
    if ($confirmDel -match '^[Yy]$') {
    try {
    if ((Get-Item $fullPath).PSIsContainer) {
    Remove-Item -Path $fullPath -Recurse -Force
    } else {
    Remove-Item -Path $fullPath -Force
    }
    Write-Host "Deleted: $fullPath"
    Log-Step "Deleted: $fullPath"
    $deletedItems += $fullPath
    } catch {
    Write-Host "Failed to delete: $fullPath - $_"
    Log-Step "Failed to delete: $fullPath - $_"
    }
    } else {
    Write-Host "Skipped: $fullPath"
    Log-Step "Skipped deletion: $fullPath"
    }
    } else {
    Write-Host "Not found: $fullPath"
    Log-Step "Not found: $fullPath"
    }
    }

    if ($deletedItems.Count -gt 0) {
        Log-Step "Total items deleted: $($deletedItems.Count)"
    } else {
        Log-Step "No items were deleted."
    }
    }

    

    # ------------------ Step 5: Zip each subfolder in Consolidated_Package ------------------

    $confirmZipEach = Read-Host "Step 5: Do you want to ZIP each folder inside 'Consolidated_Package' to 'Package'? (Y/N)"
    if ($confirmZipEach -match '^[Yy]$') {
    $consolidatedPath = Join-Path $sourceFolder "Consolidated_Package"
    $packagePath      = Join-Path $sourceFolder "Package"

    if (!(Test-Path $packagePath)) {
    New-Item -ItemType Directory -Path $packagePath | Out-Null
    Log-Step "Created folder: $packagePath"
    }

    if (Test-Path $consolidatedPath) {
    $folderCount = (Get-ChildItem -Path $consolidatedPath -Directory).Count
    $originalFileCount = (Get-ChildItem -Path $consolidatedPath -Recurse -File).Count

    Write-Host "`Consolidated_Package contains $folderCount folders and $originalFileCount files." -ForegroundColor Cyan
    Log-Step "Consolidated_Package contains $folderCount folders and $originalFileCount files"

    $zippedFilesTotal = 0
    $zipCount = 0

    Get-ChildItem -Path $consolidatedPath -Directory | ForEach-Object {
    $folderName = $_.Name
    $folderPath = $_.FullName
    $zipFile    = Join-Path $packagePath "$folderName.zip"

    try {
    Compress-Archive -Path $folderPath -DestinationPath $zipFile -Force
    Write-Host "Zipped: $folderName => $zipFile" -ForegroundColor Green
    Log-Step "Zipped: $folderPath => $zipFile"
    $zipCount++

    # ----------------Count files in this folder---------------------------------------

    $folderFiles = (Get-ChildItem -Path $folderPath -Recurse -File).Count
    $zippedFilesTotal += $folderFiles

    #----------- ---Validate ZIP--------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
    Write-Host "ZIP is valid: $zipFile" -ForegroundColor Green
    Log-Step "ZIP validated: $zipFile"
    } catch {
    Write-Host "ZIP invalid: $zipFile - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ZIP validation failed: $zipFile - $($_.Exception.Message)"
    }
    } catch {
                Write-Host "Failed to zip: $folderPath - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ERROR: Failed to zip $folderPath - $($_.Exception.Message)"
    }
    }

    $totalZipFiles = (Get-ChildItem -Path $packagePath -Filter *.zip).Count
    $actualZippedFileCount = (Get-ChildItem -Path $packagePath -Recurse -File).Count

    Write-Host "`Package folder contains $totalZipFiles zip files and $actualZippedFileCount total files." -ForegroundColor Cyan
    Write-Host "Total original files zipped from Consolidated_Package: $zippedFilesTotal" -ForegroundColor Cyan

    Log-Step "Package zip count: $totalZipFiles, total zipped files: $zippedFilesTotal"
    Log-Step "All subfolders zipped from Consolidated_Package"
    } else {
    Write-Host "Consolidated_Package folder not found: $consolidatedPath" -ForegroundColor Red
    Log-Step "ERROR: Consolidated_Package folder not found: $consolidatedPath"
    }
    } else {
    Write-Host "Skipped Step 5 - Zipping each subfolder." -ForegroundColor Yellow
    Log-Step "User skipped Step 5"
    }

    # ------------------ Step 6: Validate Items in Package ------------------

    $confirmValidate = Read-Host "Step 6: Do you want to validate expected items in 'Package'? (Y/N)"
    if ($confirmValidate -match '^[Yy]$') {

    if ($packagedir -match 'JAZZ') {
    $expectedItemsFile = "D:\Packages\IMP\JAZZ_items.txt"
    }
    elseif ($packagedir -match 'COOKIE') {
    $expectedItemsFile = "D:\Packages\IMP\Cookie_items.txt"
    }
    else {
    Write-Host "Could not determine expected items file based on packagedir: $packagedir" -ForegroundColor Red
    Log-Step "Unable to determine expectedItemsFile. Unknown path: $packagedir"
    return
    }

    $package = Join-Path $sourceFolder "Package"

    if (!(Test-Path $expectedItemsFile)) {
    Write-Host "Expected items file not found: $expectedItemsFile" -ForegroundColor Red
    Log-Step "Expected items file not found: $expectedItemsFile"
    }
    elseif (!(Test-Path $package)) {
    Write-Host "Package folder not found: $package" -ForegroundColor Red
    Log-Step "Package folder not found: $package"
    }
    else {
    $expectedItems = Get-Content -Path $expectedItemsFile | Where-Object { $_ -ne '' }

    # ✅ Print all expected items and their count
    Write-Host "Expected items from file: $expectedItemsFile" -ForegroundColor Cyan
    $expectedItems | ForEach-Object { Write-Host "- $_" }
    Write-Host "`Total expected items: $($expectedItems.Count)" -ForegroundColor Green
    Log-Step "Expected items loaded from $expectedItemsFile. Count: $($expectedItems.Count)"

    $receivedFiles = Get-ChildItem -Path $package -File | Select-Object -ExpandProperty Name

    $missingItems = $expectedItems | Where-Object { $_ -notin $receivedFiles }
    $extraItems   = $receivedFiles | Where-Object { $_ -notin $expectedItems }

    if ($missingItems.Count -eq 0) {
    Write-Host "All expected items are present in the package." -ForegroundColor Green
    Log-Step "All expected items are present in 'Package'"
    } else {
    Write-Host "Missing items in the package:" -ForegroundColor Red
    $missingItems | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    Write-Host "Total missing: $($missingItems.Count)" -ForegroundColor Red
    Log-Step "Missing items in 'Package': $($missingItems -join ', ')"
    }

    if ($extraItems.Count -gt 0) {
    Write-Host "Extra files found in the package:" -ForegroundColor Yellow
    $extraItems | ForEach-Object { Write-Host "+ $_" -ForegroundColor Yellow }
    Write-Host "Total extra: $($extraItems.Count)" -ForegroundColor Yellow
    Log-Step "Extra items found in 'Package': $($extraItems -join ', ')"
    } else {
    Log-Step "No extra files found in 'Package'"
    }
    }
    }
    else {
    Write-Host "Skipped item validation step."
    Log-Step "Skipped validation of expected items in 'Package'"
    }

    # ------------------ Step 7: Zip the Package Folder--------------------

    function Compress-With7Zip {
    param (
        [string]$sourceFolder,    # Full path to 'Package'
        [string]$destinationZip,  # Full path to 'Package.zip'
        [int]$compressionLevel = 1
    )

    $sevenZip = "C:\Program Files\7-Zip\7z.exe"
    if (-not (Test-Path $sevenZip)) {
        $sevenZip = "C:\Program Files (x86)\7-Zip\7z.exe"
    }

    if (-not (Test-Path $sevenZip)) {
        Write-Host "7-Zip not found on system." -ForegroundColor Red
        Log-Step "ERROR: 7-Zip not found."
        return
    }

    if (-not (Test-Path $sourceFolder)) {
        Write-Host "Source folder not found: $sourceFolder" -ForegroundColor Red
        Log-Step "ERROR: Source folder not found: $sourceFolder"
        return
    }

    $parentDir  = Split-Path -Path $sourceFolder -Parent
    $folderName = Split-Path -Path $sourceFolder -Leaf

    try {
        Push-Location $parentDir
        Write-Host "Zipping only '$folderName' into '$destinationZip'..." -ForegroundColor Cyan

        # ✅ Pass arguments as an array to avoid quoting problems
        $arguments = @(
            "a",                     # Add to archive
            "-tzip",                 # Format: ZIP
            $destinationZip,         # Destination archive
            $folderName,              # Folder to add
            "-mx=$compressionLevel", # Compression level
            "-mmt=on"                 # Multi-threading
        )

        $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "ZIP created successfully: $destinationZip" -ForegroundColor Green
            Log-Step "ZIP created successfully: $destinationZip"
        } else {
            Write-Host "7-Zip failed with exit code $($process.ExitCode)" -ForegroundColor Red
            Log-Step "7-Zip failed with exit code $($process.ExitCode)"
        }
    } catch {
        Write-Host "Exception during compression: $($_.Exception.Message)" -ForegroundColor Red
        Log-Step "7-Zip compression error: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

# ------------------ Prompt and run Step 8 ------------------

    $confirmZipFinal = Read-Host "Step 8: Do you want to ZIP the final 'Package' folder into 'Package.zip'? (Y/N)"

    if ($confirmZipFinal -match '^[Yy]$') {
    $packageFolder = Join-Path $sourceFolder "Package"
    $zipFile = Join-Path $sourceFolder "Package.zip"

    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
        Write-Host "Deleted existing Package.zip..." -ForegroundColor Yellow
        Log-Step "Deleted existing Package.zip before creating new archive."
    }

    Compress-With7Zip -sourceFolder $packageFolder -destinationZip $zipFile -compressionLevel 1

    # Validate ZIP
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
        Write-Host "ZIP file is valid and can be opened." -ForegroundColor Green
        Log-Step "ZIP validation passed for: $zipFile"
    } catch {
        Write-Host "ZIP file is corrupted or unreadable." -ForegroundColor Red
        Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
    } else {
    Write-Host "Skipped zipping the final Package folder." -ForegroundColor Yellow
    Log-Step "Skipped zipping final Package folder"
    }


    # ------------------ Step 9: Force Delete 'Consolidated_Package' and 'Package' folders ------------------

$confirmDeleteFolders = Read-Host "Step 9: Do you want to delete both 'Consolidated_Package' and 'Package' folders? (Y/N)"

if ($confirmDeleteFolders -match '^[Yy]$') {

    if (-not (Test-Path $sourceFolder)) {
        Write-Host "Source folder does not exist: $sourceFolder" -ForegroundColor Red
        Log-Step "Source folder missing: $sourceFolder"
        return
    }

    $foldersToDelete = @("Consolidated_Package", "Package")

    foreach ($folder in $foldersToDelete) {
        $fullPath = Join-Path $sourceFolder $folder
        if (Test-Path $fullPath) {
            try {
                # Use long path prefix to bypass MAX_PATH
                $longPath = "\\?\" + $fullPath
                Remove-Item -Path $longPath -Recurse -Force -ErrorAction Stop

                Write-Host "Deleted: $fullPath" -ForegroundColor Green
                Log-Step "Deleted folder: $fullPath"

            } catch {
                Write-Host "Failed to delete $fullPath - $($_.Exception.Message)" -ForegroundColor Red
                Log-Step "Failed to delete $fullPath - $($_.Exception.Message)"
            }
        } else {
            Write-Host "Not found (already deleted or missing): $fullPath" -ForegroundColor Yellow
            Log-Step "Folder not found or already deleted: $fullPath"
        }
    }

} else {
    Write-Host "Skipped folder deletion." -ForegroundColor Yellow
    Log-Step "Skipped deletion of folders"
}

        
    # ------------------ Step 10: List All Files and Folders in Package Root ------------------

    $confirmFinalCheck = Read-Host "Step 10: Do you want to List All Files and Folders in Package Root? (Y/N)"

    if ($confirmFinalCheck -match '^[Yy]$') {
    Write-Host "Listing all files and folders in the package root folder: $sourceFolder" -ForegroundColor Cyan
    Log-Step "Listing all files and folders in $sourceFolder"

    if (Test-Path $sourceFolder) {
    $allItems = Get-ChildItem -Path $sourceFolder

    if ($allItems.Count -eq 0) {
    Write-Host "No files or folders found in $sourceFolder" -ForegroundColor Yellow
    Log-Step "No files or folders found in $sourceFolder"
    } else {
    foreach ($item in $allItems) {
    $type = if ($item.PSIsContainer) { "Folder" } else { "File" }
    Write-Host "$type`t$item.Name"
    }

    Write-Host "Total Items Found: $($allItems.Count)" -ForegroundColor Cyan
    Log-Step "Total items listed in $sourceFolder $($allItems.Count)"
    }
    } else {
    Write-Host "Source folder not found: $sourceFolder" -ForegroundColor Red
    Log-Step "Source folder not found while listing: $sourceFolder"
    }
    } else {
    Write-Host "Skipped listing of files and folders in package root folder."
    Log-Step "Skipped listing of items in $sourceFolder"
    }

    # ------------------ Step 11: Checksum Generation ------------------

    $confirmChecksum = Read-Host "Step 11: Do you want to generate checksum of Package.zip? (Y/N)"

    if ($confirmChecksum -match '^[Yy]$') {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $zipFile = Join-Path $sourceFolder "Package.zip"
    $hashOutputFile = Join-Path $sourceFolder "CCpackage_hash_$timestamp.txt"

    Write-Host "Task 1 Started - Generating SHA256 hash of Package.zip (CoreCard Package)" -ForegroundColor Green
    Write-Host "Target path      : $sourceFolder"
    Write-Host "Output hash file : $hashOutputFile"

    if (Test-Path $zipFile) {
    Write-Host "Package.zip found at: $zipFile" -ForegroundColor Cyan
    try {
    Write-Host "Computing SHA256 hash..."
    $hash = Get-FileHash -Path $zipFile -Algorithm SHA256
    $hash.Hash | Out-File -FilePath $hashOutputFile -Encoding utf8

    Write-Host "SHA256 hash saved to file: $hashOutputFile" -ForegroundColor Green
    Write-Host "Hash value: $($hash.Hash)" -ForegroundColor Yellow
    Log-Step "Checksum generated and saved to $hashOutputFile"
    } catch {
    Write-Host "ERROR: Failed to compute hash. Exception: $_" -ForegroundColor Red
    Log-Step "Failed to generate hash: $_"
    }
    } else {
    Write-Host "ERROR: Package.zip not found in path: $sourceFolder" -ForegroundColor Red
    Log-Step "Package.zip not found in $sourceFolder"
    }
    } else {
    Write-Host "Skipped checksum generation." -ForegroundColor Yellow
    Log-Step "User skipped checksum generation."
    }

# ------------------ Step 12: Zip the Main Package Folder (Faster using 7-Zip) ------------------

function Create-FastZipWith7Zip {
    param (
        [string]$SourceFolder,
        [string]$ZipPath
    )

    $sevenZip = "C:\Program Files\7-Zip\7z.exe"

    if (-not (Test-Path $sevenZip)) {
        Write-Host "7-Zip not found at: $sevenZip" -ForegroundColor Red
        Log-Step "7-Zip not found at: $sevenZip"
        return
    }

    # Extract folder info
    $parent = Split-Path $SourceFolder -Parent
    $folderName = Split-Path $SourceFolder -Leaf

    # Build 7-Zip arguments (includes root folder)
    $arguments = "a -tzip `"$ZipPath`" `"$folderName`" -r -mx=1 -mmt=on"

    try {
        Push-Location $parent

        Write-Host "Starting fast ZIP using 7-Zip..." -ForegroundColor Cyan
        Log-Step "Zipping folder with 7-Zip: $SourceFolder"

        $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "ZIP created successfully: $ZipPath" -ForegroundColor Green
            Log-Step "ZIP created successfully using 7-Zip: $ZipPath"
        } else {
            Write-Host "7-Zip failed with exit code $($process.ExitCode)" -ForegroundColor Red
            Log-Step "7-Zip failed with exit code $($process.ExitCode)"
        }
    } catch {
        Write-Host "Exception during ZIP: $($_.Exception.Message)" -ForegroundColor Red
        Log-Step "Exception during 7-Zip: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

# Prompt user to confirm ZIP creation

$confirmManualZip = Read-Host "Step 12: Do you want to ZIP the full '$packagename' folder now? (Y/N)"

if ($confirmManualZip -match '^[Yy]$') {
    $manualSourceFolder = $sourceFolder              # e.g., E:\Packages\JAZZ\UAT2\CP7064_POD3...
    $manualZipFile      = "$manualSourceFolder.zip"  # Output ZIP: E:\Packages\...\CP7064_POD3.zip

    Log-Step "User confirmed to zip the full package folder: $manualSourceFolder"

    if (Test-Path $manualSourceFolder) {
        try {
            if (Test-Path $manualZipFile) {
                Remove-Item $manualZipFile -Force
                Write-Host "Deleted existing ZIP: $manualZipFile" -ForegroundColor Yellow
                Log-Step "Deleted existing ZIP: $manualZipFile"
            }

            # ✅ Use fast 7-Zip method
            Create-FastZipWith7Zip -SourceFolder $manualSourceFolder -ZipPath $manualZipFile
        } catch {
            Write-Host "Failed to zip package folder: $($_.Exception.Message)" -ForegroundColor Red
            Log-Step "ERROR: Failed to zip full folder - $($_.Exception.Message)"
        }
    } else {
        Write-Host "Source folder not found: $manualSourceFolder" -ForegroundColor Red
        Log-Step "ERROR: Source folder not found: $manualSourceFolder"
    }

    # ✅ Validate the ZIP
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($manualZipFile).Dispose()
        Write-Host "ZIP file is valid and can be opened." -ForegroundColor Green
        Log-Step "ZIP validation passed for $manualZipFile"
    } catch {
        Write-Host "ZIP file is corrupted or unreadable." -ForegroundColor Red
        Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "Skipped zipping full package folder." -ForegroundColor Yellow
    Log-Step "User skipped zipping full package folder"
}

Log-Step "FULL Package script completed successfully."

    
    ###==================FUll Done====================###
    
    } elseif ($packageType -eq 'patch') {
    Write-Host "\PATCH Package Selected. Executing all steps except Step 6 (validation)..." -ForegroundColor Cyan

     # ------------ Always Delete FileSplitterUtility and IncomingOutgoingUtilities ---------------

$deleteConfirm = Read-Host "Step 1: Do you want to delete 'FileSplitterUtility' and 'IncomingOutgoingUtilities' folders? (Y/N)"

if ($deleteConfirm -match '^[Yy]$') {
    $foldersToDelete = @(
        Join-Path $sourceFolder "Consolidated_Package\FileSplitterUtility"
        Join-Path $sourceFolder "Consolidated_Package\IncomingOutgoingUtilities"
    )

    foreach ($folder in $foldersToDelete) {
        if (Test-Path $folder) {
            try {
                Remove-Item -Path $folder -Recurse -Force
                Write-Host "Deleted folder: $folder" -ForegroundColor Yellow
                Log-Step "Deleted folder: $folder"
            } catch {
                Write-Host "Failed to delete folder: $folder - $($_.Exception.Message)" -ForegroundColor Red
                Log-Step "Failed to delete folder: $folder - $($_.Exception.Message)"
            }
        } else {
            Write-Host "Folder not found: $folder" -ForegroundColor DarkYellow
            Log-Step "Folder not found: $folder"
        }
    }
} else {
    Write-Host "Skipping folder deletion..." -ForegroundColor Yellow
    Log-Step "Skipped folder deletion"
}

    # ------------------ Step 2: Confirm Zipping ------------------

$zipConfirm = Read-Host "Step 2: Do you want to ZIP the package now? (Y/N)"

if ($zipConfirm -match '^[Yy]$') {
    if (Test-Path $sourceFolder) {
        if (Test-Path $destinationZip) {
            Remove-Item $destinationZip -Force
            Write-Host "Deleted existing ZIP: $destinationZip" -ForegroundColor Yellow
            Log-Step "Deleted existing ZIP: $destinationZip"
        }

        try {
    # ✅ Create ZIP with 7-Zip including the root folder
    $7zipPath = "C:\Program Files\7-Zip\7z.exe"
    if (-not (Test-Path $7zipPath)) {
        throw "7-Zip not found at path: $7zipPath"
    }

    $parentDir = Split-Path $sourceFolder
    $rootFolderName = Split-Path $sourceFolder -Leaf

    $arguments = @("a", "-tzip", "`"$destinationZip`"", "`"$rootFolderName\*`"")

    Push-Location $parentDir
    $process = Start-Process -FilePath $7zipPath -ArgumentList $arguments -NoNewWindow -PassThru -Wait
    Pop-Location

    if ($process.ExitCode -eq 0) {
        Write-Host "Package folder zipped to: $destinationZip" -ForegroundColor Green
        Log-Step "Package folder zipped to: $destinationZip"
    } else {
        throw "7-Zip failed with exit code $($process.ExitCode)"
    }
} catch {
    Write-Host "Failed to create ZIP archive: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Failed to create ZIP: $($_.Exception.Message)"
}
}}


    # ------------------ Step 3: Check ZIP File Status ------------------

    $zipPath = $destinationZip

    if (Test-Path $zipPath) {
    $fileInfo = Get-Item $zipPath
    if ($fileInfo.Length -gt 0) {
    Write-Host "ZIP file created successfully: $zipPath" -ForegroundColor Green
    Log-Step "ZIP file size: $($fileInfo.Length) bytes"
    } else {
    Write-Host "ZIP file is empty: $zipPath" -ForegroundColor Yellow
    Log-Step "ZIP file is empty"
    }
    } else {
    Write-Host "ZIP file not found: $zipPath" -ForegroundColor Yellow
    Log-Step "ZIP file not found after skipping/attempt"
    }

    # ------------------ Step 4: Validate ZIP File ------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
    Write-Host "ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed"
    } catch {
    Write-Host "ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }

    # ------------------ Step 5: List ZIP Contents ------------------

    try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    Write-Host "Contents of the ZIP archive:" -ForegroundColor Cyan

    foreach ($entry in $zip.Entries) {
    Write-Host " - $($entry.FullName)"
    }

    Write-Host "Total Entries: $($zip.Entries.Count)" -ForegroundColor Cyan
    Log-Step "ZIP entries listed: $($zip.Entries.Count)"
    $zip.Dispose()
    } catch {
    Write-Host "Failed to read ZIP contents: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Error reading ZIP: $($_.Exception.Message)"
    }

    # ------------------ Step 3: Ensure subfolders inside DataBasePackage_KMS and DataBasePackage_PlatForm ------------------

    $confirmEnsureSubfolders = Read-Host "`Step 3: Ensure subfolders inside DataBasePackage_KMS and DataBasePackage_PlatForm? (Y/N)"

    if ($confirmEnsureSubfolders -match '^[Yy]$') {
    $subFoldersToCheck = @(
    "Consolidated_Package\DataBasePackage_KMS",
    "Consolidated_Package\DataBasePackage_PlatForm"
    )

    foreach ($relativePath in $subFoldersToCheck) {
    $fullPath = Join-Path $sourceFolder $relativePath

    if (Test-Path $fullPath) {
    $contents = Get-ChildItem -Path $fullPath -Force

    if ($contents.Count -eq 0) {
    Write-Host "Folder '$relativePath' is empty." -ForegroundColor Yellow
    $confirmCreate = Read-Host "Do you want to create a '1' subfolder inside '$relativePath'? (Y/N)"

    if ($confirmCreate -match '^[Yy]$') {
    $nestedFolder = Join-Path $fullPath "1"
    if (!(Test-Path $nestedFolder)) {
    New-Item -Path $nestedFolder -ItemType Directory | Out-Null
    Write-Host "Created folder: $nestedFolder" -ForegroundColor Cyan
    Log-Step "Created subfolder: $nestedFolder inside empty $relativePath"
    } else {
    Write-Host "Subfolder already exists: $nestedFolder" -ForegroundColor Yellow
    Log-Step "Subfolder already exists: $nestedFolder"
    }
    } else {
    Write-Host "Skipped creating '1' folder inside: $relativePath" -ForegroundColor Yellow
    Log-Step "User skipped creating '1' in: $relativePath"
                }
    } else {
    Write-Host "$relativePath already contains files or folders. No need to create '1'." -ForegroundColor Green
    Log-Step "Skipped creation: $relativePath is not empty"
            }
    } else {
    Write-Host "Folder does not exist: $relativePath" -ForegroundColor Red
    Log-Step "Skipped: $relativePath not found"
    }
    }
    } else {
    Write-Host "Skipped Step 3 - Ensuring subfolders in KMS/Platform folders." -ForegroundColor Yellow
    Log-Step "User skipped Step 3 - Ensuring subfolders in KMS/Platform folders"
    }

    # ------------------ Step 4: Confirm Deletion of Unwanted Items ------------------

$proceedDelete = Read-Host "Step 4: Do you want to delete unwanted files/folders from the package? (Y/N)"
if ($proceedDelete -notmatch '^[Yy]$') {
    Write-Host "Skipping deletion step..."
    Log-Step "Skipped deletion step"
} else {
    $deletedItems = @()
    $deleteList = @(
        "\Consolidated_Package\FileSplitterUtility",
        "\Consolidated_Package\IncomingOutgoingUtilities",
        "\Consolidated_Package\Scale_Startup",
        "\Consolidated_Package\WCFServer\CoreCardServices\connectionStrings_Master.config",
        "\Consolidated_Package\WCFServer\CoreCardServices\Web_Master.config",
        "\Consolidated_Package\WCFServer\CoreCardServices\Web_WithValue.config",
        "\Consolidated_Package\WCFServer\CoreCardServices\Log",
        "\Consolidated_Package\WCFServer\CoreCardServices\Web_delta.config",
        "\Consolidated_Package\WCFServer\WCF\Log",
        "\Consolidated_Package\WCFServer\WCF\Web_Master.config",
        "\Consolidated_Package\WCFServer\WCF\Web_WithValue.config",
        "\Consolidated_Package\WCFServer\WCF\Web_delta.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\appSettings_Master.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\appSettings_WithValue.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\connectionStrings_Master.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\connectionStrings_WithValue.config",
        "\Consolidated_Package\WebServer\DBBWEB\Web_Master.config",
        "\Consolidated_Package\WebServer\Services\Web_Master.config",
        "\Consolidated_Package\WebServer\Services\CoreCardServicesGateway\Web_Master.config",
        "\Consolidated_Package\WebServer\Services\CoreCardServicesGateway\Web_WithValue.config",
        "\Consolidated_Package\WebServer\Services\CoreCardServicesGateway\Web_delta.config",
        "\Consolidated_Package\WebServer\CoreCredit\Web_Master.config",
        "\Consolidated_Package\WebServer\CoreCredit\Web_WithValue.config",
        "\Consolidated_Package\WebServer\CoreCredit\Log",
        "\Consolidated_Package\CoreCredit\Web_WithValue.config",
        "\Consolidated_Package\CoreCredit\Log",
        "\Consolidated_Package\WebServer\ScaleService",
        "\Consolidated_Package\BatchScripts\CoreAuth\Log",
        "\Consolidated_Package\BatchScripts\CoreAuth\CoreAuthSetup_Full.bat",
        "\Consolidated_Package\BatchScripts\CoreIssue\Log",
        "\Consolidated_Package\BatchScripts\CoreIssue\OrigionalFileBackup",
        "\Consolidated_Package\BatchScripts\CoreIssue\SetupCI_Full.bat",
        "\Consolidated_Package\BatchScripts\CoreIssue\SetupCIPy_Full.ini",
        "\Consolidated_Package\ReportDelivery\ReportDelivery\PDF_Kafka",
        "\Package\PlaceHolderFiles.zip",
        "\Package\PlaceHolderXlsFiles.zip",
        "\Package\ReleaseItem.zip",
        "\Consolidated_Package_Delta_Merge.txt",
        "\Consolidated_Package\TraceFiles\CoreIssue\Log",
        "\Consolidated_Package\TraceFiles\CoreIssue\OrigionalFileBackup",
        "\Consolidated_Package\TraceFiles\CoreAuth\Log",
        "\Consolidated_Package\TraceFiles\CoreAuth\OrigionalFileBackup",
        "Consolidated_Package\BatchScripts\CoreIssue\SetupCI_Delta.bat",
        "Consolidated_Package\BatchScripts\CoreIssue\SetupCIPy_Delta.ini",
        "Consolidated_Package\WebServer\Services\Web_Delta.config",
        "Consolidated_Package\Delta_Changes\BatchScripts\CoreIssue\SetupCI_Delta.bat",
        "Consolidated_Package\Delta_Changes\BatchScripts\CoreIssue\SetupCIPy_Delta.ini",
        "Consolidated_Package\Delta_Changes\WebServer\Services\Web_Delta.config"
    )

    Write-Host "Deleting unwanted files/folders (confirmation required)..."
    Log-Step "Started deleting unwanted files"

    foreach ($relativePath in $deleteList) {
        $fullPath = Join-Path $sourceFolder $relativePath.TrimStart('\')
        if (Test-Path $fullPath) {
            $item = Get-Item $fullPath
            $isFile = -not $item.PSIsContainer
            $isDelta = $fullPath -like '*_Delta*'

            if ($isFile -and $isDelta) {
                if ($item.Length -eq 0) {
                    $askDelta = Read-Host "_Delta file is 0 KB: $fullPathDo you want to delete it? (Y/N)"
                    if ($askDelta -notmatch '^[Yy]$') {
                        Write-Host "Skipped _Delta 0 KB file: $fullPath"
                        Log-Step "Skipped _Delta 0 KB file: $fullPath"
                        continue
                    }
                } else {
                    Write-Host "_Delta file has size > 0, not deleted: $fullPath"
                    Log-Step "Kept _Delta file with data: $fullPath"
                    continue
                }
            }

            $confirmDel = Read-Host "Do you want to delete:$fullPath(Y/N)"
            if ($confirmDel -match '^[Yy]$') {
                try {
                    if ($item.PSIsContainer) {
                        Remove-Item -Path $fullPath -Recurse -Force
                    } else {
                        Remove-Item -Path $fullPath -Force
                    }
                    Write-Host "Deleted: $fullPath"
                    Log-Step "Deleted: $fullPath"
                    $deletedItems += $fullPath
                } catch {
                    Write-Host "Failed to delete: $fullPath - $_"
                    Log-Step "Failed to delete: $fullPath - $_"
                }
            } else {
                Write-Host "Skipped: $fullPath"
                Log-Step "Skipped deletion: $fullPath"
            }
        } else {
            Write-Host "Not found: $fullPath"
            Log-Step "Not found: $fullPath"
        }
    }

    if ($deletedItems.Count -gt 0) {
        Log-Step "Total items deleted: $($deletedItems.Count)"
    } else {
        Log-Step "No items were deleted."
    }
}

# -------------- Check first-level subfolders of Consolidated_Package and delete if empty ----------------

Write-Host "Checking first-level subfolders of Consolidated_Package..." -ForegroundColor Cyan
$confirmZipEach = Read-Host "Step 5: Do you want to Check Blank Folders and Delete'? (Y/N)"
Log-Step "Checking first-level subfolders of Consolidated_Package"

$consFolder = Join-Path $sourceFolder "Consolidated_Package"

if (Test-Path $consFolder) {
    # Get only immediate subfolders (no recursion)
    $firstLevelFolders = Get-ChildItem -Path $consFolder -Directory

    if ($firstLevelFolders.Count -gt 0) {
        foreach ($folder in $firstLevelFolders) {
            $items = Get-ChildItem -Path $folder.FullName -Force
            if ($items.Count -eq 0) {
                $confirmDel = Read-Host "Folder '$($folder.Name)' is empty. Do you want to delete it? (Y/N)"
                if ($confirmDel -match '^[Yy]$') {
                    try {
                        Remove-Item -Path $folder.FullName -Force
                        Write-Host "Deleted empty folder: $($folder.FullName)" -ForegroundColor Green
                        Log-Step "Deleted empty folder: $($folder.FullName)"
                    } catch {
                        Write-Host "Failed to delete: $($folder.FullName) - $($_.Exception.Message)" -ForegroundColor Red
                        Log-Step "Failed to delete: $($folder.FullName) - $($_.Exception.Message)"
                    }
                } else {
                    Write-Host "Skipped empty folder: $($folder.FullName)" -ForegroundColor Yellow
                    Log-Step "Skipped empty folder: $($folder.FullName)"
                }
            }
        }
    } else {
        Write-Host "No subfolders found in Consolidated_Package." -ForegroundColor Green
        Log-Step "No subfolders in Consolidated_Package"
    }
} else {
    Write-Host "Consolidated_Package not found at: $consFolder" -ForegroundColor Red
    Log-Step "Consolidated_Package folder not found"
}


    # ------------------ Step 6: Zip each subfolder in Consolidated_Package ------------------

    $confirmZipEach = Read-Host "Step 6: Do you want to ZIP each folder inside 'Consolidated_Package' to 'Package'? (Y/N)"
    if ($confirmZipEach -match '^[Yy]$') {
    $consolidatedPath = Join-Path $sourceFolder "Consolidated_Package"
    $packagePath      = Join-Path $sourceFolder "Package"

    if (!(Test-Path $packagePath)) {
    New-Item -ItemType Directory -Path $packagePath | Out-Null
    Log-Step "Created folder: $packagePath"
    }

    if (Test-Path $consolidatedPath) {
    $folderCount = (Get-ChildItem -Path $consolidatedPath -Directory).Count
    $originalFileCount = (Get-ChildItem -Path $consolidatedPath -Recurse -File).Count

    Write-Host "Consolidated_Package contains $folderCount folders and $originalFileCount files." -ForegroundColor Cyan
    Log-Step "Consolidated_Package contains $folderCount folders and $originalFileCount files"

    $zippedFilesTotal = 0
    $zipCount = 0

    Get-ChildItem -Path $consolidatedPath -Directory | ForEach-Object {
    $folderName = $_.Name
    $folderPath = $_.FullName
    $zipFile    = Join-Path $packagePath "$folderName.zip"

    try {
    Compress-Archive -Path $folderPath -DestinationPath $zipFile -Force
    Write-Host "Zipped: $folderName => $zipFile" -ForegroundColor Green
    Log-Step "Zipped: $folderPath => $zipFile"
    $zipCount++

    # Count files in this folder
    $folderFiles = (Get-ChildItem -Path $folderPath -Recurse -File).Count
    $zippedFilesTotal += $folderFiles

    # Validate ZIP
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
    Write-Host "ZIP is valid: $zipFile" -ForegroundColor Green
    Log-Step "ZIP validated: $zipFile"
    } catch {
    Write-Host "ZIP invalid: $zipFile - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ZIP validation failed: $zipFile - $($_.Exception.Message)"
    }
    } catch {
    Write-Host "Failed to zip: $folderPath - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ERROR: Failed to zip $folderPath - $($_.Exception.Message)"
    }
    }

    $totalZipFiles = (Get-ChildItem -Path $packagePath -Filter *.zip).Count
    $actualZippedFileCount = (Get-ChildItem -Path $packagePath -Recurse -File).Count

    Write-Host "Package folder contains $totalZipFiles zip files and $actualZippedFileCount total files." -ForegroundColor Cyan
    Write-Host "Total original files zipped from Consolidated_Package: $zippedFilesTotal" -ForegroundColor Cyan

    Log-Step "Package zip count: $totalZipFiles, total zipped files: $zippedFilesTotal"
    Log-Step "All subfolders zipped from Consolidated_Package"
    } else {
    Write-Host "Consolidated_Package folder not found: $consolidatedPath" -ForegroundColor Red
    Log-Step "ERROR: Consolidated_Package folder not found: $consolidatedPath"
    }
    }

    # ✅ Always log and show Step 6 as skipped (even if Y was selected)
    Write-Host "Skipped Step 7 - Validate Items in Package." -ForegroundColor Yellow
    Log-Step "User skipped Step 7"
    
     # ------------------ Step 8: Zip the Package Folder--------------------

    function Compress-With7Zip {
    param (
        [string]$sourceFolder,    # Full path to 'Package'
        [string]$destinationZip,  # Full path to 'Package.zip'
        [int]$compressionLevel = 1
    )

    $sevenZip = "C:\Program Files\7-Zip\7z.exe"
    if (-not (Test-Path $sevenZip)) {
        $sevenZip = "C:\Program Files (x86)\7-Zip\7z.exe"
    }

    if (-not (Test-Path $sevenZip)) {
        Write-Host "7-Zip not found on system." -ForegroundColor Red
        Log-Step "ERROR: 7-Zip not found."
        return
    }

    if (-not (Test-Path $sourceFolder)) {
        Write-Host "Source folder not found: $sourceFolder" -ForegroundColor Red
        Log-Step "ERROR: Source folder not found: $sourceFolder"
        return
    }

    $parentDir  = Split-Path -Path $sourceFolder -Parent
    $folderName = Split-Path -Path $sourceFolder -Leaf

    try {
        Push-Location $parentDir
        Write-Host "Zipping only '$folderName' into '$destinationZip'..." -ForegroundColor Cyan

        # ✅ Pass arguments as an array to avoid quoting problems
        $arguments = @(
            "a",                     # Add to archive
            "-tzip",                 # Format: ZIP
            $destinationZip,         # Destination archive
            $folderName,              # Folder to add
            "-mx=$compressionLevel", # Compression level
            "-mmt=on"                 # Multi-threading
        )

        $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "ZIP created successfully: $destinationZip" -ForegroundColor Green
            Log-Step "ZIP created successfully: $destinationZip"
        } else {
            Write-Host "7-Zip failed with exit code $($process.ExitCode)" -ForegroundColor Red
            Log-Step "7-Zip failed with exit code $($process.ExitCode)"
        }
    } catch {
        Write-Host "Exception during compression: $($_.Exception.Message)" -ForegroundColor Red
        Log-Step "7-Zip compression error: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

# ------------------ Prompt and run Step 8 ------------------
    $confirmZipFinal = Read-Host "Step 8: Do you want to ZIP the final 'Package' folder into 'Package.zip'? (Y/N)"

    if ($confirmZipFinal -match '^[Yy]$') {
    $packageFolder = Join-Path $sourceFolder "Package"
    $zipFile = Join-Path $sourceFolder "Package.zip"

    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
        Write-Host "Deleted existing Package.zip..." -ForegroundColor Yellow
        Log-Step "Deleted existing Package.zip before creating new archive."
    }

    Compress-With7Zip -sourceFolder $packageFolder -destinationZip $zipFile -compressionLevel 1

    # Validate ZIP
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
        Write-Host "ZIP file is valid and can be opened." -ForegroundColor Green
        Log-Step "ZIP validation passed for: $zipFile"
    } catch {
        Write-Host "ZIP file is corrupted or unreadable." -ForegroundColor Red
        Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
    } else {
    Write-Host "Skipped zipping the final Package folder." -ForegroundColor Yellow
    Log-Step "Skipped zipping final Package folder"
    }


    # ------------------ Step 9: Force Delete 'Consolidated_Package' and 'Package' folders ------------------

$confirmDeleteFolders = Read-Host "Step 9: Do you want to delete both 'Consolidated_Package' and 'Package' folders? (Y/N)"

if ($confirmDeleteFolders -match '^[Yy]$') {

    if (-not (Test-Path $sourceFolder)) {
        Write-Host "Source folder does not exist: $sourceFolder" -ForegroundColor Red
        Log-Step "Source folder missing: $sourceFolder"
        return
    }

    $foldersToDelete = @("Consolidated_Package", "Package")

    foreach ($folder in $foldersToDelete) {
        $fullPath = Join-Path $sourceFolder $folder
        if (Test-Path $fullPath) {
            try {
                # Use long path prefix to bypass MAX_PATH
                $longPath = "\\?\" + $fullPath
                Remove-Item -Path $longPath -Recurse -Force -ErrorAction Stop

                Write-Host "Deleted: $fullPath" -ForegroundColor Green
                Log-Step "Deleted folder: $fullPath"

            } catch {
                Write-Host "Failed to delete $fullPath - $($_.Exception.Message)" -ForegroundColor Red
                Log-Step "Failed to delete $fullPath - $($_.Exception.Message)"
            }
        } else {
            Write-Host "Not found (already deleted or missing): $fullPath" -ForegroundColor Yellow
            Log-Step "Folder not found or already deleted: $fullPath"
        }
    }

} else {
    Write-Host "Skipped folder deletion." -ForegroundColor Yellow
    Log-Step "Skipped deletion of folders"
}

    # ------------------ Step 10: List All Files and Folders in Package Root ------------------

    $confirmFinalCheck = Read-Host "`Step 10: Do you want to List All Files and Folders in Package Root? (Y/N)"

    if ($confirmFinalCheck -match '^[Yy]$') {
    Write-Host "Listing all files and folders in the package root folder: $sourceFolder" -ForegroundColor Cyan
    Log-Step "Listing all files and folders in $sourceFolder"

    if (Test-Path $sourceFolder) {
    $allItems = Get-ChildItem -Path $sourceFolder

    if ($allItems.Count -eq 0) {
    Write-Host "No files or folders found in $sourceFolder" -ForegroundColor Yellow
    Log-Step "No files or folders found in $sourceFolder"
    } else {
    foreach ($item in $allItems) {
    $type = if ($item.PSIsContainer) { "Folder" } else { "File" }
    Write-Host "$type`t$item.Name"
    }

    Write-Host "Total Items Found: $($allItems.Count)" -ForegroundColor Cyan
    Log-Step "Total items listed in $sourceFolder $($allItems.Count)"
    }
    } else {
    Write-Host "Source folder not found: $sourceFolder" -ForegroundColor Red
    Log-Step "Source folder not found while listing: $sourceFolder"
    }
    } else {
    Write-Host "Skipped listing of files and folders in package root folder."
    Log-Step "Skipped listing of items in $sourceFolder"
    }

    # ------------------ Step 11: Checksum Generation ------------------

    $confirmChecksum = Read-Host "Step 11: Do you want to generate checksum of Package.zip? (Y/N)"

    if ($confirmChecksum -match '^[Yy]$') {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # Define correct zip file path and output hash file path
    $zipFile = Join-Path $sourceFolder "Package.zip"
    $hashOutputFile = Join-Path $sourceFolder "CCpackage_hash_$timestamp.txt"

    Write-Host "Task 1 Started - Generating SHA256 hash of Package.zip (CoreCard Package)" -ForegroundColor Green
    Write-Host "Target path      : $sourceFolder"
    Write-Host "Output hash file : $hashOutputFile"

    if (Test-Path $zipFile) {
    Write-Host "Package.zip found at: $zipFile" -ForegroundColor Cyan
    try {
    Write-Host "Computing SHA256 hash..."
    $hash = Get-FileHash -Path $zipFile -Algorithm SHA256
    $hash.Hash | Out-File -FilePath $hashOutputFile -Encoding utf8

    Write-Host "SHA256 hash saved to file: $hashOutputFile" -ForegroundColor Green
    Write-Host "Hash value: $($hash.Hash)" -ForegroundColor Yellow
    Log-Step "Checksum generated and saved to $hashOutputFile"
    } catch {
    Write-Host "ERROR: Failed to compute hash. Exception: $_" -ForegroundColor Red
    Log-Step "Failed to generate hash: $_"
    }
    } else {
    Write-Host "ERROR: Package.zip not found in path: $sourceFolder" -ForegroundColor Red
    Log-Step "Package.zip not found in $sourceFolder"
    }
    } else {
    Write-Host "Skipped checksum generation." -ForegroundColor Yellow
    Log-Step "User skipped checksum generation."
    }

    # ------------------ Step 12: Zip the Main Package Folder (Faster using 7-Zip) ------------------

function Create-FastZipWith7Zip {
    param (
        [string]$SourceFolder,
        [string]$ZipPath
    )

    $sevenZip = "C:\Program Files\7-Zip\7z.exe"

    if (-not (Test-Path $sevenZip)) {
        Write-Host "7-Zip not found at: $sevenZip" -ForegroundColor Red
        Log-Step "7-Zip not found at: $sevenZip"
        return
    }

    # Extract folder info
    $parent = Split-Path $SourceFolder -Parent
    $folderName = Split-Path $SourceFolder -Leaf

    # Build 7-Zip arguments (includes root folder)
    $arguments = "a -tzip `"$ZipPath`" `"$folderName`" -r -mx=1 -mmt=on"

    try {
        Push-Location $parent

        Write-Host "Starting fast ZIP using 7-Zip..." -ForegroundColor Cyan
        Log-Step "Zipping folder with 7-Zip: $SourceFolder"

        $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "ZIP created successfully: $ZipPath" -ForegroundColor Green
            Log-Step "ZIP created successfully using 7-Zip: $ZipPath"
        } else {
            Write-Host "7-Zip failed with exit code $($process.ExitCode)" -ForegroundColor Red
            Log-Step "7-Zip failed with exit code $($process.ExitCode)"
        }
    } catch {
        Write-Host "Exception during ZIP: $($_.Exception.Message)" -ForegroundColor Red
        Log-Step "Exception during 7-Zip: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

# Prompt user to confirm ZIP creation
$confirmManualZip = Read-Host "Step 12: Do you want to ZIP the full '$packagename' folder now? (Y/N)"

if ($confirmManualZip -match '^[Yy]$') {
    $manualSourceFolder = $sourceFolder              # e.g., E:\Packages\JAZZ\UAT2\CP7064_POD3...
    $manualZipFile      = "$manualSourceFolder.zip"  # Output ZIP: E:\Packages\...\CP7064_POD3.zip

    Log-Step "User confirmed to zip the full package folder: $manualSourceFolder"

    if (Test-Path $manualSourceFolder) {
        try {
            if (Test-Path $manualZipFile) {
                Remove-Item $manualZipFile -Force
                Write-Host "Deleted existing ZIP: $manualZipFile" -ForegroundColor Yellow
                Log-Step "Deleted existing ZIP: $manualZipFile"
            }

            # ✅ Use fast 7-Zip method
            Create-FastZipWith7Zip -SourceFolder $manualSourceFolder -ZipPath $manualZipFile
        } catch {
            Write-Host "Failed to zip package folder: $($_.Exception.Message)" -ForegroundColor Red
            Log-Step "ERROR: Failed to zip full folder - $($_.Exception.Message)"
        }
    } else {
        Write-Host "Source folder not found: $manualSourceFolder" -ForegroundColor Red
        Log-Step "ERROR: Source folder not found: $manualSourceFolder"
    }

    # ✅ Validate the ZIP
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($manualZipFile).Dispose()
        Write-Host "ZIP file is valid and can be opened." -ForegroundColor Green
        Log-Step "ZIP validation passed for $manualZipFile"
    } catch {
        Write-Host "ZIP file is corrupted or unreadable." -ForegroundColor Red
        Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "Skipped zipping full package folder." -ForegroundColor Yellow
    Log-Step "User skipped zipping full package folder"
}

Log-Step "FULL Package script completed successfully."
}