$Username = 'mahendra.dwivedi'
$XPathFilter = "*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4624)]] and *[EventData[Data[@Name='TargetUserName']='$Username']]"
$LogonEvents = Get-WinEvent -LogName "Security" -FilterXPath $XPathFilter
$LastLogonTime