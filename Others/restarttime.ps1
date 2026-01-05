$LastRestartEvent = Get-WinEvent -LogName System -FilterXPath "*[System[(EventID=6005)]]" | Select-Object -First 1
$LastRestartTime