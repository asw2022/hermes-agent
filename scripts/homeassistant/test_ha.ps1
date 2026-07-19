$logFile = "C:\Users\asw\ha_startup.log"
$venvPy = "C:\Users\asw\ha-venv\Scripts\python.exe"
$haConfig = "C:\Users\asw\.homeassistant"

# Test 1: Can we import HA?
Write-Host "Test 1: Import HA..." | Tee-Object -FilePath $logFile
& $venvPy -c "import homeassistant; print('HA import OK, v' + homeassistant.__version__)" 2>&1 | Tee-Object -FilePath $logFile -Append

# Test 2: Can we validate config?
Write-Host "`nTest 2: Check config..." | Tee-Object -FilePath $logFile -Append
& $venvPy -m homeassistant --config $haConfig --script check_config 2>&1 | Tee-Object -FilePath $logFile -Append

# Test 3: Start HA briefly
Write-Host "`nTest 3: Start HA (10s)..." | Tee-Object -FilePath $logFile -Append
$proc = Start-Process -FilePath $venvPy -ArgumentList "-m","homeassistant","--config",$haConfig,"--server-host","127.0.0.1","--server-port","8123" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 10
$proc2 = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
if ($proc2) {
    Write-Host "HA process still running (PID $($proc2.Id))" | Tee-Object -FilePath $logFile -Append
    Stop-Process -Id $proc.Id -Force
} else {
    Write-Host "HA process exited!" | Tee-Object -FilePath $logFile -Append
}

Write-Host "`nDone. Check $logFile" | Tee-Object -FilePath $logFile -Append
