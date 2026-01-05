
$ServerListFile = "D:\CC-Scripts\svc.txt"
$ServerList = Get-Content $ServerListFile -ErrorAction inquire

foreach ($server in $ServerList) {
    Write-Host "Checking shared folders on $server"
   
      $sharedFolders = Get-WmiObject Win32_Share -ComputerName $server -ErrorAction SilentlyContinue
  
    if ($sharedFolders) {
        Write-Host "Shared folders on $server"
       
        foreach ($folder in $sharedFolders) {
            Write-Host "  $($folder.Name) - $($folder.Path)"
        }
    } else {
        Write-Host "No shared folders found on $server"
    }
}