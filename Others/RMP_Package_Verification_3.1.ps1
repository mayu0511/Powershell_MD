    Clear-Host
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

    $packagedir = 'E:\Packages\JAZZ\UAT2\'
    $packagename = Read-Host "Step 1: Enter the RMP Package Name to zip (e.g., CP7064_POD3-Jazz-UAT2_25.2.2_TO_25.2.8)"
    $sourceFolder = Join-Path $packagedir $packagename
    $destinationZip = Join-Path $packagedir "${packagename}_RMP.zip"

    Log-Step "Package type selected: $packageType"
    Log-Step "Package name entered: $packagename"

    if ($packageType -eq 'full') {
    Write-Host "\n🧱 FULL Package Selected. Executing all steps..." -ForegroundColor Cyan

   # ------------------ Step 2: Confirm Zipping ------------------

    $zipConfirm = Read-Host "`nStep 2: Do you want to ZIP the package now? (Y/N)"

    if ($zipConfirm -match '^[Yy]$') {
    if (Test-Path $sourceFolder) {
        if (Test-Path $destinationZip) {
            Remove-Item $destinationZip -Force
            Write-Host "🗑️ Deleted existing ZIP: $destinationZip" -ForegroundColor Yellow
            Log-Step "Deleted existing ZIP: $destinationZip"
        }

        try {
            # ✅ Include the full folder as root in ZIP (not just its contents)
            Compress-Archive -Path $sourceFolder -DestinationPath $destinationZip -Force

            Write-Host "`n✅ Package folder zipped to: $destinationZip" -ForegroundColor Green
            Log-Step "Package folder zipped to: $destinationZip"
        } catch {
            Write-Host "`n❌ Failed to create ZIP archive: $($_.Exception.Message)" -ForegroundColor Red
            Log-Step "Failed to create ZIP: $($_.Exception.Message)"
        }
    } else {
        Write-Host "❌ Source folder not found: $sourceFolder" -ForegroundColor Red
        Log-Step "Source folder not found: $sourceFolder"
    }
    } else {
    Write-Host "⏭️ Skipping ZIP step..." -ForegroundColor Yellow
    Log-Step "Skipped ZIP step"
    }

# ------------------ Step 3: Check ZIP File Status ------------------

    $zipPath = $destinationZip

    if (Test-Path $zipPath) {
    $fileInfo = Get-Item $zipPath
    if ($fileInfo.Length -gt 0) {
        Write-Host "`n✅ ZIP file created successfully: $zipPath" -ForegroundColor Green
        Log-Step "ZIP file size: $($fileInfo.Length) bytes"
    } else {
        Write-Host "`n⚠️ ZIP file is empty: $zipPath" -ForegroundColor Yellow
        Log-Step "ZIP file is empty"
    }
    } else {
    Write-Host "`n⚠️ ZIP file not found: $zipPath" -ForegroundColor Yellow
    Log-Step "ZIP file not found after skipping/attempt"
    }

# ------------------ Step 4: Validate ZIP File ------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
    Write-Host "`n✅ ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed"
    } catch {
    Write-Host "`n❌ ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }

# ------------------ Step 5: List ZIP Contents ------------------

    try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    Write-Host "`n📦 Contents of the ZIP archive:" -ForegroundColor Cyan

    foreach ($entry in $zip.Entries) {
        Write-Host " - $($entry.FullName)"
    }

    Write-Host "`n📦 Total Entries: $($zip.Entries.Count)" -ForegroundColor Cyan
    Log-Step "ZIP entries listed: $($zip.Entries.Count)"
    $zip.Dispose()
    } catch {
    Write-Host "`n❌ Failed to read ZIP contents: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Error reading ZIP: $($_.Exception.Message)"
    }

    
    # ------------------ Step 3: Ensure subfolders inside DataBasePackage_KMS and DataBasePackage_PlatForm ------------------

    $confirmEnsureSubfolders = Read-Host "`nStep 3: Ensure subfolders inside DataBasePackage_KMS and DataBasePackage_PlatForm? (Y/N)"

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
    Write-Host "`n⚠️ Folder '$relativePath' is empty." -ForegroundColor Yellow
    $confirmCreate = Read-Host "Do you want to create a '1' subfolder inside '$relativePath'? (Y/N)"

    if ($confirmCreate -match '^[Yy]$') {
    $nestedFolder = Join-Path $fullPath "1"
    if (!(Test-Path $nestedFolder)) {
    New-Item -Path $nestedFolder -ItemType Directory | Out-Null
    Write-Host "📁 Created folder: $nestedFolder" -ForegroundColor Cyan
    Log-Step "Created subfolder: $nestedFolder inside empty $relativePath"
    } else {
    Write-Host "📁 Subfolder already exists: $nestedFolder" -ForegroundColor Yellow
    Log-Step "Subfolder already exists: $nestedFolder"
    }
    } else {
    Write-Host "⏭️ Skipped creating '1' folder inside: $relativePath" -ForegroundColor Yellow
    Log-Step "User skipped creating '1' in: $relativePath"
    }
    } else {
    Write-Host "📦 $relativePath already contains files or folders. No need to create '1'." -ForegroundColor Green
    Log-Step "Skipped creation: $relativePath is not empty"
    }
    } else {
    Write-Host "❌ Folder does not exist: $relativePath" -ForegroundColor Red
    Log-Step "Skipped: $relativePath not found"
    }
    }
    } else {
    Write-Host "⏭️ Skipped Step 3 - Ensuring subfolders in KMS/Platform folders." -ForegroundColor Yellow
    Log-Step "User skipped Step 3 - Ensuring subfolders in KMS/Platform folders"
    }

    # ------------------ Step 4: Confirm Deletion of Unwanted Items ------------------

    $proceedDelete = Read-Host "`nStep 4: Do you want to delete unwanted files/folders from the package? (Y/N)"
    if ($proceedDelete -notmatch '^[Yy]$') {
    Write-Host "⏭️ Skipping deletion step..."
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
        "\Consolidated_Package_Delta_Merge.txt",
        "\Consolidated_Package\TraceFiles\CoreIssue\Log",
        "\Consolidated_Package\TraceFiles\CoreIssue\OrigionalFileBackup",
        "\Consolidated_Package\TraceFiles\CoreAuth\Log",
        "\Consolidated_Package\TraceFiles\CoreAuth\OrigionalFileBackup"
    )

    Write-Host "`n🗑️ Deleting unwanted files/folders (confirmation required for each)..."
    Log-Step "Started deleting unwanted files"

    foreach ($relativePath in $deleteList) {
    $fullPath = Join-Path $sourceFolder $relativePath.TrimStart('\')
    if (Test-Path $fullPath) {
    $confirmDel = Read-Host "`n➡️ Do you want to delete:`n$fullPath`n(Y/N)"
    if ($confirmDel -match '^[Yy]$') {
    try {
    if ((Get-Item $fullPath).PSIsContainer) {
    Remove-Item -Path $fullPath -Recurse -Force
    } else {
    Remove-Item -Path $fullPath -Force
    }
    Write-Host "✅ Deleted: $fullPath"
    Log-Step "Deleted: $fullPath"
    $deletedItems += $fullPath
    } catch {
    Write-Host "⚠️ Failed to delete: $fullPath - $_"
    Log-Step "Failed to delete: $fullPath - $_"
    }
    } else {
    Write-Host "⏭️ Skipped: $fullPath"
    Log-Step "Skipped deletion: $fullPath"
    }
    } else {
    Write-Host "❌ Not found: $fullPath"
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

    $confirmZipEach = Read-Host "`nStep 5: Do you want to ZIP each folder inside 'Consolidated_Package' to 'Package'? (Y/N)"
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

    Write-Host "`n📁 Consolidated_Package contains $folderCount folders and $originalFileCount files." -ForegroundColor Cyan
    Log-Step "Consolidated_Package contains $folderCount folders and $originalFileCount files"

    $zippedFilesTotal = 0
    $zipCount = 0

    Get-ChildItem -Path $consolidatedPath -Directory | ForEach-Object {
    $folderName = $_.Name
    $folderPath = $_.FullName
    $zipFile    = Join-Path $packagePath "$folderName.zip"

    try {
    Compress-Archive -Path $folderPath -DestinationPath $zipFile -Force
    Write-Host "✅ Zipped: $folderName => $zipFile" -ForegroundColor Green
    Log-Step "Zipped: $folderPath => $zipFile"
    $zipCount++

    # ----------------Count files in this folder---------------------------------------

    $folderFiles = (Get-ChildItem -Path $folderPath -Recurse -File).Count
    $zippedFilesTotal += $folderFiles

    #----------- ---Validate ZIP--------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
    Write-Host "✅ ZIP is valid: $zipFile" -ForegroundColor Green
    Log-Step "ZIP validated: $zipFile"
    } catch {
    Write-Host "❌ ZIP invalid: $zipFile - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ZIP validation failed: $zipFile - $($_.Exception.Message)"
    }
    } catch {
                Write-Host "❌ Failed to zip: $folderPath - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ERROR: Failed to zip $folderPath - $($_.Exception.Message)"
    }
    }

    $totalZipFiles = (Get-ChildItem -Path $packagePath -Filter *.zip).Count
    $actualZippedFileCount = (Get-ChildItem -Path $packagePath -Recurse -File).Count

    Write-Host "`n📦 Package folder contains $totalZipFiles zip files and $actualZippedFileCount total files." -ForegroundColor Cyan
    Write-Host "📄 Total original files zipped from Consolidated_Package: $zippedFilesTotal" -ForegroundColor Cyan

    Log-Step "Package zip count: $totalZipFiles, total zipped files: $zippedFilesTotal"
    Log-Step "All subfolders zipped from Consolidated_Package"
    } else {
    Write-Host "❌ Consolidated_Package folder not found: $consolidatedPath" -ForegroundColor Red
    Log-Step "ERROR: Consolidated_Package folder not found: $consolidatedPath"
    }
    } else {
    Write-Host "⏭️ Skipped Step 5 - Zipping each subfolder." -ForegroundColor Yellow
    Log-Step "User skipped Step 5"
    }

    # ------------------ Step 6: Validate Items in Package ------------------

    $confirmValidate = Read-Host "`nStep 6: Do you want to validate expected items in 'Package'? (Y/N)"
    if ($confirmValidate -match '^[Yy]$') {

    if ($packagedir -match 'JAZZ') {
    $expectedItemsFile = "E:\Packages\JAZZ_items.txt"
    }
    elseif ($packagedir -match 'COOKIE') {
    $expectedItemsFile = "E:\Packages\Cookie_items.txt"
    }
    else {
    Write-Host "❌ Could not determine expected items file based on packagedir: $packagedir" -ForegroundColor Red
    Log-Step "Unable to determine expectedItemsFile. Unknown path: $packagedir"
    return
    }

    $package = Join-Path $sourceFolder "Package"

    if (!(Test-Path $expectedItemsFile)) {
    Write-Host "❌ Expected items file not found: $expectedItemsFile" -ForegroundColor Red
    Log-Step "Expected items file not found: $expectedItemsFile"
    }
    elseif (!(Test-Path $package)) {
    Write-Host "❌ Package folder not found: $package" -ForegroundColor Red
    Log-Step "Package folder not found: $package"
    }
    else {
    $expectedItems = Get-Content -Path $expectedItemsFile | Where-Object { $_ -ne '' }

    # ✅ Print all expected items and their count
    Write-Host "`n📋 Expected items from file: $expectedItemsFile" -ForegroundColor Cyan
    $expectedItems | ForEach-Object { Write-Host "- $_" }
    Write-Host "`n📦 Total expected items: $($expectedItems.Count)" -ForegroundColor Green
    Log-Step "Expected items loaded from $expectedItemsFile. Count: $($expectedItems.Count)"

    $receivedFiles = Get-ChildItem -Path $package -File | Select-Object -ExpandProperty Name

    $missingItems = $expectedItems | Where-Object { $_ -notin $receivedFiles }
    $extraItems   = $receivedFiles | Where-Object { $_ -notin $expectedItems }

    if ($missingItems.Count -eq 0) {
    Write-Host "`n✅ All expected items are present in the package." -ForegroundColor Green
    Log-Step "All expected items are present in 'Package'"
    } else {
    Write-Host "`n❌ Missing items in the package:" -ForegroundColor Red
    $missingItems | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    Write-Host "❌ Total missing: $($missingItems.Count)" -ForegroundColor Red
    Log-Step "Missing items in 'Package': $($missingItems -join ', ')"
    }

    if ($extraItems.Count -gt 0) {
    Write-Host "`n⚠️ Extra files found in the package:" -ForegroundColor Yellow
    $extraItems | ForEach-Object { Write-Host "+ $_" -ForegroundColor Yellow }
    Write-Host "⚠️ Total extra: $($extraItems.Count)" -ForegroundColor Yellow
    Log-Step "Extra items found in 'Package': $($extraItems -join ', ')"
    } else {
    Log-Step "No extra files found in 'Package'"
    }
    }
    }
    else {
    Write-Host "⏭️ Skipped item validation step."
    Log-Step "Skipped validation of expected items in 'Package'"
    }

    # ------------------ Step 7: Zip the Package Folder ------------------
    
    $confirmZipFinal = Read-Host "`nStep 7: Do you want to ZIP the final 'Package' folder into 'Package.zip'? (Y/N)"
    if ($confirmZipFinal -match '^[Yy]$') {
    $package = Join-Path $sourceFolder "Package"
    $zipFile = Join-Path $sourceFolder "Package.zip"

    if (!(Test-Path $package)) {
    Write-Host "❌ Package folder not found at: $package" -ForegroundColor Red
    Log-Step "ERROR: Package folder not found: $package"
    return
    }

    try {
    if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
    Write-Host "🗑️ Deleted existing Package.zip..." -ForegroundColor Yellow
    Log-Step "Deleted existing Package.zip before creating new archive."
    }

    # ✅ Compress the entire folder (so it shows as 'Package\' inside the ZIP)
    Compress-Archive -Path $package -DestinationPath $zipFile -Force

    Write-Host "`n✅ 'Package' folder zipped to: $zipFile" -ForegroundColor Green
    Log-Step "Zipped 'Package' folder to $zipFile"
    } catch {
    Write-Host "`n❌ Failed to zip the 'Package' folder. Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Magenta
    Log-Step "ZIP failed: $($_.Exception.Message)"
    return
    }

    # ✅ Validate ZIP
    try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
    Write-Host "`n✅ ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed for: $zipFile"
    } catch {
    Write-Host "`n❌ ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
    } else {
    Write-Host "⏭️ Skipped zipping the final Package folder." -ForegroundColor Yellow
    Log-Step "Skipped zipping final Package folder"
    }

    # ------------------ Step 8: Delete 'Consolidated_Package' and 'Package' folders ------------------

    $confirmDeleteFolders = Read-Host "`nStep 8: Do you want to delete both 'Consolidated_Package' and 'Package' folders? (Y/N)"
    if ($confirmDeleteFolders -match '^[Yy]$') {
    $foldersToDelete = @("Consolidated_Package", "Package")

    foreach ($folder in $foldersToDelete) {
    $fullPath = Join-Path $sourceFolder $folder
    if (Test-Path $fullPath) {
    try {
    Remove-Item -Path $fullPath -Recurse -Force
    Write-Host "✅ Deleted: $fullPath" -ForegroundColor Green
    Log-Step "Deleted folder: $fullPath"
    } catch {
    Write-Host "❌ Failed to delete $fullPath - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Failed to delete $fullPath - $($_.Exception.Message)"
            }
    } else {
    Write-Host "⚠️ Not found (already deleted or missing): $fullPath" -ForegroundColor Yellow
    Log-Step "Folder not found or already deleted: $fullPath"
    }
    }
    } else {
    Write-Host "⏭️ Skipped folder deletion." -ForegroundColor Yellow
    Log-Step "Skipped deletion of folders"
    }
    
    # ------------------ Step 9: List All Files and Folders in Package Root ------------------

    $confirmFinalCheck = Read-Host "`nStep 9: Do you want to List All Files and Folders in Package Root? (Y/N)"

    if ($confirmFinalCheck -match '^[Yy]$') {
    Write-Host "`n📦 Listing all files and folders in the package root folder: $sourceFolder" -ForegroundColor Cyan
    Log-Step "Listing all files and folders in $sourceFolder"

    if (Test-Path $sourceFolder) {
    $allItems = Get-ChildItem -Path $sourceFolder

    if ($allItems.Count -eq 0) {
    Write-Host "⚠️ No files or folders found in $sourceFolder" -ForegroundColor Yellow
    Log-Step "No files or folders found in $sourceFolder"
    } else {
    foreach ($item in $allItems) {
    $type = if ($item.PSIsContainer) { "📁 Folder" } else { "📄 File" }
    Write-Host "$type`t$item.Name"
    }

    Write-Host "`n📦 Total Items Found: $($allItems.Count)" -ForegroundColor Cyan
    Log-Step "Total items listed in $sourceFolder $($allItems.Count)"
    }
    } else {
    Write-Host "❌ Source folder not found: $sourceFolder" -ForegroundColor Red
    Log-Step "Source folder not found while listing: $sourceFolder"
    }
    } else {
    Write-Host "⏭️ Skipped listing of files and folders in package root folder."
    Log-Step "Skipped listing of items in $sourceFolder"
    }

    # ------------------ Step 10: Checksum Generation ------------------

    $confirmChecksum = Read-Host "`nStep 10: Do you want to generate checksum of Package.zip? (Y/N)"

    if ($confirmChecksum -match '^[Yy]$') {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $zipFile = Join-Path $sourceFolder "Package.zip"
    $hashOutputFile = Join-Path $sourceFolder "CCpackage_hash_$timestamp.txt"

    Write-Host "`n🧮 Task 1 Started - Generating SHA256 hash of Package.zip (CoreCard Package)" -ForegroundColor Green
    Write-Host "📁 Target path      : $sourceFolder"
    Write-Host "📄 Output hash file : $hashOutputFile"

    if (Test-Path $zipFile) {
    Write-Host "✅ Package.zip found at: $zipFile" -ForegroundColor Cyan
    try {
    Write-Host "🔄 Computing SHA256 hash..."
    $hash = Get-FileHash -Path $zipFile -Algorithm SHA256
    $hash.Hash | Out-File -FilePath $hashOutputFile -Encoding utf8

    Write-Host "`n✅ SHA256 hash saved to file: $hashOutputFile" -ForegroundColor Green
    Write-Host "🔐 Hash value: $($hash.Hash)" -ForegroundColor Yellow
    Log-Step "Checksum generated and saved to $hashOutputFile"
    } catch {
    Write-Host "`n❌ ERROR: Failed to compute hash. Exception: $_" -ForegroundColor Red
    Log-Step "Failed to generate hash: $_"
    }
    } else {
    Write-Host "`n❌ ERROR: Package.zip not found in path: $sourceFolder" -ForegroundColor Red
    Log-Step "Package.zip not found in $sourceFolder"
    }
    } else {
    Write-Host "⏭️ Skipped checksum generation." -ForegroundColor Yellow
    Log-Step "User skipped checksum generation."
    }

 # ------------------ Step 11: Zip the Main Package Folder ------------------

    $confirmManualZip = Read-Host "`nStep 11: Do you want to ZIP the full '$packagename' folder now? (Y/N)"

    if ($confirmManualZip -match '^[Yy]$') {
    $manualSourceFolder = $sourceFolder              # e.g., E:\Packages\JAZZ\UAT2\CP7064_POD3...
    $manualZipFile      = "$manualSourceFolder.zip"  # Output file: E:\Packages\...\CP7064_POD3....zip

    Log-Step "User confirmed to zip the full package folder: $manualSourceFolder"

    if (Test-Path $manualSourceFolder) {
    try {
    if (Test-Path $manualZipFile) {
    Remove-Item $manualZipFile -Force
    Write-Host "🗑️ Deleted existing ZIP: $manualZipFile" -ForegroundColor Yellow
    Log-Step "Deleted existing ZIP: $manualZipFile"
    }

    # ✅ Use Compress-Archive so ZIP contains the root folder (not just files)
    Compress-Archive -Path $manualSourceFolder -DestinationPath $manualZipFile -Force

    Write-Host "`n✅ Package folder zipped to: $manualZipFile" -ForegroundColor Green
    Log-Step "Successfully zipped full folder to: $manualZipFile"
    } catch {
    Write-Host "`n❌ Failed to zip package folder: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ERROR: Failed to zip full folder - $($_.Exception.Message)"
    }
    } else {
        Write-Host "`n❌ Source folder not found: $manualSourceFolder" -ForegroundColor Red
    Log-Step "ERROR: Source folder not found: $manualSourceFolder"
    }

    # ✅ Validate ZIP
    try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::OpenRead($manualZipFile).Dispose()
    Write-Host "`n✅ ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed for $manualZipFile"
    } catch {
    Write-Host "`n❌ ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
    } else {
    Write-Host "⏭️ Skipped zipping full package folder." -ForegroundColor Yellow
    Log-Step "User skipped zipping full package folder"
    }

    Log-Step "FULL Package script completed successfully."
    
    ###==================FUll Done====================###
    
    } elseif ($packageType -eq 'patch') {
    Write-Host "\n📦 PATCH Package Selected. Executing all steps except Step 6 (validation)..." -ForegroundColor Cyan

    # ------------------ Step 2: Confirm Zipping ------------------

    $zipConfirm = Read-Host "`nStep 2: Do you want to ZIP the package now? (Y/N)"

    if ($zipConfirm -match '^[Yy]$') {
    if (Test-Path $sourceFolder) {
    if (Test-Path $destinationZip) {
    Remove-Item $destinationZip -Force
    Write-Host "🗑️ Deleted existing ZIP: $destinationZip" -ForegroundColor Yellow
    Log-Step "Deleted existing ZIP: $destinationZip"
    }

    try {
    # ✅ Include the full folder as root in ZIP (not just its contents)
    Compress-Archive -Path $sourceFolder -DestinationPath $destinationZip -Force

    Write-Host "`n✅ Package folder zipped to: $destinationZip" -ForegroundColor Green
    Log-Step "Package folder zipped to: $destinationZip"
    } catch {
    Write-Host "`n❌ Failed to create ZIP archive: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Failed to create ZIP: $($_.Exception.Message)"
    }
    } else {
    Write-Host "❌ Source folder not found: $sourceFolder" -ForegroundColor Red
    Log-Step "Source folder not found: $sourceFolder"
    }
    } else {
    Write-Host "⏭️ Skipping ZIP step..." -ForegroundColor Yellow
    Log-Step "Skipped ZIP step"
    }

    # ------------------ Step 3: Check ZIP File Status ------------------

    $zipPath = $destinationZip

    if (Test-Path $zipPath) {
    $fileInfo = Get-Item $zipPath
    if ($fileInfo.Length -gt 0) {
    Write-Host "`n✅ ZIP file created successfully: $zipPath" -ForegroundColor Green
    Log-Step "ZIP file size: $($fileInfo.Length) bytes"
    } else {
    Write-Host "`n⚠️ ZIP file is empty: $zipPath" -ForegroundColor Yellow
    Log-Step "ZIP file is empty"
    }
    } else {
    Write-Host "`n⚠️ ZIP file not found: $zipPath" -ForegroundColor Yellow
    Log-Step "ZIP file not found after skipping/attempt"
    }

    # ------------------ Step 4: Validate ZIP File ------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
    Write-Host "`n✅ ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed"
    } catch {
    Write-Host "`n❌ ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }

    # ------------------ Step 5: List ZIP Contents ------------------

    try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    Write-Host "`n📦 Contents of the ZIP archive:" -ForegroundColor Cyan

    foreach ($entry in $zip.Entries) {
    Write-Host " - $($entry.FullName)"
    }

    Write-Host "`n📦 Total Entries: $($zip.Entries.Count)" -ForegroundColor Cyan
    Log-Step "ZIP entries listed: $($zip.Entries.Count)"
    $zip.Dispose()
    } catch {
    Write-Host "`n❌ Failed to read ZIP contents: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Error reading ZIP: $($_.Exception.Message)"
    }

    # ------------------ Step 3: Ensure subfolders inside DataBasePackage_KMS and DataBasePackage_PlatForm ------------------

    $confirmEnsureSubfolders = Read-Host "`nStep 3: Ensure subfolders inside DataBasePackage_KMS and DataBasePackage_PlatForm? (Y/N)"

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
    Write-Host "`n⚠️ Folder '$relativePath' is empty." -ForegroundColor Yellow
    $confirmCreate = Read-Host "Do you want to create a '1' subfolder inside '$relativePath'? (Y/N)"

    if ($confirmCreate -match '^[Yy]$') {
    $nestedFolder = Join-Path $fullPath "1"
    if (!(Test-Path $nestedFolder)) {
    New-Item -Path $nestedFolder -ItemType Directory | Out-Null
    Write-Host "📁 Created folder: $nestedFolder" -ForegroundColor Cyan
    Log-Step "Created subfolder: $nestedFolder inside empty $relativePath"
    } else {
    Write-Host "📁 Subfolder already exists: $nestedFolder" -ForegroundColor Yellow
    Log-Step "Subfolder already exists: $nestedFolder"
    }
    } else {
    Write-Host "⏭️ Skipped creating '1' folder inside: $relativePath" -ForegroundColor Yellow
    Log-Step "User skipped creating '1' in: $relativePath"
                }
    } else {
    Write-Host "📦 $relativePath already contains files or folders. No need to create '1'." -ForegroundColor Green
    Log-Step "Skipped creation: $relativePath is not empty"
            }
    } else {
    Write-Host "❌ Folder does not exist: $relativePath" -ForegroundColor Red
    Log-Step "Skipped: $relativePath not found"
    }
    }
    } else {
    Write-Host "⏭️ Skipped Step 3 - Ensuring subfolders in KMS/Platform folders." -ForegroundColor Yellow
    Log-Step "User skipped Step 3 - Ensuring subfolders in KMS/Platform folders"
    }

    # ------------------ Step 4: Confirm Deletion of Unwanted Items ------------------

