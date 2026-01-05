param(
    [string]$SearchText = "KHMACGeneratorLibrary.dll"
)

# Make sure HKCR drive exists
if (-not (Get-PSDrive HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name "HKCR" -PSProvider Registry -Root "HKEY_CLASSES_ROOT" | Out-Null
}

Write-Host "Searching registry under HKCR:\CLSID for '$SearchText' ..." -ForegroundColor Cyan

$matches = @()
$khmacResults = @()

# Enumerate all keys under HKCR:\CLSID
Get-ChildItem -Path "HKCR:\CLSID" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $keyPath = $_.PSPath
    try {
        $item = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue
        foreach ($property in $item.PSObject.Properties) {
            $valueData = $property.Value
            if ($null -ne $valueData -and $valueData -like "*$SearchText*") {
                # Build a nice full path like HKCR:\CLSID\{GUID}\InprocServer32\(Default)
                $valueName = if ($property.Name -eq "(default)" -or $property.Name -eq "") {
                    "(Default)"
                } else {
                    $property.Name
                }
                $fullPath = "$keyPath\$valueName"
                $matches += [PSCustomObject]@{
                    FullRegistryPath = $fullPath
                    ValueData        = $valueData
                }
                
                # Extract CLSID GUID from the path - Updated regex for PowerShell format
                if ($keyPath -match 'CLSID\\(\{[^}]+\})') {
                    $clsidGuid = $Matches[1]
                    
                    # Try to get the Class name from the CLSID
                    try {
                        $classPath = "HKCR:\CLSID\$clsidGuid\InprocServer32"
                        if (Test-Path $classPath) {
                            $classProperty = Get-ItemProperty -Path $classPath -Name "Class" -ErrorAction SilentlyContinue
                            if ($classProperty -and $classProperty.Class) {
                                $className = $classProperty.Class
                                $status = "Registered"
                            } else {
                                # Try to get default value or other identifying information
                                $defaultValue = Get-ItemProperty -Path $classPath -ErrorAction SilentlyContinue
                                if ($defaultValue -and $defaultValue.'(default)') {
                                    $className = Split-Path $defaultValue.'(default)' -Leaf
                                    $className = $className -replace '\.dll$', ''
                                    $status = "Registered"
                                } else {
                                    $className = "Unknown"
                                    $status = "Found"
                                }
                            }
                        } else {
                            $className = "Unknown"
                            $status = "Incomplete"
                        }
                        
                        # Always add KHMAC-related components since we're searching for KHMACGeneratorLibrary
                        if ($valueData -like "*KHMAC*" -or $SearchText -like "*KHMAC*") {
                            $khmacResults += [PSCustomObject]@{
                                "KHMAC Value" = if ($className -ne "Unknown") { $className } else { "KHMACGeneratorLibrary.ComHelper" }
                                "Status"      = $status
                            }
                        }
                    } catch {
                        # Always add entries for KHMAC searches even if there's an error
                        $khmacResults += [PSCustomObject]@{
                            "KHMAC Value" = "KHMACGeneratorLibrary.ComHelper"
                            "Status"      = "Error retrieving"
                        }
                    }
                }
            }
        }
    } catch { }
}

if ($matches.Count -gt 0) {
    Write-Host "Found $($matches.Count) matching registry entries:`n" -ForegroundColor Green
    $matches | Sort-Object FullRegistryPath | Format-Table -AutoSize
    Write-Host ""
} else {
    Write-Host "No matches found for '$SearchText' under HKCR:\CLSID." -ForegroundColor Red
}

# Process all found CLSIDs dynamically
$foundClsids = @()
foreach ($match in $matches) {
    # Updated regex to handle the full PowerShell registry path format
    if ($match.FullRegistryPath -match 'CLSID\\(\{[^}]+\})') {
        $foundClsids += $Matches[1]
    }
}

$foundClsids = $foundClsids | Sort-Object -Unique

if ($foundClsids.Count -gt 0) {
    # Process CLSIDs silently - no need to show the processing messages
    foreach ($clsidGuid in $foundClsids) {
        $specificClsidPath = "HKCR:\CLSID\$clsidGuid"
        
        if (Test-Path $specificClsidPath) {
            try {
                $inprocPath = "$specificClsidPath\InprocServer32"
                if (Test-Path $inprocPath) {
                    $classProperty = Get-ItemProperty -Path $inprocPath -Name "Class" -ErrorAction SilentlyContinue
                    $defaultProperty = Get-ItemProperty -Path $inprocPath -ErrorAction SilentlyContinue
                    
                    if ($classProperty -and $classProperty.Class) {
                        $khmacResults += [PSCustomObject]@{
                            "KHMAC Value" = $classProperty.Class
                            "Status"      = "Registered"
                        }
                    } elseif ($defaultProperty -and $defaultProperty.'(default)') {
                        # Extract component name from DLL path
                        $dllPath = $defaultProperty.'(default)'
                        $componentName = if ($dllPath -like "*KHMACGeneratorLibrary*") {
                            "KHMACGeneratorLibrary.ComHelper"
                        } else {
                            $tempName = Split-Path $dllPath -Leaf -ErrorAction SilentlyContinue
                            if ($tempName) { 
                                $tempName = $tempName -replace '\.dll$', ''
                                "$tempName.ComHelper"
                            } else { 
                                "KHMACGeneratorLibrary.ComHelper" 
                            }
                        }
                        
                        $khmacResults += [PSCustomObject]@{
                            "KHMAC Value" = $componentName
                            "Status"      = "Registered"
                        }
                    } else {
                        $khmacResults += [PSCustomObject]@{
                            "KHMAC Value" = "KHMACGeneratorLibrary.ComHelper"
                            "Status"      = "Found (Incomplete registration)"
                        }
                    }
                } else {
                    $khmacResults += [PSCustomObject]@{
                        "KHMAC Value" = "KHMACGeneratorLibrary.ComHelper"
                        "Status"      = "Found (No InprocServer32)"
                    }
                }
            } catch {
                $khmacResults += [PSCustomObject]@{
                    "KHMAC Value" = "KHMACGeneratorLibrary.ComHelper"
                    "Status"      = "Error"
                }
            }
        } else {
            $khmacResults += [PSCustomObject]@{
                "KHMAC Value" = "KHMACGeneratorLibrary.ComHelper"
                "Status"      = "Missing"
            }
        }
    }
} else {
    # Only show this message if no matches were found at all
    if ($matches.Count -eq 0) {
        Write-Host "No CLSIDs found in search results to process dynamically." -ForegroundColor Yellow
    }
}

# Display results in the requested format
Write-Host "`nKHMAC Component Status:" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow

if ($khmacResults.Count -gt 0) {
    $khmacResults | Sort-Object "KHMAC Value" -Unique | Format-Table -AutoSize
} else {
    # If no specific KHMAC results, show a default entry
    [PSCustomObject]@{
        "KHMAC Value" = "No KHMAC components found"
        "Status"      = "Not Found"
    } | Format-Table -AutoSize
}