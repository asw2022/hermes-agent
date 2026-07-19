$ErrorActionPreference = "SilentlyContinue"

# Delete old task
Unregister-ScheduledTask -TaskName "SmartHomeDashboard" -Confirm:$false -ErrorAction SilentlyContinue

# Create with full paths
$pythonw = "C:\Users\asw\ha-venv\Scripts\pythonw.exe"
$script = "C:\Users\asw\dashboard_server.py"
$workdir = "C:\Users\asw"

$action = New-ScheduledTaskAction -Execute $pythonw -Argument $script -WorkingDirectory $workdir
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Days 365)

Register-ScheduledTask -TaskName "SmartHomeDashboard" -Action $action -Trigger $trigger -Settings $settings -Force

Write-Host "Task created. Starting..."
Start-ScheduledTask -TaskName "SmartHomeDashboard"
Start-Sleep -Seconds 15

# Check
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/ft/keycode/24" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "Server OK: $($r.StatusCode) - $($r.Content)"
} catch {
    Write-Host "Server error: $_"
}

# Check pythonw process
Get-Process -Name "pythonw" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "pythonw PID: $($_.Id)"
}

# Also check if port 8080 is in use (maybe conflicting with OpenHAB?)
$netstat = netstat -ano | Select-String ":8090"
Write-Host "Port 8090: $netstat"
