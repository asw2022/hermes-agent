$ErrorActionPreference = "SilentlyContinue"

# Check Docker Desktop process
$dockerProc = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerProc) {
    Write-Host "Docker Desktop process found (PID $($dockerProc.Id))"
} else {
    Write-Host "Docker Desktop not running"
}

# Check Docker Desktop path
$ddPaths = @(
    "C:\Program Files\Docker\Docker\Docker Desktop.exe",
    "C:\Users\asw\AppData\Local\Docker\Docker Desktop.exe"
)
foreach ($p in $ddPaths) {
    if (Test-Path $p) {
        Write-Host "Docker Desktop exe: $p"
    }
}

# Check WSL
$wslStatus = wsl --status 2>&1
Write-Host "`nWSL Status: $wslStatus"

# Check if any WSL distros exist
$wslDistros = wsl --list --quiet 2>&1
Write-Host "WSL Distros: $wslDistros"
