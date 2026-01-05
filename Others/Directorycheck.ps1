Get-ChildItem -Path E:\Trace\Powershell -Recurse -Directory -ErrorAction SilentlyContinue | Select-Object FullName | Export-CSV c:\export.txt
