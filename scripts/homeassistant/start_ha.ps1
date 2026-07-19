$ErrorActionPreference = "SilentlyContinue"
$haConfig = "C:\Users\asw\.homeassistant"

if (-not (Test-Path $haConfig)) {
    New-Item -ItemType Directory -Path $haConfig -Force | Out-Null
}

Write-Host "=== Starting HomeAssistant ==="
Write-Host "Config: $haConfig"
Write-Host "First start takes 2-5 minutes..."
Write-Host ""

$venvPy = "C:\Users\asw\ha-venv\Scripts\python.exe"
$env:PYTHONPATH = "C:\Users\asw\ha-venv\Lib\site-packages"
$env:HASS_CONFIG_PATH = $haConfig

& $venvPy -m homeassistant --config $haConfig --server-host 127.0.0.1 --server-port 8123
