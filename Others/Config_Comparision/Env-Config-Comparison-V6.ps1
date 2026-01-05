Clear-Host

# Validate ConfigDetails.xml existence
$ConfigFile = "ConfigDetails.xml"
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file '$ConfigFile' not found."
    exit 1
}

[xml]$Xml = Get-Content $ConfigFile -Raw -ErrorAction Stop

# Initialize ModuleMap
$ModuleMap = @{}

# Select all <Environment> nodes using XPath
$environments = $Xml.SelectNodes("//Configuration/Environments/Environment")

foreach ($env in $environments) {
    $envName = $env.GetAttribute("name")

    # Select all <Module> nodes inside this environment
    $modules = $env.SelectNodes("Modules/Module")
    foreach ($m in $modules) {
        $moduleName = $m.GetAttribute("name")

        # Initialize module if not exists
        if (-not $ModuleMap.ContainsKey($moduleName)) {
            $ModuleMap[$moduleName] = @{
                BasePath = @{}
                Files = @{}
                Servers = @{}
                StaticDestination = $m.SelectSingleNode("StaticDestination").InnerText
            }
        }

        # BasePath per environment
        $ModuleMap[$moduleName].BasePath[$envName] = $m.SelectSingleNode("BasePath").InnerText

        # Files per environment
        $fileNodes = $m.SelectNodes("Files/File")
        $ModuleMap[$moduleName].Files[$envName] = $fileNodes | ForEach-Object { $_.InnerText }

        # Servers per environment
        $ModuleMap[$moduleName].Servers[$envName] = $m.SelectSingleNode("Server").InnerText
    }
}

# FTP Config
$FtpConfig = @{
    Host = $Xml.SelectSingleNode("//FtpConfig/Host").InnerText
    User = $Xml.SelectSingleNode("//FtpConfig/User").InnerText
    Pass = $Xml.SelectSingleNode("//FtpConfig/Pass").InnerText
    RemoteRoot = $Xml.SelectSingleNode("//FtpConfig/RemoteRoot").InnerText
    DownloadRoot = Join-Path -Path $PSScriptRoot -ChildPath ($Xml.SelectSingleNode("//FtpConfig/DownloadRoot").InnerText)
}

# Validate DownloadRoot
if (-not (Test-Path $FtpConfig.DownloadRoot)) {
    New-Item -ItemType Directory -Force -Path $FtpConfig.DownloadRoot -ErrorAction Stop | Out-Null
}

function Write-Log {
    param([string]$Message, [ConsoleColor]$ForegroundColor = 'White')
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $ForegroundColor
}

function Show-Menu {
    param([string]$Title, [string[]]$Options)

    Write-Host "`n==== $Title ===="
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i+1). $($Options[$i])"
    }

    do {
        $choice = Read-Host "Enter choice [1-$($Options.Count)] (comma for multiple)"
    } while ($choice -notmatch '^\d+(,\d+)*$')

    $indices = $choice -split ',' | ForEach-Object { [int]$_ - 1 }
    return $indices | ForEach-Object { $Options[$_] }
}

function Upload-ToFTP {
    param([string]$LocalPath, [string]$RemotePath)
    try {
        Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll" -ErrorAction Stop
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol  = [WinSCP.Protocol]::Ftp
            HostName  = $FtpConfig.Host
            UserName  = $FtpConfig.User
            Password  = $FtpConfig.Pass
            FtpSecure = [WinSCP.FtpSecure]::Explicit
            GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
        }

        $session = New-Object WinSCP.Session
        $session.add_FileTransferred({
            param($sender, $e)
            Write-Log "Uploaded: $($e.FileName)" Green
        })
        $session.Open($sessionOptions)

        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

        $session.PutFiles($LocalPath, $RemotePath, $false, $transferOptions).Check()
        Write-Log "Uploaded $LocalPath → $RemotePath"
        $session.Dispose()
    }
    catch {
        Write-Log "Failed to upload $LocalPath : $_" Red
    }
}

