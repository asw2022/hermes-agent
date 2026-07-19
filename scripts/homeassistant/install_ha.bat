@echo off
echo === Installing HomeAssistant Core ===
echo This will take 5-15 minutes...
echo.

REM Create a dedicated venv for HA
C:\Users\asw\.local\bin\uv.exe venv C:\Users\asw\ha-venv
if %ERRORLEVEL% neq 0 (
    echo Failed to create venv
    exit /b 1
)

echo Activating venv...
call C:\Users\asw\ha-venv\Scripts\activate.bat

echo Installing HomeAssistant (this takes a while)...
C:\Users\asw\.local\bin\uv.exe pip install homeassistant
if %ERRORLEVEL% neq 0 (
    echo Install failed
    exit /b 1
)

echo.
echo === HA Installed Successfully! ===
echo.
echo To start HA:
echo   call C:\Users\asw\ha-venv\Scripts\activate.bat
echo   hass --config C:\Users\asw\.homeassistant
echo.
echo First start will take 2-5 minutes.
echo Web UI: http://127.0.0.1:8123
echo.
pause
