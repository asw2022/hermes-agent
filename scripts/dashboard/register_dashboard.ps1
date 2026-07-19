$ErrorActionPreference = "SilentlyContinue"

# Remove old tasks
Unregister-ScheduledTask -TaskName "SmartHomeDashboard" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "SmartHomeDash" -Confirm:$false -ErrorAction SilentlyContinue

# Create new task
$pythonw = "C:\Users\asw\ha-venv\Scripts\pythonw.exe"
$script = "C:\Users\asw\dashboard_server.py"
$workdir = "C:\Users\asw"

$action = New-ScheduledTaskAction -Execute $pythonw -Argument "`"$script`"" -WorkingDirectory $workdir
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest

Register-ScheduledTask -TaskName "SmartHomeDash" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "Task registered. Starting..."
Start-ScheduledTask -TaskName "SmartHomeDash"
Start-Sleep -Seconds 15

# Verify
$task = Get-ScheduledTask -TaskName "SmartHomeDash"
Write-Host "Task state: $($task.State)"

# Check process
$proc = Get-Process -Name "pythonw" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "pythonw running: PID $($proc.Id)"
} else {
    Write-Host "pythonw NOT found"
}

# Check port
$netstat = netstat -ano 2>$null | Select-String ":8090"
Write-Host "Port 8090: $netstat"

# Test HTTP
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "HTTP OK: $($r.StatusCode)"
} catch {
    Write-Host "HTTP: $_"
}

Write-Host "`nDone!"
