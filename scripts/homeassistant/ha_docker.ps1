# HA Docker Installation
# Run with: powershell -NoProfile -File C:/Users/asw/ha_docker.ps1

$ErrorActionPreference = "Continue"

Write-Output "=== Pulling Home Assistant Docker Image ==="
docker pull ghcr.io/home-assistant/home-assistant:2024.3.3 2>&1 | Out-String | Write-Output

Write-Output "`n=== Checking existing containers ==="
docker ps -a --filter "name=homeassistant" --format "{{.Names}}: {{.Status}}" 2>&1 | Out-String | Write-Output

Write-Output "`n=== Starting HA Container ==="
# Remove old container if exists
docker rm -f homeassistant 2>&1 | Out-Null

# Start new container
$cmd = @(
    "docker", "run", "-d",
    "--name", "homeassistant",
    "--privileged",
    "--restart", "unless-stopped",
    "-p", "8123:8123",
    "-v", "C:\Users\asw\.homeassistant:/config",
    "-v", "/etc/localtime:/etc/localtime:ro",
    "--network", "host",
    "ghcr.io/home-assistant/home-assistant:2024.3.3"
)

& $cmd 2>&1 | Out-String | Write-Output

Write-Output "`n=== Waiting for startup ==="
Start-Sleep -Seconds 20

Write-Output "`n=== Checking status ==="
docker ps --filter "name=homeassistant" --format "{{.Names}}: {{.Status}}" 2>&1 | Out-String | Write-Output

Write-Output "`n=== Testing connection ==="
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:8123/api/" -TimeoutSec 10 -ErrorAction Stop
    Write-Output "HA is responding! Status: $($resp.StatusCode)"
} catch {
    Write-Output "HA not yet ready: $($_.Exception.Message)"
}

Write-Output "`n=== Docker logs (last 10 lines) ==="
docker logs --tail 10 homeassistant 2>&1 | Out-String | Write-Output
