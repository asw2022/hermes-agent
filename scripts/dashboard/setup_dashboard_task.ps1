$ErrorActionPreference = "SilentlyContinue"

# Create scheduled task for dashboard
$action = New-ScheduledTaskAction -Execute "C:\Users\asw\ha-venv\Scripts\pythonw.exe" -Argument "C:\Users\asw\dashboard_server.py" -WorkingDirectory "C:\Users\asw"
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "SmartHomeDashboard" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

Write-Host "Task created. Starting..."
Start-ScheduledTask -TaskName "SmartHomeDashboard"
Start-Sleep -Seconds 5

# Test
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/ft/keycode/24" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "Server OK: $($r.Content)"
} catch {
    Write-Host "Server not ready yet: $_"
}
