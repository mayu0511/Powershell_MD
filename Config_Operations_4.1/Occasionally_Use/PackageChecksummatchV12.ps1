#====================================================================#
# Package Checksum | Devloped by Akash Sharma
#--RDP Module | Fixed Platform and CC_Python Checksum Issue--#
#--Version :: V11 | Date:: 12-Feb-2026#
#--Updated by : Netra Chettri
#--Enhanced: Added support for validating checksums across multiple servers | 08-Jul-2026 | Mahendra Dwivedi
#=====================================================================#
Clear-Host
$ThisServer = (Hostname).ToLower()
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

$AWSVariables = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$ThisServer" "Name=availability-zone,Values=*" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()

$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]
$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*" "Name=availability-zone,Values=*" --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique
$AvailabilityZones

$AvailabilityZone = Read-Host "Type Availability Zones your choice $AvailabilityZones"
if ($AvailabilityZone -contains "*") {
Write-host "* doesn't support anymore"
Break
}

$AvailabilityZone

$ServerTypeList = @('bat','svc','iss','aut','src','snk','tnp','awf','web','wcf','rpd','ew','kms')
$Global:ServerTypeMap = @{}
$ServerList = @()

foreach ($ServerType in $ServerTypeList) {
    Write-Host "serverType - $ServerType"

    $typeServers = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*" "Name=availability-zone,Values=$AvailabilityZone" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double](($_.Name -split "$EnvironmentName$EnvironmentStack")[1]) } } | Sort-Object -Property serial)

    $Global:ServerTypeMap[$ServerType] = @($typeServers.Name)

    $ServerList += $typeServers
}

$ServerList | Out-Host

if (-not $ServerList) {
    Write-Host "No Server in the given criteria... Please try again"
    exit
}

$ServerList = $ServerList.Name
Read-Host "Please verify the server list and press enter to continue or Stop the script"

$Global:InstanceTypeServers = @{
    "Application" = @(
        $Global:ServerTypeMap['bat'] + $Global:ServerTypeMap['svc'] + $Global:ServerTypeMap['iss'] +
        $Global:ServerTypeMap['aut'] + $Global:ServerTypeMap['src'] + $Global:ServerTypeMap['snk'] +
        $Global:ServerTypeMap['tnp'] + $Global:ServerTypeMap['awf'] | Where-Object { $_ }
    )
    "WEB"             = @($Global:ServerTypeMap['web']   | Where-Object { $_ })
    "WCF"             = @($Global:ServerTypeMap['wcf']   | Where-Object { $_ })
    "Corecredit"      = @($Global:ServerTypeMap['ew']    | Where-Object { $_ })
    "KMS"             = @($Global:ServerTypeMap['kms']   | Where-Object { $_ })
    "Report Delivery" = @($Global:ServerTypeMap['rpd']   | Where-Object { $_ })
}

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$ResultList = @()


Clear-Host

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$defaultLogDir = "C:\Logs"

if (-not (Test-Path $defaultLogDir)) {
    New-Item -Path $defaultLogDir -ItemType Directory -Force | Out-Null
}
$Global:logFile = "$defaultLogDir\PackageCheckSumGeneric_Log_$timestamp.log"

function Write-Log {
    param (
        [string]$message,
        [ConsoleColor]$ForegroundColor = "White"
    )
    
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    Add-Content -Path $Global:logFile -Value $entry
    Write-Host $entry -ForegroundColor $ForegroundColor
}

