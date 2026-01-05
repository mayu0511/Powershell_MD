Clear-Host
[xml]$Xml = Get-Content "ConfigDetails.xml" -Raw

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

function Write-Log {
    param([string]$Message,[ConsoleColor]$ForegroundColor = 'White')
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $ForegroundColor
}
function Upload-ToFTP {
    param([string]$LocalPath,[string]$RemotePath)
    try {
        Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

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
            Write-Host "Uploaded: $($e.FileName)" -ForegroundColor Green
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
    param([string]$RemoteFile,[string]$LocalPath)
    try {
        Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

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
            Write-Host "Downloaded: $($e.FileName)" -ForegroundColor Green
        })
        $session.Open($sessionOptions)

        Write-Host " Downloading ALL files and folders from $($FtpConfig.RemoteRoot)  $($LocalRoot)"

                $transferOptions = New-Object WinSCP.TransferOptions
                $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

            # ✅ Download recursively (all files/folders under RemoteRoot)
                $transferResult = $session.GetFiles(
                    "$($FtpConfig.RemoteRoot)/*",
                    "$($LocalRoot)\*",
                    $False,
                    $transferOptions
                )

                $transferResult.Check()

                foreach ($t in $transferResult.Transfers) {
                    Write-Host " Downloaded: $($t.FileName)"
                }

                $session.Dispose()
            }
            catch {
                Write-Log "❌ FTP Download failed: $_" Red
            }
}

