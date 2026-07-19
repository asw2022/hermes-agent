$ErrorActionPreference = "SilentlyContinue"
$haConfig = "C:\Users\asw\.homeassistant"
$venvPy = "C:\Users\asw\ha-venv\Scripts\python.exe"
$logFile = "$haConfig\home-assistant.log"

# Ensure config dir exists
if (-not (Test-Path $haConfig)) {
    New-Item -ItemType Directory -Path $haConfig -Force | Out-Null
}

# Create basic config if not exists
$configYaml = "$haConfig\configuration.yaml"
if (-not (Test-Path $configYaml)) {
    @"
# Home Assistant Configuration
default_config:

# HTTP
http:
  server_host: 127.0.0.1
  server_port: 8123

# Logger
logger:
  default: warning
  logs:
    homeassistant: debug
"@ | Out-File -FilePath $configYaml -Encoding utf8
}

Write-Host "Starting HomeAssistant..."
Write-Host "Config: $haConfig"
Write-Host "Log: $logFile"

# Start HA in background
$env:PYTHONUNBUFFERED = "1"
Start-Process -FilePath $venvPy -ArgumentList "-m","homeassistant","--config",$haConfig,"--server-host","127.0.0.1","--server-port","8123" -WindowStyle Hidden

Write-Host "Started. Waiting 30s for startup..."
Start-Sleep -Seconds 30

Write-Host "Checking..."
$response = Invoke-WebRequest -Uri "http://127.0.0.1:8123/api/" -TimeoutSec 5 -ErrorAction SilentlyContinue
if ($response) {
    Write-Host "HA Status: $($response.StatusCode)"
} else {
    Write-Host "HA not ready yet"
}

Write-Host "`nLog output:"
if (Test-Path $logFile) {
    Get-Content $logFile -Tail 30
} else {
    Write-Host "No log file yet"
}
