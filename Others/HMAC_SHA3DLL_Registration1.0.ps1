######################################################################################################################
# HMAC + SHA3 DLL Registration | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.3 |  HMAC + SHA3 DLL Registration | Date:: 19-July-2025
#=====================================================================================================================
# ------------------- Configuration -------------------
$hmacDllPath = "D:\DBBSetup\MonitoringScript\KHMACGeneratorLibrary\KHMACGeneratorLibrary.dll"
$sha3DllPath = "D:\DBBSetup\MonitoringScript\SHA3Library\SHA3HashLibraryNet.dll"

$regasm32 = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\regasm.exe"
$regasm64 = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\regasm.exe"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "C:\Temp\DLL_Registration_Log_$timestamp.txt"

# Create log directory if it doesn't exist
if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory | Out-Null
}

# ------------------- Function to Log and Register DLL -------------------
function Register-Dll {
    param (
        [string]$regasmPath,
        [string]$dllPath
    )

    $logHeader = "`n[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Trying: $regasmPath -> $dllPath"
    Add-Content -Path $logFile -Value $logHeader
    Write-Host $logHeader -ForegroundColor Cyan

    if (-Not (Test-Path $dllPath)) {
        $msg = "❌ DLL not found: $dllPath"
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Red
        return
    }

    if (-Not (Test-Path $regasmPath)) {
        $msg = "❌ regasm not found: $regasmPath"
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Red
        return
    }

    try {
        $process = Start-Process -FilePath $regasmPath `
                                 -ArgumentList "/codebase `"$dllPath`"" `
                                 -Wait -NoNewWindow -PassThru

        if ($process.ExitCode -eq 0) {
            $msg = "✅ Successfully registered: $dllPath"
            Add-Content -Path $logFile -Value $msg
            Write-Host $msg -ForegroundColor Green
        } else {
            $msg = "❌ Failed to register (Exit Code $($process.ExitCode)): $dllPath"
            Add-Content -Path $logFile -Value $msg
            Write-Host $msg -ForegroundColor Red
        }
    } catch {
        $msg = "❌ Exception while registering: $($_.Exception.Message)"
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Red
    }
}

# ------------------- Main Execution -------------------
Write-Host "`n🔧 Starting DLL Registration with Logging..." -ForegroundColor Yellow
Add-Content -Path $logFile -Value "`n==== DLL Registration Log Started at $(Get-Date) ===="

# HMAC Library
Register-Dll -regasmPath $regasm32 -dllPath $hmacDllPath
Register-Dll -regasmPath $regasm64 -dllPath $hmacDllPath

# SHA3 Library
Register-Dll -regasmPath $regasm32 -dllPath $sha3DllPath
Register-Dll -regasmPath $regasm64 -dllPath $sha3DllPath

Add-Content -Path $logFile -Value "`n==== DLL Registration Completed at $(Get-Date) ===="
Write-Host "`n📄 Log saved to: $logFile" -ForegroundColor Yellow
