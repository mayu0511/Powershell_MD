Write-Host "⚠️ Forcefully closing all SMB sessions and open files..." -ForegroundColor Red

# --- Close all open files ---
Get-SmbOpenFile | ForEach-Object {
    try {
        Close-SmbOpenFile -FileId $_.FileId -Force
        Write-Host "✅ Closed file: $($_.Path)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error closing file $($_.Path): $_" -ForegroundColor Yellow
    }
}

# --- Close all SMB sessions ---
Get-SmbSession | ForEach-Object {
    try {
        Close-SmbSession -SessionId $_.SessionId -Force
        Write-Host "✅ Closed session: $($_.ClientUserName) from $($_.ClientComputerName)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error closing session from $($_.ClientComputerName): $_" -ForegroundColor Yellow
    }
}

Write-Host "`n🚪 All SMB sessions and open files have been closed." -ForegroundColor Cyan