$proceedDelete = Read-Host "`nStep 4: Do you want to delete unwanted files/folders from the package? (Y/N)"
if ($proceedDelete -notmatch '^[Yy]$') {
    Write-Host "⏭️ Skipping deletion step..."
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
        "\Consolidated_Package\WCFServer\WCF\Log",
        "\Consolidated_Package\WCFServer\WCF\Web_Master.config",
        "\Consolidated_Package\WCFServer\WCF\Web_WithValue.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\appSettings_Master.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\appSettings_WithValue.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\connectionStrings_Master.config",
        "\Consolidated_Package\WCFServer\WCF\configuration\connectionStrings_WithValue.config",
        "\Consolidated_Package\WebServer\DBBWEB\Web_Master.config",
        "\Consolidated_Package\WebServer\Services\Web_Master.config",
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

    Write-Host "`n🗑️ Deleting unwanted files/folders (confirmation required)..."
    Log-Step "Started deleting unwanted files"

    foreach ($relativePath in $deleteList) {
        $fullPath = Join-Path $sourceFolder $relativePath.TrimStart('\')
        if (Test-Path $fullPath) {
            $item = Get-Item $fullPath
            $isFile = -not $item.PSIsContainer
            $isDelta = $fullPath -like '*_Delta*'

            if ($isFile -and $isDelta) {
                if ($item.Length -eq 0) {
                    $askDelta = Read-Host "`n⚠️ _Delta file is 0 KB: $fullPath`nDo you want to delete it? (Y/N)"
                    if ($askDelta -notmatch '^[Yy]$') {
                        Write-Host "⏭️ Skipped _Delta 0 KB file: $fullPath"
                        Log-Step "Skipped _Delta 0 KB file: $fullPath"
                        continue
                    }
                } else {
                    Write-Host "✅ _Delta file has size > 0, not deleted: $fullPath"
                    Log-Step "Kept _Delta file with data: $fullPath"
                    continue
                }
            }

            $confirmDel = Read-Host "`n➡️ Do you want to delete:`n$fullPath`n(Y/N)"
            if ($confirmDel -match '^[Yy]$') {
                try {
                    if ($item.PSIsContainer) {
                        Remove-Item -Path $fullPath -Recurse -Force
                    } else {
                        Remove-Item -Path $fullPath -Force
                    }
                    Write-Host "✅ Deleted: $fullPath"
                    Log-Step "Deleted: $fullPath"
                    $deletedItems += $fullPath
                } catch {
                    Write-Host "⚠️ Failed to delete: $fullPath - $_"
                    Log-Step "Failed to delete: $fullPath - $_"
                }
            } else {
                Write-Host "⏭️ Skipped: $fullPath"
                Log-Step "Skipped deletion: $fullPath"
            }
        } else {
            Write-Host "❌ Not found: $fullPath"
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

    $confirmZipEach = Read-Host "`nStep 5: Do you want to ZIP each folder inside 'Consolidated_Package' to 'Package'? (Y/N)"
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

    Write-Host "`n📁 Consolidated_Package contains $folderCount folders and $originalFileCount files." -ForegroundColor Cyan
    Log-Step "Consolidated_Package contains $folderCount folders and $originalFileCount files"

    $zippedFilesTotal = 0
    $zipCount = 0

    Get-ChildItem -Path $consolidatedPath -Directory | ForEach-Object {
    $folderName = $_.Name
    $folderPath = $_.FullName
    $zipFile    = Join-Path $packagePath "$folderName.zip"

    try {
    Compress-Archive -Path $folderPath -DestinationPath $zipFile -Force
    Write-Host "✅ Zipped: $folderName => $zipFile" -ForegroundColor Green
    Log-Step "Zipped: $folderPath => $zipFile"
    $zipCount++

    # Count files in this folder
    $folderFiles = (Get-ChildItem -Path $folderPath -Recurse -File).Count
    $zippedFilesTotal += $folderFiles

    # Validate ZIP
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
    [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
    Write-Host "✅ ZIP is valid: $zipFile" -ForegroundColor Green
    Log-Step "ZIP validated: $zipFile"
    } catch {
    Write-Host "❌ ZIP invalid: $zipFile - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ZIP validation failed: $zipFile - $($_.Exception.Message)"
    }
    } catch {
    Write-Host "❌ Failed to zip: $folderPath - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ERROR: Failed to zip $folderPath - $($_.Exception.Message)"
    }
    }

    $totalZipFiles = (Get-ChildItem -Path $packagePath -Filter *.zip).Count
    $actualZippedFileCount = (Get-ChildItem -Path $packagePath -Recurse -File).Count

    Write-Host "`n📦 Package folder contains $totalZipFiles zip files and $actualZippedFileCount total files." -ForegroundColor Cyan
    Write-Host "📄 Total original files zipped from Consolidated_Package: $zippedFilesTotal" -ForegroundColor Cyan

    Log-Step "Package zip count: $totalZipFiles, total zipped files: $zippedFilesTotal"
    Log-Step "All subfolders zipped from Consolidated_Package"
    } else {
    Write-Host "❌ Consolidated_Package folder not found: $consolidatedPath" -ForegroundColor Red
    Log-Step "ERROR: Consolidated_Package folder not found: $consolidatedPath"
    }
    }

    # ✅ Always log and show Step 6 as skipped (even if Y was selected)
    Write-Host "⏭️ Skipped Step 6 - Validate Items in Package." -ForegroundColor Yellow
    Log-Step "User skipped Step 6"
    
    # ------------------ Step 7: Zip the Package Folder ------------------

    $confirmZipFinal = Read-Host "`nStep 7: Do you want to ZIP the final 'Package' folder into 'Package.zip'? (Y/N)"
    if ($confirmZipFinal -match '^[Yy]$') {
    # Assume $sourceFolder is defined from previous steps (e.g., E:\Packages\JAZZ\UAT2\CP7064_POD3...)
    $package = Join-Path $sourceFolder "Package"
    $zipFile = Join-Path $sourceFolder "Package.zip"

    if (!(Test-Path $package)) {
    Write-Host "❌ Package folder not found at: $package" -ForegroundColor Red
    Log-Step "ERROR: Package folder not found: $package"
    return
    }

    try {
    if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
    Write-Host "🗑️ Deleted existing Package.zip..." -ForegroundColor Yellow
    Log-Step "Deleted existing Package.zip before creating new archive."
    }

    # ✅ Compress the entire folder (so it shows as 'Package\' inside the ZIP)
    Compress-Archive -Path $package -DestinationPath $zipFile -Force

    Write-Host "`n✅ 'Package' folder zipped to: $zipFile" -ForegroundColor Green
    Log-Step "Zipped 'Package' folder to $zipFile"
    } catch {
    Write-Host "`n❌ Failed to zip the 'Package' folder. Error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Magenta
    Log-Step "ZIP failed: $($_.Exception.Message)"
    return
    }

    # ✅ Validate ZIP
    try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::OpenRead($zipFile).Dispose()
    Write-Host "`n✅ ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed for: $zipFile"
    } catch {
    Write-Host "`n❌ ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
    } else {
    Write-Host "⏭️ Skipped zipping the final Package folder." -ForegroundColor Yellow
    Log-Step "Skipped zipping final Package folder"
    }

    # ------------------ Step 8: Delete 'Consolidated_Package' and 'Package' folders ------------------

    $confirmDeleteFolders = Read-Host "`nStep 8: Do you want to delete both 'Consolidated_Package' and 'Package' folders? (Y/N)"
    if ($confirmDeleteFolders -match '^[Yy]$') {
    $foldersToDelete = @("Consolidated_Package", "Package")

    foreach ($folder in $foldersToDelete) {
    $fullPath = Join-Path $sourceFolder $folder
    if (Test-Path $fullPath) {
    try {
    Remove-Item -Path $fullPath -Recurse -Force
    Write-Host "✅ Deleted: $fullPath" -ForegroundColor Green
    Log-Step "Deleted folder: $fullPath"
    } catch {
    Write-Host "❌ Failed to delete $fullPath - $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "Failed to delete $fullPath - $($_.Exception.Message)"
    }
    } else {
    Write-Host "⚠️ Not found (already deleted or missing): $fullPath" -ForegroundColor Yellow
    Log-Step "Folder not found or already deleted: $fullPath"
    }
    }
    } else {
    Write-Host "⏭️ Skipped folder deletion." -ForegroundColor Yellow
    Log-Step "Skipped deletion of folders"
    }

    # ------------------ Step 9: List All Files and Folders in Package Root ------------------

    $confirmFinalCheck = Read-Host "`nStep 9: Do you want to List All Files and Folders in Package Root? (Y/N)"

    if ($confirmFinalCheck -match '^[Yy]$') {
    Write-Host "`n📦 Listing all files and folders in the package root folder: $sourceFolder" -ForegroundColor Cyan
    Log-Step "Listing all files and folders in $sourceFolder"

    if (Test-Path $sourceFolder) {
    $allItems = Get-ChildItem -Path $sourceFolder

    if ($allItems.Count -eq 0) {
    Write-Host "⚠️ No files or folders found in $sourceFolder" -ForegroundColor Yellow
    Log-Step "No files or folders found in $sourceFolder"
    } else {
    foreach ($item in $allItems) {
    $type = if ($item.PSIsContainer) { "📁 Folder" } else { "📄 File" }
    Write-Host "$type`t$item.Name"
    }

    Write-Host "`n📦 Total Items Found: $($allItems.Count)" -ForegroundColor Cyan
    Log-Step "Total items listed in $sourceFolder $($allItems.Count)"
    }
    } else {
    Write-Host "❌ Source folder not found: $sourceFolder" -ForegroundColor Red
    Log-Step "Source folder not found while listing: $sourceFolder"
    }
    } else {
    Write-Host "⏭️ Skipped listing of files and folders in package root folder."
    Log-Step "Skipped listing of items in $sourceFolder"
    }

    # ------------------ Step 10: Checksum Generation ------------------
    $confirmChecksum = Read-Host "`nStep 10: Do you want to generate checksum of Package.zip? (Y/N)"

    if ($confirmChecksum -match '^[Yy]$') {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # Define correct zip file path and output hash file path
    $zipFile = Join-Path $sourceFolder "Package.zip"
    $hashOutputFile = Join-Path $sourceFolder "CCpackage_hash_$timestamp.txt"

    Write-Host "`n🧮 Task 1 Started - Generating SHA256 hash of Package.zip (CoreCard Package)" -ForegroundColor Green
    Write-Host "📁 Target path      : $sourceFolder"
    Write-Host "📄 Output hash file : $hashOutputFile"

    if (Test-Path $zipFile) {
    Write-Host "✅ Package.zip found at: $zipFile" -ForegroundColor Cyan
    try {
    Write-Host "🔄 Computing SHA256 hash..."
    $hash = Get-FileHash -Path $zipFile -Algorithm SHA256
    $hash.Hash | Out-File -FilePath $hashOutputFile -Encoding utf8

    Write-Host "`n✅ SHA256 hash saved to file: $hashOutputFile" -ForegroundColor Green
    Write-Host "🔐 Hash value: $($hash.Hash)" -ForegroundColor Yellow
    Log-Step "Checksum generated and saved to $hashOutputFile"
    } catch {
    Write-Host "`n❌ ERROR: Failed to compute hash. Exception: $_" -ForegroundColor Red
    Log-Step "Failed to generate hash: $_"
    }
    } else {
    Write-Host "`n❌ ERROR: Package.zip not found in path: $sourceFolder" -ForegroundColor Red
    Log-Step "Package.zip not found in $sourceFolder"
    }
    } else {
    Write-Host "⏭️ Skipped checksum generation." -ForegroundColor Yellow
    Log-Step "User skipped checksum generation."
    }

    # ------------------ Step 11: Zip the Main Package Folder ------------------

    $confirmManualZip = Read-Host "`nStep 11: Do you want to ZIP the full '$packagename' folder now? (Y/N)"

    if ($confirmManualZip -match '^[Yy]$') {
    $manualSourceFolder = $sourceFolder              # e.g., E:\Packages\JAZZ\UAT2\CP7064_POD3...
    $manualZipFile      = "$manualSourceFolder.zip"  # Output file: E:\Packages\...\CP7064_POD3....zip

    Log-Step "User confirmed to zip the full package folder: $manualSourceFolder"

    if (Test-Path $manualSourceFolder) {
    try {
    if (Test-Path $manualZipFile) {
    Remove-Item $manualZipFile -Force
    Write-Host "🗑️ Deleted existing ZIP: $manualZipFile" -ForegroundColor Yellow
    Log-Step "Deleted existing ZIP: $manualZipFile"
    }

    # ✅ Use Compress-Archive so ZIP contains the root folder (not just files)
    Compress-Archive -Path $manualSourceFolder -DestinationPath $manualZipFile -Force

    Write-Host "`n✅ Package folder zipped to: $manualZipFile" -ForegroundColor Green
    Log-Step "Successfully zipped full folder to: $manualZipFile"
    } catch {
    Write-Host "`n❌ Failed to zip package folder: $($_.Exception.Message)" -ForegroundColor Red
    Log-Step "ERROR: Failed to zip full folder - $($_.Exception.Message)"
    }
    } else {
    Write-Host "`n❌ Source folder not found: $manualSourceFolder" -ForegroundColor Red
    Log-Step "ERROR: Source folder not found: $manualSourceFolder"
    }

    # ✅ Validate ZIP
    try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::OpenRead($manualZipFile).Dispose()
    Write-Host "`n✅ ZIP file is valid and can be opened." -ForegroundColor Green
    Log-Step "ZIP validation passed for $manualZipFile"
    } catch {
    Write-Host "`n❌ ZIP file is corrupted or unreadable." -ForegroundColor Red
    Log-Step "ZIP validation failed: $($_.Exception.Message)"
    }
    } else {
    Write-Host "⏭️ Skipped zipping full package folder." -ForegroundColor Yellow
    Log-Step "User skipped zipping full package folder"
    }

    Log-Step "PATCH script completed successfully."
    Write-Host "`n✅ PATCH Packaging process completed. Log saved to: $logFile" -ForegroundColor Green

    Log-Step "PATCH Package script completed successfully."

    } else {
    Write-Host "\n❌ Invalid package type entered. Only 'Full' or 'Patch' accepted." -ForegroundColor Red
    Log-Step "Invalid package type input: $packageType"
    }
