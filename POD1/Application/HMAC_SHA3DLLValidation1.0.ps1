######################################################################################################################
# HMAC + SHA3 DLL Validation 
# Initial Verion | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 |  HMAC + SHA3 DLL Validation |DEVELOPED BY:: Netra Chettri Date:: 13-April-2026
#=====================================================================================================================

param(
    [string[]]$SearchTexts = @("KHMACGeneratorLibrary.dll", "SHA3HashLibraryNet.dll")
)

# Make sure HKCR drive exists
if (-not (Get-PSDrive HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name "HKCR" -PSProvider Registry -Root "HKEY_CLASSES_ROOT" | Out-Null
}

# Summary collection
$finalSummary = @()
$serverName = $env:COMPUTERNAME

foreach ($SearchText in $SearchTexts) {

    Write-Host "`n=========================================" -ForegroundColor Cyan
    Write-Host "Processing: $SearchText" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan

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

                    # Extract CLSID GUID
                    if ($keyPath -match 'CLSID\\(\{[^}]+\})') {
                        $clsidGuid = $Matches[1]

                        try {
                            $classPath = "HKCR:\CLSID\$clsidGuid\InprocServer32"

                            if (Test-Path $classPath) {
                                $classProperty = Get-ItemProperty -Path $classPath -Name "Class" -ErrorAction SilentlyContinue

                                if ($classProperty -and $classProperty.Class) {
                                    $className = $classProperty.Class
                                    $status = "Registered"
                                } else {
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

                            $componentName = if ($SearchText -like "*SHA3*") {
                                "SHA3HashLibraryNet.ComHelper"
                            } else {
                                "KHMACGeneratorLibrary.ComHelper"
                            }

                            if ($valueData -like "*KHMAC*" -or $valueData -like "*SHA3*" -or $SearchText -like "*KHMAC*" -or $SearchText -like "*SHA3*") {
                                $khmacResults += [PSCustomObject]@{
                                    "KHMAC Value" = if ($className -ne "Unknown") { $className } else { $componentName }
                                    "Status"      = $status
                                }
                            }

                        } catch {
                            $componentName = if ($SearchText -like "*SHA3*") {
                                "SHA3HashLibraryNet.ComHelper"
                            } else {
                                "KHMACGeneratorLibrary.ComHelper"
                            }

                            $khmacResults += [PSCustomObject]@{
                                "KHMAC Value" = $componentName
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

    # Extract CLSIDs
    $foundClsids = @()
    foreach ($match in $matches) {
        if ($match.FullRegistryPath -match 'CLSID\\(\{[^}]+\})') {
            $foundClsids += $Matches[1]
        }
    }

    $foundClsids = $foundClsids | Sort-Object -Unique

    if ($foundClsids.Count -gt 0) {
        foreach ($clsidGuid in $foundClsids) {

            $componentName = if ($SearchText -like "*SHA3*") {
                "SHA3HashLibraryNet.ComHelper"
            } else {
                "KHMACGeneratorLibrary.ComHelper"
            }

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

                            $dllPath = $defaultProperty.'(default)'

                            $componentName = if ($dllPath -like "*SHA3HashLibraryNet*") {
                                "SHA3HashLibraryNet.ComHelper"
                            } elseif ($dllPath -like "*KHMACGeneratorLibrary*") {
                                "KHMACGeneratorLibrary.ComHelper"
                            } else {
                                $tempName = Split-Path $dllPath -Leaf -ErrorAction SilentlyContinue
                                if ($tempName) {
                                    ($tempName -replace '\.dll$', '') + ".ComHelper"
                                } else {
                                    $componentName
                                }
                            }

                            $khmacResults += [PSCustomObject]@{
                                "KHMAC Value" = $componentName
                                "Status"      = "Registered"
                            }
                        } else {
                            $khmacResults += [PSCustomObject]@{
                                "KHMAC Value" = $componentName
                                "Status"      = "Found (Incomplete registration)"
                            }
                        }
                    } else {
                        $khmacResults += [PSCustomObject]@{
                            "KHMAC Value" = $componentName
                            "Status"      = "Found (No InprocServer32)"
                        }
                    }
                } catch {
                    $khmacResults += [PSCustomObject]@{
                        "KHMAC Value" = $componentName
                        "Status"      = "Error"
                    }
                }
            } else {
                $khmacResults += [PSCustomObject]@{
                    "KHMAC Value" = $componentName
                    "Status"      = "Missing"
                }
            }
        }
    } else {
        if ($matches.Count -eq 0) {
            Write-Host "No CLSIDs found in search results to process dynamically." -ForegroundColor Yellow
        }
    }

    # Add to summary
    $componentType = if ($SearchText -like "*SHA3*") { "SHA3" } else { "KHMAC" }

    if ($khmacResults.Count -gt 0) {
        foreach ($res in ($khmacResults | Sort-Object "KHMAC Value" -Unique)) {
            $finalSummary += [PSCustomObject]@{
                ServerName = $serverName
                Component  = $componentType
                Value      = $res."KHMAC Value"
                Status     = $res.Status
            }
        }
    } else {
        $finalSummary += [PSCustomObject]@{
            ServerName = $serverName
            Component  = $componentType
            Value      = "Not Found"
            Status     = "Not Found"
        }
    }
}

# Final Summary Output
Write-Host "`n=========== FINAL SUMMARY ===========" -ForegroundColor Cyan
$finalSummary | Format-Table -AutoSize