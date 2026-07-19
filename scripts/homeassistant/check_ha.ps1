$ErrorActionPreference = "SilentlyContinue"

# Check Home Assistant
Write-Host "=== HomeAssistant Check ==="

# 1. Check if HA service exists
$service = Get-Service -Name "HomeAssistant*" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "HA Service found: $($service.Name) - Status: $($service.Status)"
} else {
    Write-Host "No HA Windows Service found"
}

# 2. Check common HA paths
$haPaths = @(
    "C:\Users\asw\AppData\Roaming\hass",
    "C:\Users\asw\.homeassistant",
    "C:\ProgramData\hass",
    "C:\homeassistant", 
    "C:\hass",
    "C:\HASS"
)
foreach ($p in $haPaths) {
    if (Test-Path $p) {
        Write-Host "HA path found: $p"
    }
}

# 3. Check if HA is running (HA default port 8123)
$tcp = New-Object System.Net.Sockets.TcpClient
$connect = $tcp.BeginConnect("127.0.0.1", 8123, $null, $null)
$wait = $connect.AsyncWaitHandle.WaitOne(2000, $false)
if ($wait -and $tcp.Connected) {
    Write-Host "HA Web UI responding on port 8123"
    try {
        $tcp.Close()
    } catch {}
} else {
    Write-Host "NOT responding on port 8123"
}

# 4. Check Docker for HA
$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) {
    Write-Host ""
    Write-Host "=== Docker HA Check ==="
    $containers = docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>$null
    if ($containers -match "hass|home.assistant") {
        Write-Host "HA Docker container found:"
        $containers -split "`n" | Where-Object { $_ -match "hass|home.assistant" } | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "No HA Docker container running"
        Write-Host "All containers:"
        docker ps --format "{{.Names}} - {{.Status}}" 2>$null | ForEach-Object { Write-Host "  $_" }
    }
}

# 5. Check Python HA
$haCmd = Get-Command hass -ErrorAction SilentlyContinue
if ($haCmd) {
    Write-Host "hass command found: $($haCmd.Source)"
}

Write-Host ""
Write-Host "=== Done ==="
