$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Podman Machine Init ==="
$result = podman machine init --cpus 2 --memory 2048 --disk-size 15 --now 2>&1
Write-Host $result

Write-Host ""
Write-Host "=== Podman Machine List ==="
podman machine list 2>&1

Write-Host ""
Write-Host "=== Waiting 30s for machine start ==="
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "=== Podman Info ==="
$result2 = podman info 2>&1
Write-Host $result2
