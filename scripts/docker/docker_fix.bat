@echo off
echo === Docker Desktop Restart After Reboot ===

echo [1] WSL shutdown...
wsl --shutdown
timeout /t 5 /nobreak >nul

echo [2] Start Docker service...
net start com.docker.service 2>nul
timeout /t 10 /nobreak >nul

echo [3] Test docker...
"C:\Program Files\Docker\Docker\resources\bin\docker.exe" info --format "ServerVersion: {{.ServerVersion}}" 2>nul
if %ERRORLEVEL% equ 0 (
    echo DOCKER OK!
) else (
    echo Docker not ready yet, launching Docker Desktop GUI...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Waiting 90s...
    timeout /t 90 /nobreak >nul
    "C:\Program Files\Docker\Docker\resources\bin\docker.exe" info --format "ServerVersion: {{.ServerVersion}}" 2>nul
    if %ERRORLEVEL% equ 0 (echo DOCKER OK!) else (echo Docker STILL not ready...)
)

echo === DONE ===
pause
