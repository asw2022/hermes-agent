$ErrorActionPreference = "SilentlyContinue"
$pythonExe = "C:\Users\asw\ha-venv\Scripts\python.exe"
$scriptPath = "C:\Users\asw\dashboard_server.py"
$workDir = "C:\Users\asw"

# Kill any existing pythonw/dashboard processes
Get-Process -Name "pythonw","python" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -match "dashboard" -or $_.MainWindowTitle -match "dashboard"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

# Start in background using Start-Process
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $pythonExe
$psi.Arguments = $scriptPath
$psi.WorkingDirectory = $workDir
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$psi.CreateNoWindow = $true
$psi.UseShellExecute = $false

[System.Diagnostics.Process]::Start($psi) | Out-Null
Write-Host "Dashboard server started"

Start-Sleep -Seconds 8

# Test
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/ft/vol/up" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "Server OK: $($r.StatusCode) - $($r.Content)"
} catch {
    Write-Host "Server test: $_"
}
