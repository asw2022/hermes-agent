
@echo off
setlocal EnableDelayedExpansion
for /d %%i in ("C:\Users\asw\*") do (
    set "dir=%%i"
    for /f "tokens=3" %%a in ('dir /s /a:-d "%%i" 2^>nul ^| find "Datei(en)"') do (
        set "size=%%a"
        set "size=!size:,=!"
        echo !size! MB  %%i
    )
)
