$ShutdownEvent = Get-WinEvent -LogName "System" -FilterXPath "*[System[(EventID=1074)]]" | Sort-Object TimeCreated -Descending | Select-Object -First 1
$ShutdownTime