function Download-FromFTP {
    param([string]$LocalRoot)
    try {
        Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll" -ErrorAction Stop
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol  = [WinSCP.Protocol]::Ftp
            HostName  = $FtpConfig.Host
            UserName  = $FtpConfig.User
            Password  = $FtpConfig.Pass
            FtpSecure = [WinSCP.FtpSecure]::Explicit
            GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
        }

        $session = New-Object WinSCP.Session
        $session.add_FileTransferred({
            param($sender, $e)
            Write-Log "Downloaded: $($e.FileName)" Green
        })
        $session.Open($sessionOptions)

        Write-Log "Downloading all files and folders from $($FtpConfig.RemoteRoot) to $LocalRoot"
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

        $transferResult = $session.GetFiles(
            "$($FtpConfig.RemoteRoot)/*",
            "$LocalRoot\*",
            $false,
            $transferOptions
        )

        $transferResult.Check()
        foreach ($t in $transferResult.Transfers) {
            Write-Log "Downloaded: $($t.FileName)"
        }
        $session.Dispose()
    }
    catch {
        Write-Log "FTP Download failed: $_" Red
    }
}

# ============================
# Main Loop
# ============================
do {
    $MainChoice = Show-Menu -Title "Select Action" -Options @("Copy Files", "Upload to FTP", "Download from FTP", "Compare Environments", "Exit")

    switch ($MainChoice) {
        "Copy Files" {
            $EnvChoices = Show-Menu -Title "Select Environment(s)" -Options @("DEV", "QA", "PTR", "UATP", "PERF", "PROD", "All")
            $SelectedEnvs = if ($EnvChoices -contains "All") { @("DEV", "QA", "PTR", "UATP", "PERF", "PROD") } else { @($EnvChoices) }

            $ModuleChoices = Show-Menu -Title "Select Module(s)" -Options ($ModuleMap.Keys + "All")
            $SelectedModules = if ($ModuleChoices -contains "All") { $ModuleMap.Keys } else { @($ModuleChoices) }

            $DestinationRoot = Read-Host "Enter Destination Root Folder (default: $PSScriptRoot\Config-Comp)"
            if ([string]::IsNullOrWhiteSpace($DestinationRoot)) { $DestinationRoot = "$PSScriptRoot\Config-Comp" }

            foreach ($EnvName in $SelectedEnvs) {
                foreach ($Module in $SelectedModules) {
                    $Config = $ModuleMap[$Module]

                    if ($Config.BasePath -is [hashtable]) {
                        $BasePath = $Config.BasePath[$EnvName]
                    } else {
                        $BasePath = $Config.BasePath -replace "ENV", $EnvName
                    }

                    $Files = @()
                    if ($Config.Files -is [hashtable]) {
                        if ($Config.Files.ContainsKey($EnvName)) {
                            $Files += $Config.Files[$EnvName]
                        }
                        if ($Config.Files.ContainsKey("COMMON")) {
                            $Files += $Config.Files["COMMON"]
                        }
                        if ($Config.Files.ContainsKey("ALL")) {
                            $Files += $Config.Files["ALL"]
                        }
                    } else {
                        $Files = $Config.Files
                    }
                    $ServerName = $Config.Servers[$EnvName]
                    $StaticPath = $Config.StaticDestination

                    if (-not $ServerName) {
                        Write-Log "No server defined for [$Module] in [$EnvName]" Yellow
                        continue
                    }

                    $DestinationPath = Join-Path $DestinationRoot "$EnvName\$StaticPath"
                    if (-not (Test-Path $DestinationPath)) {
                        New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null
                    }

                    Write-Log "Copying [$Module] files from [$ServerName] for Env [$EnvName]..."
                    foreach ($File in $Files) {
                        $SourceFile = "\\$ServerName\D$\$BasePath\$File"
                        $RelativeFile = $File.TrimStart('\', '/')
                        $TargetFile = Join-Path $DestinationPath $RelativeFile
                        $TargetDir = Split-Path $TargetFile -Parent

                        if (-not (Test-Path $TargetDir)) {
                            New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
                        }

                        try {
                            Copy-Item -Path $SourceFile -Destination $TargetFile -Force -ErrorAction Stop
                            Write-Log "Copied: $RelativeFile" Green
                        }
                        catch {
                            Write-Log "Failed to copy $RelativeFile ($_)" Yellow
                        }
                    }
                }
            }
        }
        "Upload to FTP" {
            $LocalRoot = Read-Host "Enter Local Path to Upload (e.g. $PSScriptRoot\Config-Comp)"
            if ([string]::IsNullOrWhiteSpace($LocalRoot)) {
                $LocalRoot = Join-Path $PSScriptRoot "Config-Comp"
                Write-Log "No path entered. Using default: $LocalRoot" Yellow
            }
            if (-not (Test-Path $LocalRoot)) {
                Write-Log "Path not found: $LocalRoot" Red
            } else {
                Get-ChildItem -Path $LocalRoot -Recurse -File | ForEach-Object {
                    $relativePath = $_.FullName.Substring($LocalRoot.Length).TrimStart('\')
                    $remotePath = ($FtpConfig.RemoteRoot + "/" + ($relativePath -replace '\\', '/'))
                    Upload-ToFTP -LocalPath $_.FullName -RemotePath $remotePath
                }
            }
        }
        "Download from FTP" {
            $LocalRoot = Read-Host "Enter Local Path to Download (e.g. $PSScriptRoot\Config-Comp)"
            if ([string]::IsNullOrWhiteSpace($LocalRoot)) {
                $LocalRoot = Join-Path $PSScriptRoot "Config-Comp"
                Write-Log "No path entered. Using default: $LocalRoot" Yellow
            }
            if (-not (Test-Path $LocalRoot)) {
                New-Item -ItemType Directory -Force -Path $LocalRoot | Out-Null
            }

            Download-FromFTP -LocalRoot $LocalRoot
        }
        "Compare Environments" {
            $envOptions = @("DEV", "QA", "PTR", "UATP", "PERF", "PROD", "Master", "All")
    $Env1Name = Show-Menu -Title "Select First Environment" -Options $envOptions
    $Env2Name = Show-Menu -Title "Select Second Environment" -Options $envOptions

    # --- Validate selected environments ---
    $SelectedEnvs = @($Env1Name, $Env2Name) | ForEach-Object { $_.Trim().ToUpper() }
$EnvPaths = @{}
    foreach ($env in $SelectedEnvs) {
        $EnvPaths[$env] = Join-Path $FtpConfig.DownloadRoot $env  # Similar to $Env1Path = Join-Path $FtpConfig.DownloadRoot $Env1Name
    }

            # -------- Helpers --------
            function Is-CommentLine {
                param ([string]$Line, [string]$FileExtension)
                $Line = $Line.Trim()
                if ([string]::IsNullOrWhiteSpace($Line)) { return $true }
                switch -Regex ($FileExtension.ToLower()) {
                    '\.bat|\.cmd'       { return $Line -match '^\s*(REM|::)' }
                    '\.ps1|\.py|\.ini'  { return $Line -match '^\s*(#|;)' }
                    '\.cs|\.cpp|\.java|\.js|\.ts' { return $Line -match '^\s*(//|/\*)' }
                    '\.xml|\.html|\.config' { return $Line -match '^\s*<!--' }
                    default { return $false }
                }
            }

            # -------- Parser --------
            function Get-KeyValuePairs {
                param (
                    [string[]]$Content,
                    [string]$FileExtension,
                    [string]$FilePath
                )

                $pairs = @{}
                $fileName = [System.IO.Path]::GetFileName($FilePath)

                # ---- Setup files ----
                if ($fileName -match '^Setup.*\.bat$') {
                    $section = "GLOBAL"
                    foreach ($line in $Content) {
                        $line = $line.Trim()
                        if ([string]::IsNullOrWhiteSpace($line) -or (Is-CommentLine -Line $line -FileExtension $FileExtension)) { continue }

                        if ($line -match '^\[(.+)\]$') {
                            $section = $matches[1].Trim()
                            $pairs["TAG::$section"] = @("TAG_PRESENT")
                            continue
                        }

                        if ($line -match '^(SET\s+)?([\w\.\-]+)=(.*)$') {
                            $key = "$section::$($matches[2].Trim())"
                            $value = $matches[3].Trim()
                            if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @() }
                            $pairs[$key] += $value
                        }
                    }
                    return $pairs
                }

                # ---- Runcc batch files ----
                if ($FileExtension -match '\.bat$|\.cmd$' -and ($Content -join "`n") -match '-w\s+\w+') {
                    $section = "RUNCC"
                    foreach ($line in $Content) {
                        $line = $line.Trim()
                        if ([string]::IsNullOrWhiteSpace($line) -or (Is-CommentLine -Line $line -FileExtension $FileExtension)) { continue }

                        if ($line -match 'start\s+"?([^"]+)"?.*?cmd\s+/(c|k)\s+"?([^"]+)"?') {
                            $title = $matches[1]
                            $command = $matches[3]

                            if ($command -match '-w\s+([\w_]+)') { $workflow = $matches[1] } else { $workflow = "" }
                            if ($command -match '([\w\\]+\.exe)') { $exe = $matches[1] } else { $exe = "" }
                            if ($command -match '-threads\s+(\d+)') { $threads = $matches[1] } else { $threads = "" }

                            $key = "$section::$title"
                            $value = "Exe=$exe; Workflow=$workflow; Threads=$threads"
                            if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @() }
                            $pairs[$key] += $value
                        }
                        elseif ($line -match '^\s*echo\s+\d+\s*=\s*(.+)$') {
                            $key = "MENU::$($matches[1].Trim())"
                            if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @() }
                            $pairs[$key] += "MENU_PRESENT"
                        }
                        elseif ($line -match '^\s*if\s+%1==(\d+)\s+goto\s+(\w+)$') {
                            $key = "ARG_MAPPING::%$($matches[1])%"
                            if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @() }
                            $pairs[$key] += $matches[2]
                        }
                    }
                    return $pairs
                }

                # ---- .ini files ----
                if ($FileExtension -eq ".ini") {
                    $section = "GLOBAL"
                    foreach ($line in $Content) {
                        $line = $line.Trim()
                        if ([string]::IsNullOrWhiteSpace($line) -or (Is-CommentLine -Line $line -FileExtension $FileExtension)) { continue }

                        if ($line -match '^\[(.+)\]$') {
                            $section = $matches[1].Trim()
                            $pairs["TAG::$section"] = @("TAG_PRESENT")
                            continue
                        }
                        if ($line -match '^\s*([\w\.\-]+)\s*(=|:|\s)\s*(.*)$') {
                            $key = "$section::$($matches[1].Trim())"
                            $value = $matches[3].Trim()
                            if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @() }
                            $pairs[$key] += $value
                        }
                    }
                    return $pairs
                }

                # ---- .config/.xml files ----
                if ($FileExtension -match '\.config$|\.xml$') {
                    $pairs = @{}
                    try {
                        $text = ($Content -join "`n") -replace 'xmlns="[^"]*"', '' -replace '<\?xml.*?\?>', ''
                        $text = $text.Trim()

                        $settings = New-Object System.Xml.XmlReaderSettings
                        $settings.IgnoreComments = $true
                        $settings.IgnoreWhitespace = $true

                        $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader $text), $settings)
                        $xml = New-Object System.Xml.XmlDocument
                        $xml.PreserveWhitespace = $false
                        $xml.Load($reader)

                        function Walk-Nodes {
                            param (
                                [System.Xml.XmlNode]$node,
                                [string]$prefix = ""
                            )
                            $result = @{}

                            if ($null -eq $node) { return $result }
                            if ($node.NodeType -eq [System.Xml.XmlNodeType]::Comment) { return $result }

                            $nodePrefix = if ($prefix) { "$prefix/$($node.Name)" } else { $node.Name }

                            if ($node.Name -eq "add" -and $node.Attributes["key"] -and $node.Attributes["value"]) {
                                $k = "$nodePrefix::$($node.Attributes["key"].Value.Trim())"
                                $v = $node.Attributes["value"].Value.Trim()
                                $result[$k] = @($v)
                            }
                            elseif ($node.Name -eq "add" -and $node.Attributes["name"] -and $node.Attributes["connectionString"]) {
                                $k = "$nodePrefix::$($node.Attributes["name"].Value.Trim())"
                                $v = $node.Attributes["connectionString"].Value.Trim()
                                if ($node.Attributes["providerName"]) {
                                    $v = "$v; ProviderName=$($node.Attributes["providerName"].Value.Trim())"
                                }
                                $result[$k] = @($v)
                            }
                            elseif ($node.Name -eq "endpoint" -and $node.Attributes["address"]) {
                                $name = if ($node.Attributes["name"]) { $node.Attributes["name"].Value.Trim() } else { "UnnamedEndpoint" }
                                $k = "$nodePrefix::$name"
                                $v = "Address=$($node.Attributes["address"].Value); Binding=$($node.Attributes["binding"].Value); Contract=$($node.Attributes["contract"].Value)"
                                $result[$k] = @($v)
                            }
                            elseif ($node.Name -eq "logger" -and $node.Attributes["name"]) {
                                $k = "$nodePrefix::Logger"
                                $v = $node.Attributes["name"].Value.Trim()
                                $result[$k] = @($v)
                            }
                            elseif ($node.Name -eq "appender" -and $node.Attributes["name"]) {
                                $name = $node.Attributes["name"].Value.Trim()
                                $type = if ($node.Attributes["type"]) { $node.Attributes["type"].Value.Trim() } else { "Unknown" }
                                $k = "$nodePrefix::Appender::$name"
                                $v = "Type=$type"
                                $result[$k] = @($v)
                            }
                            elseif ($node.Name -eq "file" -and $node.Attributes["value"]) {
                                $k = "$nodePrefix::LogFile"
                                $v = $node.Attributes["value"].Value.Trim()
                                $result[$k] = @($v)
                            }
                            elseif ($node.Name -eq "conversionPattern" -and $node.Attributes["value"]) {
                                $k = "$nodePrefix::Layout"
                                $v = $node.Attributes["value"].Value.Trim()
                                $result[$k] = @($v)
                            }
                            elseif ($node.Name -eq "location" -and $node.Attributes["path"]) {
                                $locPath = $node.Attributes["path"].Value.Trim()
                                $allowOverride = if ($node.Attributes["allowOverride"]) { $node.Attributes["allowOverride"].Value.Trim() } else { "" }
                                $locPrefix = "$nodePrefix[$locPath]"

                                $result["$locPrefix::allowOverride"] = @($allowOverride)

                                foreach ($child in $node.SelectNodes("appSettings/add")) {
                                    if ($child.Attributes["key"] -and $child.Attributes["value"]) {
                                        $k = "$locPrefix/$($child.Name)::$($child.Attributes["key"].Value.Trim())"
                                        $v = $child.Attributes["value"].Value.Trim()
                                        $result[$k] = @($v)
                                    }
                                }
                            }

                            foreach ($attr in $node.Attributes) {
                                if ($null -ne $attr -and $attr.Name -notin @("key", "value", "providerName", "name")) {
                                    $k = "$nodePrefix::$($attr.Name)"
                                    $v = $attr.Value.Trim()
                                    if (-not $result.ContainsKey($k)) { $result[$k] = @() }
                                    $result[$k] += $v
                                }
                            }

                            if ($node.InnerText -and $node.ChildNodes.Count -eq 0 -and $node.InnerText.Trim() -ne "") {
                                $k = "$nodePrefix::#text"
                                $v = $node.InnerText.Trim()
                                $result[$k] = @($v)
                            }

                            foreach ($child in $node.ChildNodes) {
                                if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                                    $childPairs = Walk-Nodes $child $nodePrefix
                                    foreach ($ck in $childPairs.Keys) { $result[$ck] = $childPairs[$ck] }
                                }
                            }

                            return $result
                        }

                        $pairs = Walk-Nodes $xml.DocumentElement
                    }
                    catch {
                        Write-Warning "Failed to parse XML in ${FilePath} : $_"
                    }
                }
                else {
                    $pairs = @{}
                    foreach ($line in $Content) {
                        $line = $line.Trim()
                        if ([string]::IsNullOrWhiteSpace($line) -or (Is-CommentLine -Line $line -FileExtension $FileExtension)) { continue }
                        if ($line -match '^\s*(set\s+)?([\w\.\-]+)\s*(=|:|\s)\s*(.*)$') {
                            $k = $matches[2].Trim()
                            $v = $matches[4].Trim()
                            if (-not $pairs.ContainsKey($k)) { $pairs[$k] = @() }
                            $pairs[$k] += $v
                        }
                    }
                }

                return $pairs
            }

            # -------- Test write access --------
            function Test-WriteAccess {
                param ([string]$Path)
                try {
                    $testFile = Join-Path $Path "test_$(New-Guid).txt"
                    Set-Content -Path $testFile -Value "test" -ErrorAction Stop
                    Remove-Item $testFile -ErrorAction Stop
                    return $true
                }
                catch { return $false }
            }

            # -------- Output path --------
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $outputDir = Join-Path $PSScriptRoot "Reports"
            $OutputHtml = "ENVConfigComparisonReport_$timestamp.html"
            $outputPath = Join-Path $outputDir $OutputHtml

            if (-not (Test-Path $outputDir)) {
                New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
            }
            if (-not (Test-WriteAccess -Path $outputDir)) {
                Write-Warning "Cannot write to $outputDir. Using fallback."
                $outputDir = Join-Path "$env:USERPROFILE\Documents" "Reports"
                $outputPath = Join-Path $outputDir $OutputHtml
                if (-not (Test-WriteAccess -Path $outputDir)) {
                    Write-Error "Cannot write to fallback path $outputDir."
                    continue
                }
            }

            # -------- Gather files --------
            $allFiles = @()
            foreach ($env in $SelectedEnvs) {
                $envPath = $EnvPaths[$env]
                if ([string]::IsNullOrWhiteSpace($envPath)) {
                    Write-Log "No valid path defined for environment $env." Yellow
                    continue
                }
                if (Test-Path $envPath -ErrorAction SilentlyContinue) {
                    $files = Get-ChildItem -Path $envPath -File -Recurse -ErrorAction SilentlyContinue
                    if ($files) {
                        $allFiles += $files.FullName | ForEach-Object { $_.Replace($envPath, "").TrimStart('\') }
                    } else {
                        Write-Log "No files found in $envPath for environment $env." Yellow
                    }
                } else {
                    Write-Log "Path not found for environment $env : $envPath" Yellow
                }
            }
            $allFiles = $allFiles | Sort-Object -Unique

            if (-not $allFiles) {
                Write-Log "No files found in the selected environments." Red
                continue
            }

            # -------- HTML start --------
            $html = @"
<html>
<head>
<meta charset="utf-8" />
<style>
    body { font-family: Arial; background: #f8f9fa; }
    h1 { background: #007bff; color: white; padding: 8px; }
    h2 { background: #17a2b8; color: white; padding: 5px; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
    th, td { border: 1px solid #ddd; padding: 6px; font-family: Consolas, monospace; vertical-align: top; }
    th { background-color: #343a40; color: white; }
    .DIFF { background-color: #f8d7da; }
    .MATCHED { background-color: #d4edda; }
    .mono { white-space: pre-wrap; }
    .button-group button {
        margin: 2px;
        padding: 5px 10px;
        cursor: pointer;
    }
"@
            # Add CSS for environment-specific MISSING classes
            foreach ($env in $SelectedEnvs) {
                $html += ".MISSING_$($env -replace '[^a-zA-Z0-9]', '_') { background-color: #fff3cd; }`n"
            }
            $html += "</style>`n</head>`n<body>`n"
            $html += "<h1>Environment File Comparison Report</h1>`n"
            $html += "<h2>Comparing: $($SelectedEnvs -join ', ')</h2>`n"

            # -------- Compare files --------
            foreach ($file in $allFiles) {
                # Collect file data for all selected environments
                $envPairs = @{}
                $fileExists = @{}
                foreach ($env in $SelectedEnvs) {
                    $filePath = Join-Path $EnvPaths[$env] $file
                    $fileExists[$env] = Test-Path $filePath -ErrorAction SilentlyContinue
                    if ($fileExists[$env]) {
                        try {
                            $content = Get-Content $filePath -ErrorAction Stop
                            $ext = [System.IO.Path]::GetExtension($file)
                            $envPairs[$env] = Get-KeyValuePairs -Content $content -FileExtension $ext -FilePath $filePath
                        } catch {
                            Write-Log "Failed to read file $file in $env : $_" Red
                            $envPairs[$env] = @{}
                        }
                    } else {
                        $envPairs[$env] = @{}
                    }
                }

                # Check if file is missing in any environment
                $missingEnvs = $SelectedEnvs | Where-Object { -not $fileExists[$_] }
                if ($missingEnvs) {
                    $html += "<h2>File: $file → Missing in $($missingEnvs -join ', ')</h2>`n"
                    continue
                }

                # Collect all keys that exist in at least one environment
                $allKeys = @()
                foreach ($env in $SelectedEnvs) {
                    if ($envPairs[$env]) {
                        $allKeys += $envPairs[$env].Keys
                    }
                }
                $allKeys = $allKeys | Sort-Object -Unique

                if (-not $allKeys) {
                    continue
                }

                # Generate comparison table
                $rows = ""
                $hasRows = $false
                foreach ($key in $allKeys) {
                    $values = @{}
                    $missingEnvs = @()
                    foreach ($env in $SelectedEnvs) {
                        if ($envPairs[$env].ContainsKey($key)) {
                            $values[$env] = $envPairs[$env][$key] -join "`n"
                        } else {
                            $values[$env] = ""
                            $missingEnvs += $env
                        }
                    }

                    # Only include keys that exist in at least one environment
                    $nonEmptyValues = $values.Values | Where-Object { $_ -ne "" }
                    if ($nonEmptyValues.Count -eq 0) {
                        continue  # Skip keys that don't exist in any environment
                    }

                    # Determine status
                    $uniqueNonEmptyValues = $nonEmptyValues | Select-Object -Unique
                    if ($uniqueNonEmptyValues.Count -eq 1 -and $missingEnvs.Count -eq 0) {
                        $status = "Matched"
                        $rowClass = "MATCHED"
                    } elseif ($missingEnvs.Count -gt 0) {
                        $status = "Missing in $($missingEnvs -join ', ')"
                        $rowClass = "MISSING"
                    } else {
                        $status = "Different"
                        $rowClass = "DIFF"
                    }

                    # Generate table row
                    $rowCells = $SelectedEnvs | ForEach-Object {
                        $envSafe = $_ -replace '[^a-zA-Z0-9]', '_'
                        $value = if ($values[$_] -eq "") { "<i>MISSING</i>" } else { [System.Net.WebUtility]::HtmlEncode($values[$_]) }
                        "<td class='mono $(if ($values[$_] -eq '') { 'MISSING_' + $envSafe } else { '' })'>$value</td>"
                    }
                    $rows += "<tr class='$rowClass'><td>$([System.Net.WebUtility]::HtmlEncode($key))</td>$($rowCells -join '')<td>$([System.Net.WebUtility]::HtmlEncode($status))</td></tr>`n"
                    $hasRows = $true
                }

                if ($hasRows) {
                    $html += "<h2>File: $file</h2>`n"
                    $html += "<div class='button-group'>`n"
                    $html += "<button onclick=`"filterRows('MATCHED')`">Show Matched</button>`n"
                    $html += "<button onclick=`"filterRows('DIFF')`">Show Different</button>`n"
                    # Add environment-specific missing buttons
                    foreach ($env in $SelectedEnvs) {
                        $envSafe = $env -replace '[^a-zA-Z0-9]', '_'
                        $html += "<button onclick=`"filterRows('MISSING_$envSafe')`">Missing in $env</button>`n"
                    }
                    $html += "<button onclick=`"filterRows('ALL')`">Show All</button>`n"
                    $html += "</div>`n"
                    $html += @"
<script>
function filterRows(status) {
    var rows = document.querySelectorAll("table tr");
    rows.forEach(function(row, index) {
        if (index === 0) return; // Skip header
        if (status === 'ALL') {
            row.style.display = '';
        } else if (status.startsWith('MISSING_')) {
            row.style.display = Array.from(row.cells).some(cell => cell.classList.contains(status)) ? '' : 'none';
        } else {
            row.style.display = row.classList.contains(status) ? '' : 'none';
        }
    });
}
</script>
<table>
<tr><th>Key / Tag</th>
"@
                    $html += ($SelectedEnvs | ForEach-Object { "<th>$_</th>" }) -join ''
                    $html += "<th>Status</th></tr>`n$rows</table>`n"
                }
            }

            # -------- HTML end --------
            $html += "</body></html>"

            if ($html -notmatch "<table") {
                $html += "<p>No differences found or no valid files available for comparison.</p>"
                Write-Log "No differences found or no valid files available for comparison." Yellow
            }

            try {
                Set-Content -Path $outputPath -Value $html -Encoding UTF8 -ErrorAction Stop
                Write-Log "Environment Config Comparison Report generated at: $outputPath" Green
            }
            catch {
                Write-Log "Failed to write report to $outputPath : $_" Red
            }
        }
        "Exit" { break }
    }

    $again = if ($MainChoice -eq "Exit") { "N" } else { Read-Host "`nDo you want to perform another action? (Y/N)" }
}
while ($again -match '^(Y|y)$')

Write-Log "Script finished. Goodbye!" Green