# ============================
# Main Loop
# ============================
do {
    $MainChoice = Show-Menu -Title "Select Action" -Options @("Copy Files","Upload to FTP","Download from FTP", "Compare Environments","Exit")

    switch ($MainChoice) {
        "Copy Files" {
            $EnvChoices = Show-Menu -Title "Select Environment(s)" -Options @("DEV","QA","PTR","UATP","PERF","PROD","All")
            $SelectedEnvs = if ($EnvChoices -contains "All") { @("DEV","QA","PTR","UATP","PERF","PROD") } else { @($EnvChoices) }

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
                        Write-Log " No server defined for [$Module] in [$EnvName]" Yellow
                        continue
                    }

                    $DestinationPath = Join-Path $DestinationRoot "$EnvName\$StaticPath"
                    if (-not (Test-Path $DestinationPath)) {
                        New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null
                    }

                    Write-Log " Copying [$Module] files from [$ServerName] for Env [$EnvName]..." 
                    foreach ($File in $Files) {
                        $SourceFile = "\\$ServerName\D$\$BasePath\$File"
                        $RelativeFile = $File.TrimStart('\','/')
                        $TargetFile = Join-Path $DestinationPath $RelativeFile  
                        $TargetDir  = Split-Path $TargetFile -Parent

                        if (-not (Test-Path $TargetDir)) {
                            New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
                        }

                        try {
                            Copy-Item -Path $SourceFile -Destination $TargetFile -Force
                            Write-Log "Copied: $RelativeFile" -ForegroundColor Green
                        }
                        catch {
                            Write-Log " Failed to copy $RelativeFile ($_)" Yellow
                        }
                    }
                }
            }
        }
        "Upload to FTP" {
            $LocalRoot = Read-Host "Enter Local Path to Upload (e.g. $PSScriptRoot\Config-Comp)"
			# If user did not provide any input, set default
if ([string]::IsNullOrWhiteSpace($LocalRoot)) {
    $LocalRoot = Join-Path $PSScriptRoot "Config-Comp"
    Write-Host "No path entered. Using default: $LocalRoot" -ForegroundColor Yellow
}
            if (-not (Test-Path $LocalRoot)) {
                Write-Log "Path not found: $LocalRoot" Red
            } else {
                Get-ChildItem -Path $LocalRoot -Recurse -File | ForEach-Object {
                    $relativePath = $_.FullName.Substring($LocalRoot.Length).TrimStart('\')
                    $remotePath   = ($FtpConfig.RemoteRoot + "/" + ($relativePath -replace '\\','/'))
                    Upload-ToFTP -LocalPath $_.FullName -RemotePath $remotePath
                }
            }
        }
        "Download from FTP" {
		
		$LocalRoot = Read-Host "Enter Local Path to Download (e.g. $PSScriptRoot\Config-Comp)"
			# If user did not provide any input, set default
if ([string]::IsNullOrWhiteSpace($LocalRoot)) {
    $LocalRoot = Join-Path $PSScriptRoot "Config-Comp"
    Write-Host "No path entered. Using default: $LocalRoot" -ForegroundColor Yellow
}
            if (-not (Test-Path $LocalRoot)) {
                New-Item -ItemType Directory -Force -Path $LocalRoot | Out-Null
            }

           Download-FromFtp -LocalRoot $localPath -FtpConfig $FtpConfig
                
        }

        "Compare Environments" {
    # --- Ask user which two environments to compare ---
$envOptions = @("DEV","QA","PTR","UATP","PERF","PROD","Package")

$Env1Name = Show-Menu -Title "Select First Environment" -Options $envOptions
$Env2Name = Show-Menu -Title "Select Second Environment" -Options $envOptions

# --- Build paths dynamically from Download Root ---
$Env1Path = Join-Path $FtpConfig.DownloadRoot $Env1Name
$Env2Path = Join-Path $FtpConfig.DownloadRoot $Env2Name

$OutputHtml = "EnvDiffReport.html"

   # -------- Helpers --------
function Is-CommentLine {
    param ([string]$Line,[string]$FileExtension)
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

    $pairs = @{ }
    $fileName = [System.IO.Path]::GetFileName($FilePath)

    # ---- Setup files ----
    if ($fileName -match '^Setup.*\.bat$') {
        $section = "GLOBAL"
        foreach ($line in $Content) {
            $line = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($line) -or (Is-CommentLine -Line $line -FileExtension $FileExtension)) { continue }

            # Section [SECTION]
            if ($line -match '^\[(.+)\]$') {
                $section = $matches[1].Trim()
                $pairs["TAG::$section"] = @("TAG_PRESENT")
                continue
            }

            # Batch variable: SET VAR=VALUE
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

        # --- Capture start lines (existing logic) ---
        if ($line -match 'start\s+"?([^"]+)"?.*?cmd\s+/(c|k)\s+"?([^"]+)"?') {
            $title = $matches[1]
            $command = $matches[3]

            # Extract workflow name
            if ($command -match '-w\s+([\w_]+)') { $workflow = $matches[1] } else { $workflow = "" }
            # Extract executable
            if ($command -match '([\w\\]+\.exe)') { $exe = $matches[1] } else { $exe = "" }
            # Extract threads
            if ($command -match '-threads\s+(\d+)') { $threads = $matches[1] } else { $threads = "" }

            $key = "$section::$title"
            $value = "Exe=$exe; Workflow=$workflow; Threads=$threads"
            if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @() }
            $pairs[$key] += $value
        }

        # --- Capture menu echo lines ---
        elseif ($line -match '^\s*echo\s+\d+\s*=\s*(.+)$') {
            $key = "MENU::$($matches[1].Trim())"
            if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @() }
            $pairs[$key] += "MENU_PRESENT"
        }

        # --- Capture argument mappings (if %1==N goto XYZ) ---
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
                $section = $matches[1].Trim(); $pairs["TAG::$section"] = @("TAG_PRESENT"); continue 
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
    # Join text & strip namespace + xml declaration
    $text = ($Content -join "`n") -replace 'xmlns="[^"]*"', ''
    $text = $text -replace '<\?xml.*?\?>', ''      # Remove <?xml ... ?>
    $text = $text.Trim()

    # Use XmlReader to parse safely
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

            # --- Standard key/value ---
            if ($node.Name -eq "add" -and $node.Attributes["key"] -and $node.Attributes["value"]) {
                $k = "$nodePrefix::$($node.Attributes["key"].Value.Trim())"
                $v = $node.Attributes["value"].Value.Trim()
                $result[$k] = @($v)
            }

            # --- ConnectionStrings ---
            elseif ($node.Name -eq "add" -and $node.Attributes["name"] -and $node.Attributes["connectionString"]) {
                $k = "$nodePrefix::$($node.Attributes["name"].Value.Trim())"
                $v = $node.Attributes["connectionString"].Value.Trim()
                if ($node.Attributes["providerName"]) {
                    $v = "$v; ProviderName=$($node.Attributes["providerName"].Value.Trim())"
                }
                $result[$k] = @($v)
            }

            # --- Endpoints ---
            elseif ($node.Name -eq "endpoint" -and $node.Attributes["address"]) {
                $name = if ($node.Attributes["name"]) { $node.Attributes["name"].Value.Trim() } else { "UnnamedEndpoint" }
                $k = "$nodePrefix::$name"
                $v = "Address=$($node.Attributes["address"].Value); Binding=$($node.Attributes["binding"].Value); Contract=$($node.Attributes["contract"].Value)"
                $result[$k] = @($v)
            }

            # --- log4net logger ---
            elseif ($node.Name -eq "logger" -and $node.Attributes["name"]) {
                $k = "$nodePrefix::Logger"
                $v = $node.Attributes["name"].Value.Trim()
                $result[$k] = @($v)
            }

            # --- log4net appender ---
            elseif ($node.Name -eq "appender" -and $node.Attributes["name"]) {
                $name = $node.Attributes["name"].Value.Trim()
                $type = if ($node.Attributes["type"]) { $node.Attributes["type"].Value.Trim() } else { "Unknown" }
                $k = "$nodePrefix::Appender::$name"
                $v = "Type=$type"
                $result[$k] = @($v)
            }

            # --- log4net file path ---
            elseif ($node.Name -eq "file" -and $node.Attributes["value"]) {
                $k = "$nodePrefix::LogFile"
                $v = $node.Attributes["value"].Value.Trim()
                $result[$k] = @($v)
            }

            # --- log4net layout pattern ---
            elseif ($node.Name -eq "conversionPattern" -and $node.Attributes["value"]) {
                $k = "$nodePrefix::Layout"
                $v = $node.Attributes["value"].Value.Trim()
                $result[$k] = @($v)
            }

          # --- location blocks (serverPort, applicationName, virtloc, etc.) ---
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

            # --- Generic attributes ---
            foreach ($attr in $node.Attributes) {
                if ($null -ne $attr -and $attr.Name -notin @("key","value","providerName","name")) {
                    $k = "$nodePrefix::$($attr.Name)"
                    $v = $attr.Value.Trim()
                    if (-not $result.ContainsKey($k)) { $result[$k] = @() }
                    $result[$k] += $v
                }
            }

            # --- Capture text content ---
            if ($node.InnerText -and $node.ChildNodes.Count -eq 0 -and $node.InnerText.Trim() -ne "") {
                $k = "$nodePrefix::#text"
                $v = $node.InnerText.Trim()
                $result[$k] = @($v)
            }

            # --- Recurse ---
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
    # ---- Fallback for other text-based files ----
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
$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputHtml = "ENVConfigComparisonReport_$timestamp.html"

$outputPath = Join-Path $PSScriptRoot\Reports $OutputHtml
$outputDir  = Split-Path $outputPath -Parent

if (-not (Test-WriteAccess -Path $outputDir)) {
    Write-Warning "Cannot write to $outputDir. Using fallback."
    $outputPath = Join-Path "$env:USERPROFILE\Documents" $OutputHtml
    $outputDir  = Split-Path $outputPath -Parent
    if (-not (Test-WriteAccess -Path $outputDir)) {
        Write-Error "Cannot write to fallback path $outputPath."
        exit 1
    }
}


# -------- Gather files --------
$filesEnv1 = Get-ChildItem -Path $Env1Path -File -Recurse -ErrorAction SilentlyContinue
$filesEnv2 = Get-ChildItem -Path $Env2Path -File -Recurse -ErrorAction SilentlyContinue
if (-not $filesEnv1 -and -not $filesEnv2) {
    Write-Error "No files found in $Env1Path or $Env2Path."
    exit 1
}

$allFiles = ($filesEnv1.FullName.Replace($Env1Path, "").TrimStart('\') + $filesEnv2.FullName.Replace($Env2Path, "").TrimStart('\')) | Sort-Object -Unique

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
    .MISSING1 { background-color: #fff3cd; }
    .MISSING2 { background-color: #cce5ff; }
    .mono { white-space: pre-wrap; }
	.MATCHED { background-color: #d4edda; }
    .button-group button {
    margin: 2px;
    padding: 5px 10px;
    cursor: pointer;
}
</style>
</head>
<body>
    <h1>Environment File Comparison Report</h1>
    <h2>Comparing $Env1Name AND $Env2Name </h2>
"@

# -------- Compare files --------
foreach ($file in $allFiles) {
    $file1 = Join-Path $Env1Path $file
    $file2 = Join-Path $Env2Path $file

    $exists1 = Test-Path $file1
    $exists2 = Test-Path $file2

    if (-not $exists1) { $html += "<h2>$file → Missing in $Env1Name</h2>"; continue }
    if (-not $exists2) { $html += "<h2>$file → Missing in $Env2Name</h2>"; continue }

    try {
        $content1 = Get-Content $file1 -ErrorAction Stop
        $content2 = Get-Content $file2 -ErrorAction Stop
    } catch { continue }

    $ext = [System.IO.Path]::GetExtension($file)
    $pairs1 = Get-KeyValuePairs -Content $content1 -FileExtension $ext -FilePath $file1
    $pairs2 = Get-KeyValuePairs -Content $content2 -FileExtension $ext -FilePath $file2

    if ($pairs1.Count -eq 0 -and $pairs2.Count -eq 0) { continue }

    $allKeys = ($pairs1.Keys + $pairs2.Keys) | Sort-Object -Unique
    $hasRows = $false
    $rows = ""

    foreach ($key in $allKeys) {
        $v1 = if ($pairs1.ContainsKey($key)) { [string[]]$pairs1[$key] } else { @() }
        $v2 = if ($pairs2.ContainsKey($key)) { [string[]]$pairs2[$key] } else { @() }

        $s1 = ($v1 -join "`n")
        $s2 = ($v2 -join "`n")

       if ($s1 -eq "" -and $s2 -ne "") {
    $hasRows = $true
    $rows += "<tr class='MISSING1'><td>$key</td><td></td><td class='mono'>$([System.Net.WebUtility]::HtmlEncode($s2))</td><td>Missing in $Env1Name</td></tr>"
}
elseif ($s2 -eq "" -and $s1 -ne "") {
    $hasRows = $true
    $rows += "<tr class='MISSING2'><td>$key</td><td class='mono'>$([System.Net.WebUtility]::HtmlEncode($s1))</td><td></td><td>Missing in $Env2Name</td></tr>"
}
elseif ($s1 -ne $s2) {
    $hasRows = $true
    $rows += "<tr class='DIFF'><td>$key</td><td class='mono'>$([System.Net.WebUtility]::HtmlEncode($s1))</td><td class='mono'>$([System.Net.WebUtility]::HtmlEncode($s2))</td><td>Different</td></tr>"
}
else {
    $hasRows = $true
    $rows += "<tr class='MATCHED'><td>$key</td><td class='mono'>$([System.Net.WebUtility]::HtmlEncode($s1))</td><td class='mono'>$([System.Net.WebUtility]::HtmlEncode($s2))</td><td>Matched</td></tr>"
}

    }

   if ($hasRows) {
    $html += @"
<h2>File: $file</h2>
<div class="button-group">
    <button onclick="filterRows('MATCHED')">Show Matched</button>
    <button onclick="filterRows('DIFF')">Show Different</button>
    <button onclick="filterRows('MISSING1')">Missing in $Env1Name</button>
    <button onclick="filterRows('MISSING2')">Missing in $Env2Name</button>
    <button onclick="filterRows('ALL')">Show All</button>
</div>

<script>
function filterRows(status) {
    var rows = document.querySelectorAll("table tr");
    rows.forEach(function(row, index) {
        if(index === 0) return; // skip table header
        if(status === 'ALL') {
            row.style.display = '';
        } else if(row.classList.contains(status)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
}
</script>

<table>
    <tr><th>Key / Tag</th><th>$Env1Name</th><th>$Env2Name</th><th>Status</th></tr>
    $rows
</table>
"@
        }
    }


try {
    Set-Content -Path $outputPath -Value $html -Encoding UTF8 -ErrorAction Stop
    Write-Host "Environment Config & Setup Reports generated at: $outputPath" -ForegroundColor Green
}
catch { Write-Error "Failed to write report to $outputPath : $_" }

}

        "Exit" { break }
    }

    $again = if ($MainChoice -eq "Exit") { "N" } else { Read-Host "`nDo you want to perform another action? (Y/N)" }
}
while ($again -match '^(Y|y)$')

Write-Host "`n✅ Script finished. Goodbye!"
