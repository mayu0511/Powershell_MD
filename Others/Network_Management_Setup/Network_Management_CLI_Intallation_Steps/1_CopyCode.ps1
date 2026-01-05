#Copy File
$ServerListFile = "D:\backup\LIST\servers.txt" 
$ServerList = Get-Content $ServerListFile -ErrorAction inquire
ForEach($computername in $ServerList)
{
write-host $computername
robocopy D:\WebServer\NetworkManagementAPI\ \\$computername\d$\WebServer\NetworkManagementAPI\ /e
#robocopy D:\LOGs\NetworkManagementAPI\ \\$computername\d$\LOGs\NetworkManagementAPI\ /e
mkdir D:\LOGs\NetworkManagementAPI 
robocopy D:\DotNetHostingBudle\ \\$computername\d$\DotNetHostingBudle\ /e
 
}