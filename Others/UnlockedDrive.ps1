$ServerListFile = "D:\CC_Scripts\Servers.txt"
 
try {
    $ServerList = Get-Content $ServerListFile -ErrorAction Stop
} catch {
    Write-Host "❌ Failed to read server list from $ServerListFile" -ForegroundColor Red
    exit
}
 
$option = New-PSSessionOption -ProxyAccessType NoProxyServer
 
foreach ($computername in $ServerList) {
    Write-Host "`n🔄 Processing: $computername" -ForegroundColor Cyan
 
    try {
        Invoke-Command -ComputerName $computername -SessionOption $option -ScriptBlock {
            try {
                Get-ChildItem -Path "D:\" -Recurse -ErrorAction Stop | Unblock-File
                Write-Host "✅ Files unblocked on $env:COMPUTERNAME" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to unblock files on $env:COMPUTERNAME - $_" -ForegroundColor Red
            }
        } -ErrorAction Stop
    } catch {
        Write-Host "❌ Connection failed for $computername - $_" -ForegroundColor Red
    }
}