######################################################################################################################
# Maintenance API | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | Initial Release | Date:: 16-Jan-2025
#=====================================================================================================================
$ServerListFile = "C:\ser.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction Stop
$FolderName = (Get-Date).ToString("ddMMyyyy")
$TargetPath = "E:\$FolderName"

foreach ($ComputerName in $ServerList) {
    Write-Host "Processing server: $ComputerName"

      $SessionOption = New-PSSessionOption -ProxyAccessType NoProxyServer

    try {
        Invoke-Command -ComputerName $ComputerName -SessionOption $SessionOption -ScriptBlock {
            param ($Path)

            if (-not (Test-Path -Path $Path)) {
                New-Item -Path $Path -ItemType Directory | Out-Null
                Write-Host "Folder created successfully: $Path"
            } else {
                Write-Host "Folder already exists: $Path"
            }
        } -ArgumentList $TargetPath -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to create folder on $ComputerName. Error: $_" -ForegroundColor Red
    }
}