function Write-FinalSummary {
    
    if (-not $Global:summaryList -or $Global:summaryList.Count -eq 0) {
        Write-Log "No results to summarize." -ForegroundColor Yellow
        return
    }

    $colInstance    = 16
    $colModule      = 15
    $colServerCount = 14
    $colMatched     = 9
    $colMismatched  = 12
    $colNotFound    = 14

    $header = "{0,-$colInstance}{1,-$colModule}{2,-$colServerCount}{3,-$colMatched}{4,-$colMismatched}{5,-$colNotFound}" -f `
        "Instance Type", "Module", "Server Count", "Matched", "Mismatched", "NotFound"
    $divider = "{0,-$colInstance}{1,-$colModule}{2,-$colServerCount}{3,-$colMatched}{4,-$colMismatched}{5,-$colNotFound}" -f `
        ("-" * 13), ("-" * 6), ("-" * 12), ("-" * 7), ("-" * 10), ("-" * 8)

    Write-Log $header
    Write-Log $divider

    foreach ($group in ($Global:summaryList | Group-Object InstanceType)) {
        $isFirstRowInGroup = $true
        foreach ($row in $group.Group) {
            
            $typeLabel  = if ($isFirstRowInGroup) { $group.Name } else { "" }
            $countLabel = if ($isFirstRowInGroup) { $row.ServerCount } else { "" }
            $isFirstRowInGroup = $false
            $line = "{0,-$colInstance}{1,-$colModule}{2,-$colServerCount}{3,-$colMatched}{4,-$colMismatched}{5,-$colNotFound}" -f `
                $typeLabel, $row.Module, $countLabel, $row.Matched, $row.Mismatched, $row.NotFound
            Write-Log $line
        }
    }
}

function confirm-continue {
    $response = Read-Host "Do you want to continue to next task (yes/no)"
    if($response -ne 'yes'){
    Write-Host "Exiting Script as per user input" -ForegroundColor Yellow
    exit
    }
}

$Destinationpackagepath = "D:\Package"
if (-not (Test-Path $Destinationpackagepath)) {
    New-Item -Path $Destinationpackagepath -ItemType Directory | Out-Null
    Write-Log "Created folder: $Destinationpackagepath"
} else {
    Write-Log "Folder already exists: $Destinationpackagepath"
}

$userInput = Read-Host "Type 'yes' if you want to delete all items from $Destinationpackagepath else Enter to skip"

if ($userInput.ToLower() -eq 'yes') {
    Write-Log "Cleaning folder: $Destinationpackagepath ..." -ForegroundColor Yellow

    Get-ChildItem -Path $Destinationpackagepath -Recurse -Force |
    Where-Object { (-not $_.PSIsContainer -and $_.Extension -ne ".log") -or $_.PSIsContainer } |
    ForEach-Object {
        try {
            if ($_.PSIsContainer) {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
            } else {
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
            }
        } catch {
            Write-Log "Failed to remove: $($_.FullName) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Log "Folder cleaned (except .log files)." -ForegroundColor Green
} else {
    Write-Log "Skipping folder clean step." -ForegroundColor Cyan
}

while ($true) {
    Write-Host ""
    Write-Host "========= MAIN MENU ========="
    Write-Host "1. Generate CheckSum of Package.zip (On RPMPackage CoreCard Side)"
    Write-Host "2. Download package from S3 bucket, Match CheckSum of Package.zip and Extract Package.zip file"
    Write-Host "3. Copy Package to Staging dir"
    Write-Host "4. Match Package to Runtime Checksum"
    Write-Host "5. Exit"

    Write-Host "============================="

    do {
        $choice = Read-Host "Enter your choice (1/2/3/4/5)"
        if ($choice -notin @("1", "2", "3", "4", "5")) {        
            Write-log "  Invalid choice. Please enter 1, 2, 3, 4, or 5." -ForegroundColor Red
        }
    } while ($choice -notin @("1", "2", "3", "4", "5"))



    switch ($choice) {
# =========================================== Task 1 Generate hash of Package.zip (On CCPackage CoreCard Side) ==============================================================

        '1' {
                       
            
            do {
                $ccpackagepath = Read-Host "Enter the folder path (without 'Package.zip')"
                if (-not $ccpackagepath) {
                    Write-log "  Folder path cannot be empty." -ForegroundColor Red
                } elseif (-not (Test-Path $ccpackagepath)) {
                    Write-log "  Folder path does not exist: $ccpackagepath" -ForegroundColor Red
                    $ccpackagepath = $null
                }
            } while (-not $ccpackagepath)
            
            $hashOutputFile = "$ccpackagepath\CCpackage_hash_$timestamp.txt"            
            
            Write-Log "Task 1 Started - Generate hash of Package.zip (On CCPackage CoreCard Side)" -ForegroundColor Green
            Write-Log "Target path: $ccpackagepath"
            Write-Log "Output hash file: $hashOutputFile"

            $zipFile = Join-Path $ccpackagepath "Package.zip"

            if (Test-Path $zipFile) {
                Write-Log "Package.zip found at: $zipFile"
                try {
                    Write-Log "Computing SHA256 hash..."
                    $hash = Get-FileHash -Path $zipFile -Algorithm SHA256
                    $hash.Hash | Out-File -FilePath $hashOutputFile -Encoding utf8
                    Write-Log "SHA256 hash saved to file: $hashOutputFile"
                    Write-Log "Hash value: $($hash.Hash)"
                } catch {
                    Write-Log "ERROR: Failed to compute hash. Exception: $_" -ForegroundColor Red
                }
            } else {
                Write-Log "ERROR: Package.zip not found in path: $ccpackagepath" -ForegroundColor Red
            }

            Write-Log "==================== Task 1 completed ====================== `n"
        }

# =========================================== Task 2 Download package from S3 bucket and Match CheckSum of Package.zip =============================================

        '2' {               
            
               Write-Log "Task 2 Started - Download package from S3 bucket, Match CheckSum of Package.zip and Extract Package.zip file" -ForegroundColor Green                        
               
               $S3Bucketwithfilename = Read-Host "Enter the package s3 location (with package name)"              

               Write-Log "S3 Bucket name - $S3Bucketwithfilename"

               Write-Log "Downloading package from S3Bucket"
               aws s3 cp $S3Bucketwithfilename $Destinationpackagepath --quiet
               Start-Sleep -Seconds 5
               
               $packagezipfile = Get-ChildItem $Destinationpackagepath | Sort-Object LastWriteTime -Descending | Select-Object -First 1
               Start-Sleep -Seconds 5

               Write-Log "Unziping package - $packagezipfile"
               Expand-Archive "D:\Package\$packagezipfile" -DestinationPath "D:\Package" -Force
               Start-Sleep -Seconds 5

              
            do {                
                                
                $packageunzipfile = Get-ChildItem $Destinationpackagepath | Sort-Object LastWriteTime -Descending | Select-Object -First 1              
                $Lenoxpackagepath = "$Destinationpackagepath\$packageunzipfile"
                $LenoxhashOutputFile = "$Destinationpackagepath\$packageunzipfile\Lenoxpackage_hash_$timestamp.txt"

               Write-Log "Target path: $Lenoxpackagepath"
               Write-Log "Output hash file: $LenoxhashOutputFile"  

                if (-not $Lenoxpackagepath) {
                    Write-log "Folder path cannot be empty." -ForegroundColor Red
                } elseif (-not (Test-Path $Lenoxpackagepath)) {
                    Write-log "  Folder path does not exist: $Lenoxpackagepath" -ForegroundColor Red
                    $Lenoxpackagepath = $null
                }
            } while (-not $Lenoxpackagepath)

            $zipFile = Join-Path $Lenoxpackagepath "Package.zip"

            if (Test-Path $zipFile) {
                Write-Log "Package.zip found at: $zipFile"
                try {
                    Write-Log "Computing SHA256 hash..."
                    $hash = Get-FileHash -Path $zipFile -Algorithm SHA256
                    $hash.Hash | Out-File -FilePath $LenoxhashOutputFile -Encoding utf8
                    Write-Log "SHA256 hash saved to file: $LenoxhashOutputFile"
                    Write-Log "Hash value: $($hash.Hash)"
                } catch {
                    Write-Log "ERROR: Failed to compute hash. Exception: $_" -ForegroundColor Red
                }
            } else {
                Write-Log "ERROR: Package.zip not found in path: $Lenoxpackagepath" -ForegroundColor Red
            }

            Write-Log "Verifying against latest CC hash file..."

            $hashFolder = $Lenoxpackagepath

            $latestCCHash = Get-ChildItem -Path $hashFolder -Filter "CCpackage_hash_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $latestLenoxHash = Get-ChildItem -Path $hashFolder -Filter "Lenoxpackage_hash_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

            if (-not $latestCCHash -or -not $latestLenoxHash) {
                Write-Log "One or both hash files not found in $hashFolder" -ForegroundColor Red
                exit
            }

            Write-Log "Comparing:"
            Write-Log "  CC Hash File:     $($latestCCHash.FullName)"
            Write-Log "  Lenox Hash File:  $($latestLenoxHash.FullName)"

            $ccHashValue = Get-Content -Path $latestCCHash.FullName | Select-Object -First 1
            $lenoxHashValue = Get-Content -Path $latestLenoxHash.FullName | Select-Object -First 1

            Start-Sleep -Seconds 5

            if ($ccHashValue -eq $lenoxHashValue) {
                Write-Log "  Hashes MATCH" -ForegroundColor Green
            } else {
                Write-Log "  Hashes DO NOT MATCH" -ForegroundColor Red
                Write-Log "  CC Hash:     $ccHashValue"  -ForegroundColor Red
                Write-Log "  Lenox Hash:  $lenoxHashValue"  -ForegroundColor Red
                Write-Log "  Package.zip file corrupt"  -ForegroundColor Red
                exit
            }

            Write-Log "Download package from S3 bucket and Match CheckSum of Package.zip Task Completed `n" -ForegroundColor Cyan
            #Write-Log "==================== Task 2 completed ====================== `n"
            confirm-continue

# =========================================== Task 3 Extract Package.zip file ==============================================================
           
                Write-Log "Task - Extract Package.zip file" -ForegroundColor Green
                Write-Log "Target path: $Lenoxpackagepath" -ForegroundColor Green            

                function Extract-ZipRecursively {
                    param (
                        [string]$ZipPath,
                        [string]$ExtractPath
                    )
                
                    # Load zip library
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                
                    #Ensure destination exists
                    if (-not (Test-Path $ExtractPath)) {
                        New-Item -Path $ExtractPath -ItemType Directory | Out-Null
                    }
                
                    # Extract the main zip
                    Write-Log "`nExtracting main zip: $ZipPath to $ExtractPath"
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ExtractPath)
                
                    Write-Log "Recursively extract all nested zip files, except excluded ones"
                    Get-ChildItem -Path $ExtractPath -Recurse -Filter *.zip |
                    Where-Object { $_.Name -ne "CreditCloudStatementing.zip" } |
                    ForEach-Object {
                        $nestedZip = $_.FullName
                        $targetFolder = $_.Directory.FullName  # Extract in same folder
                
                        Write-Log "Extracting nested zip: $($_.Name) to $targetFolder"
                
                        try {
                            [System.IO.Compression.ZipFile]::ExtractToDirectory($nestedZip, $targetFolder) 
                            Start-Sleep -Seconds 5                          
                            Remove-Item $nestedZip -Force
                        } catch {
                            Write-Log "Failed to extract $($nestedZip): $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }                
            
            $mainZip =  "$($Lenoxpackagepath)\Package.zip"
            $extractTo = "D:\Package\UnZipPkg"
            
            Extract-ZipRecursively -ZipPath $mainZip -ExtractPath $extractTo

            Write-Log "Extract Package.zip file Task Completed `n" -ForegroundColor Cyan
          
           }

# =========================================== Task 4 Copy package to Staging dir ==============================================================

       '3' {

            Write-Log "Task 3 Started - Copy package to Staging dir" -ForegroundColor Green
            Write-Log "Package Location:- $Lenoxpackagepath" -ForegroundColor Green

            function Handle-CopyResult {
            param (
                [string]$Context = "File Copy"
            )
        
            switch ($LASTEXITCODE) {
                0 {
                    Write-Log "[$Context] No files were copied." -ForegroundColor Yellow
                    exit 1
                }
                1 {
                    Write-Log "[$Context] Files copied successfully." -ForegroundColor Green
                }
                2 {
                    Write-Log "[$Context] Extra files detected, but no new copies." -ForegroundColor Yellow
                    exit 1
                }
                3 {
                    Write-Log "[$Context] Files copied with some extra files." -ForegroundColor Green
                }
                default {
                    Write-Log "[$Context] An error occurred. Exit code: $LASTEXITCODE" -ForegroundColor Red
                    exit 1
                }
            }
            }


            function Show-MainMenu {
                Write-Host ""
                Write-Host "===== COPY MENU ====="
                Write-Host "1. APP_SETUP"
                Write-Host "2. WCF_SETUP"
                Write-Host "3. WEB_SETUP"
                Write-Host "4. EWEB_SETUP"
                Write-Host "5. KMS_SETUP"
                Write-Host "6. RPD_SETUP"
                Write-Host "99. Exit script"
                return (Read-Host "Enter your choice")
            }
            
            function Copy-AppSetup {
                $sourceBase = "D:\Package\UnZipPkg\Package"
                $appSetupMap = @{
                    "BatchScripts" = "C:\CopyFiles\APP_SETUP\DBBSetup\BatchScripts"
                    "DSLs"         = "C:\CopyFiles\APP_SETUP\DBBSetup\DSLs"
                    "CC_Python"    = "C:\CopyFiles\APP_SETUP\CC_Python"
                    "PlatformCode"   = "C:\CopyFiles\APP_SETUP\CC_runtime"
                    "TraceFiles"   = "C:\CopyFiles\APP_SETUP\TraceFiles"
                }
            
                foreach ($folder in $appSetupMap.Keys) {
                    $src = Join-Path $sourceBase $folder
                    $dst = $appSetupMap[$folder]
            
                    if (Test-Path $src) {
                        Write-Log "Copying '$folder' to '$dst'..."
                        robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP /MT:8 /R:1 /W:1
                        Handle-CopyResult -Context "Copying APP_SETUP Module"
                    } else {
                        Write-Log "Source folder not found: $folder" -ForegroundColor Yellow
                    }
                }
            
                Write-Log "APP_SETUP complete.`n" -ForegroundColor Green
            }
            
            function Copy-WCFSetup {
                $sourceBase = "D:\Package\UnZipPkg\Package"
                $wcfSetupMap = @{
                    "WCFServer" = "C:\CopyFiles\WCF_SETUP\WebServer"
                   
                }
            
                foreach ($folder in $wcfSetupMap.Keys) {
                    $src = Join-Path $sourceBase $folder
                    $dst = $wcfSetupMap[$folder]
            
                    if (Test-Path $src) {
                        Write-Log "Copying '$folder' to '$dst'..."
                        robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP /MT:8 /R:1 /W:1
                        Handle-CopyResult -Context "Copying WCF_SETUP Module"
                    } else {
                        Write-Log "Source folder not found: $folder" -ForegroundColor Yellow
                    }
                }
            
                Write-Log "WCF_SETUP complete.`n" -ForegroundColor Green
            }
            
            function Copy-WEBSetup {
                $sourceBase = "D:\Package\UnZipPkg\Package"
                $webSetupMap = @{
                    "WebServer" = "C:\CopyFiles\WEB_SETUP\WebServer"
                }
            
                foreach ($folder in $webSetupMap.Keys) {
                    $src = Join-Path $sourceBase $folder
                    $dst = $webSetupMap[$folder]
            
                    if (Test-Path $src) {
                        Write-Log "Copying '$folder' to '$dst'..."
                        robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP /MT:8 /R:1 /W:1
                        Handle-CopyResult -Context "Copying WEB_SETUP Module"
                    } else {
                        Write-Log "Source folder not found: $folder" -ForegroundColor Yellow
                    }
                }
            
                Write-Log "WEB_SETUP complete.`n" -ForegroundColor Green
            }
            
            function Copy-EWEBSetup {
                $sourceBase = "D:\Package\UnZipPkg\Package"
                $ewebSetupMap = @{        
                    "CoreCredit"   = "C:\CopyFiles\EWEB_SETUP\WebServer\CoreCredit"
                }
            
                foreach ($folder in $ewebSetupMap.Keys) {
                    $src = Join-Path $sourceBase $folder
                    $dst = $ewebSetupMap[$folder]
            
                    if (Test-Path $src) {
                        Write-Log "Copying '$folder' to '$dst'..."
                        robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP /MT:8 /R:1 /W:1
                        Handle-CopyResult -Context "Copying EWEB_SETUP Module"
                    } else {
                        Write-Log "Source folder not found: $folder" -ForegroundColor Yellow
                    }
                }
            
                Write-Log "EWEB_SETUP complete.`n" -ForegroundColor Green
            }
            
            function Copy-KMSSetup {
                $sourceBase = "D:\Package\UnZipPkg\Package"
                $kmsSetupMap = @{        
                    "KMS"   = "C:\CopyFiles\KMS_SETUP\KMS\"
                }
            
                foreach ($folder in $kmsSetupMap.Keys) {
                    $src = Join-Path $sourceBase $folder
                    $dst = $kmsSetupMap[$folder]
                    
            
                    if (Test-Path $src) {
                        Write-Log "Copying '$folder' to '$dst'..."
                        robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP /MT:8 /R:1 /W:1
                        Handle-CopyResult -Context "Copying KMS_SETUP Module"

                        } else {
                        Write-Log "Source folder not found: $folder" -ForegroundColor Yellow
                    }
                }
            
                Write-Log "KMS_SETUP complete.`n" -ForegroundColor Green
            }

            function Copy-RPDSetup {
                $sourceBase = "D:\Package\UnZipPkg\Package"
                $rpdSetupMap = @{        
                    "ReportDelivery"   = "C:\CopyFiles\RPD_SETUP\ReportDelivery\"
                    "DataFeed"   = "C:\CopyFiles\RPD_SETUP\DataFeed\"
                    "DataReports"   = "C:\CopyFiles\RPD_SETUP\DataReports\"
                    "CC_Python"   = "C:\CopyFiles\RPD_SETUP\CC_Python\"
                    "PlatformCode"   = "C:\CopyFiles\RPD_SETUP\PlatformCode\"
                }
            
                foreach ($folder in $rpdSetupMap.Keys) {
                    $src = Join-Path $sourceBase $folder
                    $dst = $rpdSetupMap[$folder]
                    
            
                    if (Test-Path $src) {
                        Write-Log "Copying '$folder' to '$dst'..."
                        robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP /MT:8 /R:1 /W:1
                        Handle-CopyResult -Context "Copying RPD_SETUP Module"

                        } else {
                        Write-Log "Source folder not found: $folder" -ForegroundColor Yellow
                    }
                }
            
                Write-Log "RPD_SETUP complete.`n" -ForegroundColor Green
            }
            
            # ========= MAIN EXECUTION LOOP =========
            Write-Log "Package Location: D:\Package\UnZipPkg\Package\" -ForegroundColor Cyan
            Write-Log "Task 4 Started - Copy package to Staging dir" -ForegroundColor Cyan
            
                 do {
                     $choice = Show-MainMenu
                 
                 if ($choice -in @("99", "exit", "no", "false")) {
                     Write-Log "Exiting script based on user input..."
                     $exitLoop = $true
                     continue
                 }
            
                switch ($choice) {
            
                    "1" {            
                        $serverName = $env:COMPUTERNAME.ToLower()            
                        if (($serverName -like "*SVC*") -or ($serverName -like "*iss*") -or ($serverName -like "*bat*") -or ($serverName -like "*aut*") -or ($serverName -like "*tnp*") -or ($serverName -like "*awf*") -or ($serverName -like "*src*") -or ($serverName -like "*snk*"))
                        {
                            Copy-AppSetup
                        } else {
                            Write-Log "Skipping APP_SETUP. Server '$serverName' is not authorized." -ForegroundColor Red
                            exit
                        }
                        
                        Remove-Variable serverName -ErrorAction SilentlyContinue
                    }
                  
                    "2" {            
                        $serverName = $env:COMPUTERNAME.ToLower()            
                        if ($serverName -like "*wcf*") {
                            Copy-WCFSetup
                        } else {
                            Write-Log "Skipping WCF_SETUP. Server '$serverName' is not authorized." -ForegroundColor Red
                            exit
                        }
                        
                        Remove-Variable serverName -ErrorAction SilentlyContinue
                    }
            
                    "3" {            
                        $serverName = $env:COMPUTERNAME.ToLower()            
                        if ($serverName -like "*web*") {
                            Copy-WEBSetup
                        } else {
                            Write-Log "Skipping WEB_SETUP. Server '$serverName' is not authorized." -ForegroundColor Red
                            exit
                        }
                        
                        Remove-Variable serverName -ErrorAction SilentlyContinue
                    }
            
                    "4" {            
                        $serverName = $env:COMPUTERNAME.ToLower()            
                        if ($serverName -like "*ewe*") {
                            Copy-EWEBSetup
                        } else {
                            Write-Log "Skipping EWEB_SETUP. Server '$serverName' is not authorized." -ForegroundColor Red
                            exit
                        }
                        
                        Remove-Variable serverName -ErrorAction SilentlyContinue
                    }
                    
                    "5" {            
                        $serverName = $env:COMPUTERNAME.ToLower()            
                        if ($serverName -like "*kms*") {
                            Copy-KMSSetup
                        } else {
                            Write-Log "Skipping KMS_SETUP. Server '$serverName' is not authorized." -ForegroundColor Red
                            exit
                        }
                        
                        Remove-Variable serverName -ErrorAction SilentlyContinue
                    }
                    
                    "6" {            
                        $serverName = $env:COMPUTERNAME.ToLower()            
                        if ($serverName -like "*rpd*") {
                            Copy-RPDSetup
                        } else {
                            Write-Log "Skipping RPD_SETUP. Server '$serverName' is not authorized." -ForegroundColor Red
                            exit
                        }
                        
                        Remove-Variable serverName -ErrorAction SilentlyContinue
                    }
                          
            
                    "99" {
                        Write-Log "Exiting script..." -ForegroundColor Magenta
                        exit
                    }
                }
            
                Start-Sleep -Seconds 1
            } while (-not $exitLoop)
            
            Write-Log "Copy package to Staging dir Task Completed `n" -ForegroundColor Cyan
            
            Write-Log "Match Package to staging checksum `n" -ForegroundColor Cyan
            confirm-continue
                           
         
# =========================================== Task 4 Match Package to staging checksum ==============================================================

                $Package_Path = $null                
                Write-Log "Task 3 - Match Package to staging checksum" -ForegroundColor Green
                Write-Log "Remote servers to be checked: $($ServerList -join ', ')" -ForegroundColor Cyan
                Write-Log "Package Location:- D:\Package\UnZipPkg\Package\" -ForegroundColor Green
            
              do {
                $Package_Path = "D:\Package\UnZipPkg\Package"
                if (-not $Package_Path) {
                    Write-Log "  Folder path cannot be empty." -ForegroundColor Red
                } elseif (-not (Test-Path $Package_Path)) {
                    Write-Log "  Folder path does not exist: $Package_Path" -ForegroundColor Red
                    $Package_Path = $null
                }
                } while (-not $Package_Path)

               

            $Global:summaryList = @()
            
            function CheckSum {
                param (
                    [string]$Staging_Path,
                    [string]$Package_Path,
                    [string]$ModuleName,
                    [string]$InstanceType,
                    [string[]]$ComputerNames
                )

                if (-not $ComputerNames) {
                    $ComputerNames = @($Global:InstanceTypeServers[$InstanceType])
                }
                $ServerCount = $ComputerNames.Count

                $Relative_Paths = Get-ChildItem -Path $Package_Path -Recurse -File | ForEach-Object {
                    $_.FullName.Replace($Package_Path, "")
                }

                if ($Relative_Paths.Length -eq 0) {
                    Write-Log "No files found in package path: $Package_Path" -ForegroundColor Yellow
                    $Global:summaryList += [pscustomobject]@{
                        InstanceType = $InstanceType
                        Module       = $ModuleName
                        ServerCount  = $ServerCount
                        Matched      = "-"
                        Mismatched   = "-"
                        NotFound     = "No files found"
                    }
                    return
                }

                if (-not $ComputerNames -or $ComputerNames.Count -eq 0) {
                    Write-Log "No remote servers available to check module: $ModuleName (Instance Type: $InstanceType)" -ForegroundColor Yellow
                    $Global:summaryList += [pscustomobject]@{
                        InstanceType = $InstanceType
                        Module       = $ModuleName
                        ServerCount  = 0
                        Matched      = "-"
                        Mismatched   = "-"
                        NotFound     = "No servers found"
                    }
                    return
                }

                $remoteHashesByServer = @{}
                $failedServers        = @()

                foreach ($server in $ComputerNames) {
                    Write-Log "`n----- Connecting to server: $server -----" -ForegroundColor Magenta

                    try {
                        $remoteHashesByServer[$server] = Invoke-Command -ComputerName $server -SessionOption $option -ScriptBlock {
                            param($BasePath, $RelPaths)
                            $results = @{}
                            foreach ($rp in $RelPaths) {
                                $fullPath = Join-Path $BasePath $rp
                                if (Test-Path $fullPath) {
                                    $results[$rp] = (Get-FileHash -Path $fullPath -Algorithm SHA256).Hash
                                } else {
                                    $results[$rp] = $null
                                }
                            }
                            return $results
                        } -ArgumentList $Staging_Path, $Relative_Paths -ErrorAction Stop
                    }
                    catch {
                        Write-Log "ERROR: Could not connect to $server - $($_.Exception.Message)" -ForegroundColor Red
                        $failedServers += $server
                    }
                }

                if ($failedServers.Count -eq $ComputerNames.Count) {
                   
                    $Global:summaryList += [pscustomobject]@{
                        InstanceType = $InstanceType
                        Module       = $ModuleName
                        ServerCount  = $ServerCount
                        Matched      = "-"
                        Mismatched   = "-"
                        NotFound     = "Connection Failed"
                    }
                    return
                }

                if ($failedServers.Count -gt 0) {
                    Write-Log "WARNING: Could not connect to: $($failedServers -join ', ') - excluded from checks below" -ForegroundColor Yellow
                }

                
                $matchedCount    = 0
                $mismatchedCount = 0
                $notFoundCount   = 0

                foreach ($Relative_Path in $Relative_Paths) {
                    $Package_File_Path = Join-Path $Package_Path $Relative_Path
                    $pkgHash = (Get-FileHash -Path $Package_File_Path -Algorithm SHA256).Hash

                    $missingOnServers    = @()
                    $mismatchedOnServers = @()

                    foreach ($server in $remoteHashesByServer.Keys) {
                        $remoteHash = $remoteHashesByServer[$server][$Relative_Path]
                        if ($null -eq $remoteHash) {
                            $missingOnServers += $server
                        }
                        elseif ($pkgHash -ne $remoteHash) {
                            $mismatchedOnServers += $server
                        }
                    }

                    if ($missingOnServers.Count -gt 0) {
                        Write-Log "[$ModuleName] Not found in staging on: $($missingOnServers -join ', ') - $Relative_Path" -ForegroundColor Yellow
                        $notFoundCount++
                    }
                    elseif ($mismatchedOnServers.Count -gt 0) {
                        Write-Log "[$ModuleName] Checksum mismatch on: $($mismatchedOnServers -join ', ') - $Relative_Path" -ForegroundColor Red
                        $mismatchedCount++
                    }
                    else {
                        Write-Log "[$ModuleName] Checksum matched on all servers - $Relative_Path" -ForegroundColor Green
                        $matchedCount++
                    }
                }

                Write-Log "`n===== CHECKSUM SUMMARY for $ModuleName ($InstanceType, $ServerCount server(s)) =====" -ForegroundColor Cyan
                Write-Log "Matched Files   : $matchedCount" -ForegroundColor Green
                Write-Log "Mismatched Files: $mismatchedCount" -ForegroundColor Red
                Write-Log "Not Found Files : $notFoundCount" -ForegroundColor Yellow
                Write-Log "====================================="

                $Global:summaryList += [pscustomobject]@{
                    InstanceType = $InstanceType
                    Module       = $ModuleName
                    ServerCount  = $ServerCount
                    Matched      = $matchedCount
                    Mismatched   = $mismatchedCount
                    NotFound     = $notFoundCount
                }
            }
            
            function Check-AppSetupModules {
                $basePackagePath = "D:\Package\UnZipPkg\Package"
                $appModules = @{
                        "BatchScripts" = "C:\CopyFiles\APP_SETUP\DBBSetup\BatchScripts"
                        "DSLs"         = "C:\CopyFiles\APP_SETUP\DBBSetup\DSLs"
                        "CC_Python"    = "C:\CopyFiles\APP_SETUP\CC_Python"
                        "PlatformCode" = "C:\CopyFiles\APP_SETUP\CC_runtime"
                        "TraceFiles"   = "C:\CopyFiles\APP_SETUP\TraceFiles"
                }
            
                foreach ($module in $appModules.Keys) {
                    $pkgPath = Join-Path $basePackagePath $module
                    $StagingPath = $appModules[$module]
                    Write-Log "`nChecking module: $module" -ForegroundColor Cyan
                    CheckSum -Staging_Path $StagingPath -Package_Path $pkgPath -ModuleName $module -InstanceType "Application"
                }
            }
            
            function Check-WCFModules {
                $basePackagePath = "D:\Package\UnZipPkg\Package"
                $wcfModules = @{
                        "WCFServer" = "C:\CopyFiles\WCF_SETUP\WebServer"                   
                }
            
                foreach ($module in $wcfModules.Keys) {
                    $pkgPath = Join-Path $basePackagePath $module
                    $StagingPath = $wcfModules[$module]
                    Write-Log "`nChecking WCF module: $module" -ForegroundColor Cyan
                    CheckSum -Staging_Path $StagingPath -Package_Path $pkgPath -ModuleName $module -InstanceType "WCF"
                }
            }
            
            function Check-WEBModules {
                $basePackagePath = "D:\Package\UnZipPkg\Package"
                $webModules = @{
                        "WebServer"  = "C:\CopyFiles\WEB_SETUP\WebServer"                        
                }
            
                foreach ($module in $webModules.Keys) {
                    $pkgPath = Join-Path $basePackagePath $module
                    $StagingPath = $webModules[$module]
                    Write-Log "`nChecking WEB module: $module" -ForegroundColor Cyan
                    CheckSum -Staging_Path $StagingPath -Package_Path $pkgPath -ModuleName $module -InstanceType "WEB"
                }
            }
            
            function Check-EWEB_SETUP {
                $basePackagePath = "D:\Package\UnZipPkg\Package"
                $ewebModules = @{
                        "CoreCredit"  = "C:\CopyFiles\WEB_SETUP\WebServer\CoreCredit"                        
                }
            
                foreach ($module in $ewebModules.Keys) {
                    $pkgPath = Join-Path $basePackagePath $module
                    $StagingPath = $ewebModules[$module]
                    Write-Log "`nChecking EWEB module: $module" -ForegroundColor Cyan
                    CheckSum -Staging_Path $StagingPath -Package_Path $pkgPath -ModuleName $module -InstanceType "Corecredit"
                }
            }
            
            function Check-KMS_SETUP {
                $basePackagePath = "D:\Package\UnZipPkg\Package"
                $kmsModules = @{
                        "KMS"  = "C:\CopyFiles\KMS_SETUP\KMS\"                        
                }
            
                foreach ($module in $kmsModules.Keys) {
                    $pkgPath = Join-Path $basePackagePath $module
                    $StagingPath = $kmsModules[$module]
                    Write-Log "`nChecking KMS module: $module" -ForegroundColor Cyan
                    CheckSum -Staging_Path $StagingPath -Package_Path $pkgPath -ModuleName $module -InstanceType "KMS"
                }
            }

            function Check-RPD_SETUP {
                $basePackagePath = "D:\Package\UnZipPkg\Package"
                $rpdModules = @{
                    "ReportDelivery"   = "C:\CopyFiles\RPD_SETUP\ReportDelivery\"
                    "DataFeed"   = "C:\CopyFiles\RPD_SETUP\DataFeed\"
                    "DataReports"   = "C:\CopyFiles\RPD_SETUP\DataReports\"
                    "CC_Python"   = "C:\CopyFiles\RPD_SETUP\CC_Python\"
                    "PlatformCode"   = "C:\CopyFiles\RPD_SETUP\PlatformCode\"                      
                }
            
                foreach ($module in $rpdModules.Keys) {
                    $pkgPath = Join-Path $basePackagePath $module
                    $StagingPath = $rpdModules[$module]
                    Write-Log "`nChecking RPD module: $module" -ForegroundColor Cyan
                    CheckSum -Staging_Path $StagingPath -Package_Path $pkgPath -ModuleName $module -InstanceType "Report Delivery"
                }
            }
            
            function Show-MainMenu {
                Write-Host ""
                Write-Host "===== CHECKSUM MENU ====="
                Write-Host "1. Check APP_SETUP modules"
                Write-Host "2. Check WCF_SETUP modules"
                Write-Host "3. Check WEB_SETUP modules"
                Write-Host "4. Check EWEB_SETUP modules"
                Write-Host "5. Check KMS_SETUP modules"
                Write-Host "6. Check RPD_SETUP modules"
                Write-Host "99. Exit script & verify Final summary"
                return (Read-Host "Enter your choice")
            }
            
            # ========== MAIN LOOP ==========
            
            Write-Log "Checksum Validation Started..." -ForegroundColor Cyan
            Write-Log "Package Path: D:\Package\UnZipPkg\Package" -ForegroundColor Cyan
            
            $exitLoop = $false
            
            do {
                $choice = Show-MainMenu
            
                if ($choice -in @("99", "exit", "no", "false")) {
                    Write-Log "Exiting script based on user input..."
                    $exitLoop = $true
                    continue
                }
            
                switch ($choice) {
                    "1" { Check-AppSetupModules }
                    "2" { Check-WCFModules }
                    "3" { Check-WEBModules }
                    "4" { Check-EWEB_SETUP }
                    "5" { Check-KMS_SETUP }
                    "6" { Check-RPD_SETUP }
                    "99" {
                        Write-Log "Exiting script..." -ForegroundColor Magenta
                        break
                    }
                    default {
                        Write-Log "Invalid choice. Please enter 1, 2, 3, or 99." -ForegroundColor Red
                    }
                }
            
                Start-Sleep -Seconds 1
            } while (-not $exitLoop)
            
            Write-Log "`n==================== Task 3 Match Package to staging checksum Task Completed ======================" -ForegroundColor Cyan
            
            # Final Summary Table - grouped by Instance Type, not server-wise
            Write-Log "`n===== FINAL SUMMARY =====" -ForegroundColor Cyan
            Write-FinalSummary
            
             Clear-Variable summaryList -Scope Global -ErrorAction SilentlyContinue

            }

# =========================================== Task 4 Match Package to Runtime Checksum ==============================================================

        '4' {
                Write-Log "Task 4 Started - Match Package to Runtime Checksum" -ForegroundColor Green
                Write-Log "Remote servers to be checked: $($ServerList -join ', ')" -ForegroundColor Cyan

                $Package_Path = $null
                do {
                $Package_Path = "D:\Package\UnZipPkg\Package"
                if (-not $Package_Path) {
                    Write-log "  Folder path cannot be empty." -ForegroundColor Red
                } elseif (-not (Test-Path $Package_Path)) {
                    Write-log "  Folder path does not exist: $Package_Path" -ForegroundColor Red
                    $Package_Path = $null
                }
                } while (-not $Package_Path)

               

                $Global:summaryList = @()

                function CheckSum {
                    param (
                        [string]$Runtime_Path,
                        [string]$Package_Path,
                        [string]$ModuleName,
                        [string]$InstanceType,
                        [string[]]$ComputerNames
                    )

                    
                    if (-not $ComputerNames) {
                        $ComputerNames = @($Global:InstanceTypeServers[$InstanceType])
                    }
                    $ServerCount = $ComputerNames.Count

                    $Relative_Paths = Get-ChildItem -Path $Package_Path -Recurse -File | ForEach-Object {
                        $_.FullName.Replace($Package_Path, "")
                    }

                    if ($Relative_Paths.Length -eq 0) {
                        Write-Log "No files found in package path: $Package_Path" -ForegroundColor Yellow
                        $Global:summaryList += [pscustomobject]@{
                            InstanceType = $InstanceType
                            Module       = $ModuleName
                            ServerCount  = $ServerCount
                            Matched      = "-"
                            Mismatched   = "-"
                            NotFound     = "No files found"
                        }
                        return
                    }

                    if (-not $ComputerNames -or $ComputerNames.Count -eq 0) {
                        Write-Log "No remote servers available to check module: $ModuleName (Instance Type: $InstanceType)" -ForegroundColor Yellow
                        $Global:summaryList += [pscustomobject]@{
                            InstanceType = $InstanceType
                            Module       = $ModuleName
                            ServerCount  = 0
                            Matched      = "-"
                            Mismatched   = "-"
                            NotFound     = "No servers found"
                        }
                        return
                    }

                    # Step 1: gather remote file hashes from every server in this Instance Type
                    $remoteHashesByServer = @{}
                    $failedServers        = @()

                    foreach ($server in $ComputerNames) {
                        Write-Log "`n----- Connecting to server: $server -----" -ForegroundColor Magenta

                        try {
                            $remoteHashesByServer[$server] = Invoke-Command -ComputerName $server -SessionOption $option -ScriptBlock {
                                param($BasePath, $RelPaths)
                                $results = @{}
                                foreach ($rp in $RelPaths) {
                                    $fullPath = Join-Path $BasePath $rp
                                    if (Test-Path $fullPath) {
                                        $results[$rp] = (Get-FileHash -Path $fullPath -Algorithm SHA256).Hash
                                    } else {
                                        $results[$rp] = $null
                                    }
                                }
                                return $results
                            } -ArgumentList $Runtime_Path, $Relative_Paths -ErrorAction Stop
                        }
                        catch {
                            Write-Log "ERROR: Could not connect to $server - $($_.Exception.Message)" -ForegroundColor Red
                            $failedServers += $server
                        }
                    }

                    if ($failedServers.Count -eq $ComputerNames.Count) {
                        # Every server for this module failed to connect - nothing was actually checked
                        $Global:summaryList += [pscustomobject]@{
                            InstanceType = $InstanceType
                            Module       = $ModuleName
                            ServerCount  = $ServerCount
                            Matched      = "-"
                            Mismatched   = "-"
                            NotFound     = "Connection Failed"
                        }
                        return
                    }

                    if ($failedServers.Count -gt 0) {
                        Write-Log "WARNING: Could not connect to: $($failedServers -join ', ') - excluded from checks below" -ForegroundColor Yellow
                    }

                    $matchedCount    = 0
                    $mismatchedCount = 0
                    $notFoundCount   = 0

                    foreach ($Relative_Path in $Relative_Paths) {
                        $Package_File_Path = Join-Path $Package_Path $Relative_Path
                        $pkgHash = (Get-FileHash -Path $Package_File_Path -Algorithm SHA256).Hash

                        $missingOnServers    = @()
                        $mismatchedOnServers = @()

                        foreach ($server in $remoteHashesByServer.Keys) {
                            $remoteHash = $remoteHashesByServer[$server][$Relative_Path]
                            if ($null -eq $remoteHash) {
                                $missingOnServers += $server
                            }
                            elseif ($pkgHash -ne $remoteHash) {
                                $mismatchedOnServers += $server
                            }
                        }

                        if ($missingOnServers.Count -gt 0) {
                            Write-Log "[$ModuleName] Not found in runtime on: $($missingOnServers -join ', ') - $Relative_Path" -ForegroundColor Yellow
                            $notFoundCount++
                        }
                        elseif ($mismatchedOnServers.Count -gt 0) {
                            Write-Log "[$ModuleName] Checksum mismatch on: $($mismatchedOnServers -join ', ') - $Relative_Path" -ForegroundColor Red
                            $mismatchedCount++
                        }
                        else {
                            Write-Log "[$ModuleName] Checksum matched on all servers - $Relative_Path" -ForegroundColor Green
                            $matchedCount++
                        }
                    }

                    Write-Log "`n===== CHECKSUM SUMMARY for $ModuleName ($InstanceType, $ServerCount server(s)) =====" -ForegroundColor Cyan
                    Write-Log "Matched Files   : $matchedCount" -ForegroundColor Green
                    Write-Log "Mismatched Files: $mismatchedCount" -ForegroundColor Red
                    Write-Log "Not Found Files : $notFoundCount" -ForegroundColor Yellow
                    Write-Log "====================================="

                    # One aggregated row per module (file-level counts, not multiplied by server count) - not server-wise
                    $Global:summaryList += [pscustomobject]@{
                        InstanceType = $InstanceType
                        Module       = $ModuleName
                        ServerCount  = $ServerCount
                        Matched      = $matchedCount
                        Mismatched   = $mismatchedCount
                        NotFound     = $notFoundCount
                    }
                }
                
                function Check-AppSetupModules {
                    $basePackagePath = "D:\Package\UnZipPkg\Package"
                    $appModules = @{
                        "BatchScripts" = "D:\DBBSetup\BatchScripts"
                        "DSLs"         = "D:\DBBSetup\DSLs"
                        "CC_Python"    = "D:\CC_Python"
                        "PlatformCode" = "D:\CC_runtime"
                        "TraceFiles"   = "D:\TraceFiles"
                    }
                
                    foreach ($module in $appModules.Keys) {
                        $pkgPath = Join-Path $basePackagePath $module
                        $RuntimePath = $appModules[$module]
                        Write-Log "`nChecking module: $module" -ForegroundColor Cyan
                        CheckSum -Runtime_Path $RuntimePath -Package_Path $pkgPath -ModuleName $module -InstanceType "Application"
                    }
                }
                
                function Check-WCFModules {
                    $basePackagePath = "D:\Package\UnZipPkg\Package"
                    $wcfModules = @{
                        "WCFServer" = "D:\WebServer"                        
                    }
                
                    foreach ($module in $wcfModules.Keys) {
                        $pkgPath = Join-Path $basePackagePath $module
                        $RuntimePath = $wcfModules[$module]
                        Write-Log "`nChecking WCF module: $module" -ForegroundColor Cyan
                        CheckSum -Runtime_Path $RuntimePath -Package_Path $pkgPath -ModuleName $module -InstanceType "WCF"
                    }
                }
                
                function Check-WEBModules {
                    $basePackagePath = "D:\Package\UnZipPkg\Package"
                    $webModules = @{
                        "WebServer" = "D:\WebServer"                        
                    }
                
                    foreach ($module in $webModules.Keys) {
                        $pkgPath = Join-Path $basePackagePath $module
                        $RuntimePath = $webModules[$module]
                        Write-Log "`nChecking WEB module: $module" -ForegroundColor Cyan
                        CheckSum -Runtime_Path $RuntimePath -Package_Path $pkgPath -ModuleName $module -InstanceType "WEB"
                    }
                }
                
                function Check-EWEB_SETUP {
                    $basePackagePath = "D:\Package\UnZipPkg\Package"
                    $ewebModules = @{
                        "CoreCredit" = "D:\WebServer\CoreCredit"                        
                    }
                
                    foreach ($module in $ewebModules.Keys) {
                        $pkgPath = Join-Path $basePackagePath $module
                        $RuntimePath = $ewebModules[$module]
                        Write-Log "`nChecking EWEB module: $module" -ForegroundColor Cyan
                        CheckSum -Runtime_Path $RuntimePath -Package_Path $pkgPath -ModuleName $module -InstanceType "Corecredit"
                    }
                }
                
                function Check-KMS_SETUP {
                    $basePackagePath = "D:\Package\UnZipPkg\Package"
                    $kmsModules = @{
                        "KMS" = "D:\KMS\"                        
                    }
                
                    foreach ($module in $kmsModules.Keys) {
                        $pkgPath = Join-Path $basePackagePath $module
                        $RuntimePath = $kmsModules[$module]
                        Write-Log "`nChecking KMS module: $module" -ForegroundColor Cyan
                        CheckSum -Runtime_Path $RuntimePath -Package_Path $pkgPath -ModuleName $module -InstanceType "KMS"
                    }
                }

                function Check-RPD_SETUP {
		$rpdModules = @{
        	        "ReportDelivery" = @{
            		PackagePath = "D:\Package\UnZipPkg\Package\ReportDelivery\ReportDelivery"
            		RuntimePath = "D:\ReportDelivery\ReportDelivery"
        	}
        		"DataFeed" = @{
           		 PackagePath = "D:\Package\UnZipPkg\Package\ReportDelivery\DataFeed"
            		 RuntimePath = "D:\ReportDelivery\DataFeed"
        	}
        		"DataReports" = @{
            		PackagePath = "D:\Package\UnZipPkg\Package\ReportDelivery\DataReports"
            		RuntimePath = "D:\ReportDelivery\DataReports"
        	}
        		"PlatformCode" = @{
            		 PackagePath = "D:\Package\UnZipPkg\Package\PlatformCode"
            		 RuntimePath = "D:\PlatformCode"
        	}
        		"CC_Python" = @{
            		 PackagePath = "D:\Package\UnZipPkg\Package\CC_Python"
            		 RuntimePath = "D:\CC_Python"
       	        }
            } 

    		 foreach ($module in $rpdModules.Keys) {
       			 Write-Log "`nChecking RPD module: $module" -ForegroundColor Cyan
        		CheckSum `
            		-Runtime_Path $rpdModules[$module].RuntimePath `
            		-Package_Path $rpdModules[$module].PackagePath `
            		-ModuleName $module `
            		-InstanceType "Report Delivery"
   	       }
	    }

                
                function Show-MainMenu {
                    Write-Host ""
                    Write-Host "===== CHECKSUM MENU ====="
                    Write-Host "1. Check APP_SETUP modules"
                    Write-Host "2. Check WCF_SETUP modules"
                    Write-Host "3. Check WEB_SETUP modules"
                    Write-Host "4. Check EWEB_SETUP modules"
                    Write-Host "5. Check KMS_SETUP modules"
                    Write-Host "6. Check RPD_SETUP modules"
                    Write-Host "99. Exit script & verify Final summary"
                    return (Read-Host "Enter your choice")
                }
                
                # ========== MAIN LOOP ==========
                
                Write-Log "Checksum Validation Started..." -ForegroundColor Cyan
                Write-Log "Package Path: D:\Package\UnZipPkg\Package" -ForegroundColor Cyan
                
                $exitLoop = $false
                
                do {
                    $choice = Show-MainMenu
                
                    if ($choice -in @("99", "exit", "no", "false")) {
                        Write-Log "Exiting script based on user input..."
                        $exitLoop = $true
                        continue
                    }
                
                    switch ($choice) {
                        "1" { Check-AppSetupModules }
                        "2" { Check-WCFModules }
                        "3" { Check-WEBModules }
                        "4" { Check-EWEB_SETUP }
                        "5" { Check-KMS_SETUP }
                        "6" { Check-RPD_SETUP }
                        "99" {
                            Write-Log "Exiting script..." -ForegroundColor Magenta
                            break
                        }
                        default {
                            Write-Log "Invalid choice. Please enter 1, 2, 3, or 99." -ForegroundColor Red
                        }
                    }
                
                    Start-Sleep -Seconds 1
                } while (-not $exitLoop)
                
                Write-Log "`n==================== Task 4 Match Package to Runtime Checksum Task Completed ======================" -ForegroundColor Cyan
                
                # Final Summary Table - grouped by Instance Type, not server-wise
                Write-Log "`n===== FINAL SUMMARY =====" -ForegroundColor Cyan
                Write-FinalSummary
                
                # Clean up
                Clear-Variable summaryList -Scope Global -ErrorAction SilentlyContinue

            }
         
# =========================================== Task 5 Exit ==============================================================

        '5' {
              Write-Log "Exiting script."
              exit

            }        
    
    }
    

    Write-log "`nPress Enter to return to the main menu..." -ForegroundColor Yellow
    Read-Host

}

Clear-Variable Lenoxpackagepath
Clear-Variable S3Bucketwithfilename
Clear-Variable Destinationpackagepath
Clear-Variable packagezipfile
Clear-Variable packageunzipfile
Clear-Variable LenoxhashOutputFile