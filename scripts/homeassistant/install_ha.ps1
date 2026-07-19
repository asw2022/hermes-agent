# HA Installation Script
# Run with: powershell -NoProfile -File C:/Users/asw/install_ha.ps1

$ErrorActionPreference = "Stop"
$venvPath = "C:\Users\asw\ha-venv-py312"
$pipExe = "$venvPath\Scripts\pip.exe"

# Check if venv exists
if (-not (Test-Path $pipExe)) {
    Write-Output "Creating venv..."
    & "C:\Users\asw\AppData\Local\Programs\Python\Python312\python.exe" -m venv $venvPath
}

# Upgrade pip
Write-Output "Upgrading pip..."
& $pipExe install --upgrade pip 2>&1 | Out-String | Write-Output

# Install HA
Write-Output "Installing Home Assistant 2024.3.3..."
& $pipExe install homeassistant==2024.3.3 2>&1 | Out-String | Write-Output

# Verify
Write-Output "`n=== Verification ==="
& $pipExe show homeassistant 2>&1 | Out-String | Write-Output

Write-Output "`n=== Starting HA ==="
& "$venvPath\Scripts\hass.exe" --config "C:\Users\asw\.homeassistant" 2>&1 | Out-String | Write-Output
