$task = Get-ScheduledTask -TaskName "SmartHomeDashboard" -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "Task found: $($task.State)"
    Start-ScheduledTask -TaskName "SmartHomeDashboard"
    Write-Host "Started. Waiting 10s..."
    Start-Sleep -Seconds 10
    
    try {
        $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/" -TimeoutSec 5 -ErrorAction Stop
        Write-Host "Server OK! $($r.StatusCode)"
    } catch {
        Write-Host "Server not ready: $_"
    }
    
    # Check processes
    Get-Process -Name "pythonw","python" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "PID $($_.Id): $($_.ProcessName)"
    }
} else {
    Write-Host "Task NOT found! Creating..."
    $action = New-ScheduledTaskAction -Execute "pythonw.exe" -Argument "C:\Users\asw\dashboard_server.py" -WorkingDirectory "C:\Users\asw"
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "SmartHomeDashboard" -Action $action -Trigger $trigger -Settings $settings -Force
    Write-Host "Created. Starting..."
    Start-ScheduledTask -TaskName "SmartHomeDashboard"
}
