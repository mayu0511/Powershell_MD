@echo off
cd /d "%~dp0"

set logFile=.\Log\ProcSetupFile-Validation_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%.log

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0SetupFile-Validation_1.0.ps1" >> "%logFile%"