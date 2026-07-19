@echo off
echo === Docker Desktop Restart Script ===

echo [1/4] Stopping Docker service...
net stop com.docker.service 2>nul
timeout /t 3 /nobreak >nul

echo [2/4] Killing Docker Desktop process...
taskkill /F /IM "Docker Desktop.exe" 2>nul
timeout /t 2 /nobreak >nul

echo [3/4] WSL shutdown...
wsl --shutdown 2>nul
timeout /t 5 /nobreak >nul

echo [4/4] Starting Docker service...
net start com.docker.service 2>nul
timeout /t 5 /nobreak >nul

echo Launching Docker Desktop...
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

echo Waiting 60s for daemon...
timeout /t 60 /nobreak >nul

echo Checking docker...
"C:\Program Files\Docker\Docker\resources\bin\docker.exe" info --format "ServerVersion: {{.ServerVersion}}" 2>nul
if %ERRORLEVEL% neq 0 echo Docker daemon NOT ready yet.

echo DONE
