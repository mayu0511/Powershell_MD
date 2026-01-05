#---List of all the folder
Get-ChildItem -Recurse  "E:\mahendra" | Where { $_.PSIsContainer } | Select Name,FullName 
#----list of all the folder with size
Get-ChildItem -Recurse "E:\mahendra" | Where { ! $_.PSIsContainer } | Select Name,FullName,Length
#--With Output
Get-ChildItem -Path E:\Trace\Powershell -Recurse -Directory -ErrorAction SilentlyContinue | Select-Object FullName | Export-CSV c:\export.txt
#date wise and assending order
Get-ChildItem -Recurse "E:\Software\64-bit-2014-Assemblies" | Where { ! $_.PSIsContainer } | Select Name, FullName, Length, LastWriteTime | Sort-Object Name
# assending order
#Get-ChildItem -Recurse "E:\Software\64-bit-2014-Assemblies" | Where { ! $_.PSIsContainer } | Select Name,FullName,Length | Sort-Object Name
#date wise and assending order with MB size
Get-ChildItem -Recurse "E:\Software\64-bit-2014-Assemblies" | Where { ! $_.PSIsContainer } | Select Name, FullName, @{Name="SizeMB";Expression={"{0:N2}" -f ($_.Length / 1MB)}}, LastWriteTime | Sort-Object Name

