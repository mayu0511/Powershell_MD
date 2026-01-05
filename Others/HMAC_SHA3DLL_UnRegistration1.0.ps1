# ------------------- Configuration -------------------
$hmacDllPath = "D:\DBBSetup\MonitoringScript\KHMACGeneratorLibrary\KHMACGeneratorLibrary.dll"
$sha3DllPath = "D:\DBBSetup\MonitoringScript\SHA3Library\SHA3HashLibraryNet.dll"

$regasm32 = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\regasm.exe"
$regasm64 = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\regasm.exe"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "C:\Temp\DLL_Unregistration_Log_$timestamp.txt"

# Create log directory if it doesn't exist
if (-not (Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory | Out-Null
}

# ------------------- Function to Unregister DLL -------------------
function Unregister-Dll {
    param (
        [string]$regasmPath,
        [string]$dllPath
    )

    $dllName = Split-Path -Path $dllPath -Leaf
    $logTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content $logFile "`n[$logTime] Unregistering: $dllName via $regasmPath"
    Write-Host "`n🔄 Unregistering: $dllPath" -ForegroundColor Cyan

    if (-Not (Test-Path $dllPath)) {
        $msg = "❌ DLL not found: $dllPath"
        Write-Host $msg -ForegroundColor Red
        Add-Content $logFile $msg
        return
    }

    if (-Not (Test-Path $regasmPath)) {
        $msg = "❌ regasm not found: $regasmPath"
        Write-Host $msg -ForegroundColor Red
        Add-Content $logFile $msg
        return
    }

    try {
        $process = Start-Process -FilePath $regasmPath `
                                 -ArgumentList "/unregister `"$dllPath`"" `
                                 -Wait -NoNewWindow -PassThru

        if ($process.ExitCode -eq 0) {
            $msg = "✅ Successfully unregistered: $dllPath"
            Write-Host $msg -ForegroundColor Green
            Add-Content $logFile $msg
        } else {
            $msg = "⚠️ Unregistration failed (Exit Code $($process.ExitCode))"
            Write-Host $msg -ForegroundColor DarkYellow
            Add-Content $logFile $msg
        }
    } catch {
        $err = "❌ Exception during unregistration: $($_.Exception.Message)"
        Write-Host $err -ForegroundColor Red
        Add-Content $logFile $err
    }
}

# ------------------- Main Execution -------------------
Write-Host "`n🧹 Starting DLL Unregistration Only..." -ForegroundColor Yellow
Add-Content $logFile "`n==== DLL Unregistration Log Started at $(Get-Date) ===="

# HMAC DLL
Unregister-Dll -regasmPath $regasm32 -dllPath $hmacDllPath
Unregister-Dll -regasmPath $regasm64 -dllPath $hmacDllPath

# SHA3 DLL
Unregister-Dll -regasmPath $regasm32 -dllPath $sha3DllPath
Unregister-Dll -regasmPath $regasm64 -dllPath $sha3DllPath

Add-Content $logFile "`n==== DLL Unregistration Completed at $(Get-Date) ===="
Write-Host "`n📄 Unregistration log saved to: $logFile" -ForegroundColor Yellow
