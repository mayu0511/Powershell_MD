@echo off
cd /d "%~dp0"

set logFile=.\Log\VisualCron_Report_alert_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%.log

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0VisualCron_Report_alert.ps1" >> "%logFile%"



