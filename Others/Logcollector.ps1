Clear-Host
$ServerListFile = "D:\list.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire 
ForEach ($computername in $ServerList) { 
    
    $option = New-PSSessionOption -ProxyAccessType NoProxyServer 
    Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction inquire -ScriptBlock { 
        hostname         
        
$FolderName = "D:\Temp\PFlogs_$env:computername"
if (Test-Path $FolderName) {
 
    Write-Host "Folder Exists"
    Remove-Item $FolderName -Force
}
else
{
    Write-Host "Folder Doesn't Exists"
}
mkdir D:\Temp\PFlogs_$env:computername\

$EarliestModifiedTime = (Get-date).AddDays(0) #Chagne EarliestModifiedTime date
$NotOlderThanTime = (Get-date).AddDays(-2)    #Change NotOlderThanTime date


$PFfolder = "PFlogs_$env:computername.zip"

$Files = Get-ChildItem "D:\LOGs\DBBWEBHandlerLogs\*.*" #Chagne file path as per requirement.


foreach ($File in $Files)   
{  
       
      if (($File.CreationTime -lt $EarliestModifiedTime) -and ($File.CreationTime -gt $NotOlderThanTime))
      {  
         Copy-Item $File -Destination D:\Temp\PFlogs_$env:computername
          Write-Host "Copying $File"  
      }  
      else   
      {  
          Write-Host "Not copying $File"  
      }  
}  


Compress-Archive -Path D:\Temp\PFlogs_$env:computername -DestinationPath D:\Temp\PFlogs_$env:computername -Verbose -Force

aws s3 cp D:\Temp\$PFfolder s3://corecard-pod2-prod-us-west-2-config-files/Copy/Temp/
}
}

#Remove-Item D:\Temp 