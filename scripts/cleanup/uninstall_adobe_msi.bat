@echo off
echo =============================================
echo Adobe CS3 Deinstallation - MSI Method
echo =============================================
echo.

:: Check Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo FEHLER: Administrator-Rechte erforderlich!
    pause
    exit /b 1
)

set MSIDIR=%TEMP%\adobe_msi_cache
mkdir "%MSIDIR%" 2>nul

echo Entferne Adobe CS3 Produkte per msiexec...
echo.

call :uninst "Adobe Color - Photoshop Specific" "{A2D81E70-2A98-4A08-A628-94388B063C5E}"
call :uninst "Adobe Color EU Recommended Settings" "{73B5D990-04EA-4751-B10F-5534770B91F2}"
call :uninst "Adobe Default Language CS3" "{B9B35331-B7E4-4E5C-BF4C-7BC87856124D}"
call :uninst "Adobe Anchor Service CS3" "{90176341-0A8B-4CCC-A78D-F862228A6B95}"
call :uninst "Adobe ExtendScript Toolkit 2" "{C2D69781-F392-4118-A5A7-C7E9C38DBFC2}"
call :uninst "Adobe WinSoft Linguistics Plugin" "{184CE391-7E0E-4C63-9935-D7A10EDFD3C6}"
call :uninst "Adobe Linguistics CS3" "{54793AA1-5001-42F4-ABB6-C364617C6078}"
call :uninst "Adobe Color NA Extra Settings" "{FF29A7E2-FF40-4D07-B7E4-2093DE59E10A}"
call :uninst "Adobe Type Support" "{8E6808E2-613D-4FCD-81A2-6C8FA8E03312}"
call :uninst "Adobe Photoshop CS3" "{29F05234-DCBB-4FE0-88DC-5160C9250312}"
call :uninst "Adobe Device Central CS3" "{8D2BA474-F406-4710-9AE4-D4F22D21F0DD}"
call :uninst "Adobe Color JA Extra Settings" "{DD7DB3C5-6FA3-4FA3-8A71-C2F2940EB029}"
call :uninst "Adobe Update Manager CS3" "{E69AE897-9E0B-485C-8552-7841F48D42D8}"
call :uninst "Adobe Stock Photos CS3" "{29E5EA97-5F74-4A57-B8B2-D4F169117183}"
call :uninst "Adobe PDF Library Files" "{D2559B88-CC9D-4B48-81BB-F492BAA9C48C}"
call :uninst "Adobe Bridge Start Meeting" "{08B32819-6EEF-4057-AEDA-5AB681A36A23}"
call :uninst "Adobe Camera Raw 4.0" "{B3BF6689-A81D-40D8-9A86-4AC4ACD9FC1C}"
call :uninst "Adobe XMP Panels CS3" "{802771A9-A856-4A41-ACF7-1450E523C923}"
call :uninst "Adobe Bridge CS3" "{9C9824D9-9000-4373-A6A5-D0E5D4831394}"
call :uninst "Adobe Version Cue CS3 Client" "{D0DFF92A-492E-4C40-B862-A74A173C25C5}"
call :uninst "Adobe Asset Services CS3" "{6FF5DD7A-FE28-4439-B8CF-1E9AF4EA0A61}"
call :uninst "Adobe Color Common Settings" "{DADD7B8A-BCB0-44F5-967A-ECB6B4F2ECD9}"
call :uninst "Adobe Help Viewer CS3" "{04AF207D-9A77-465A-8B76-991F6AB66245}"
call :uninst "Adobe Setup" "{F01F79AD-1F47-4685-AE4E-CCFA4EA9FF7C}"
call :uninst "Adobe CMaps" "{A2B242BD-FF8D-4840-9DAA-9170EABEC59C}"
call :uninst "Adobe Fonts All" "{6ABE0BEE-D572-4FE8-B434-9E72A289431B}"

echo.
echo =============================================
echo Fertig! Alle Aufrufe abgeschlossen.
echo =============================================
pause
goto :eof

:uninst
echo Deinstalliere %~1...
msiexec /x %~2 /qn /norestart /l* "%MSIDIR%\%~2.log" 2>nul
if %errorlevel% equ 0 (
    echo   OK
) else if %errorlevel% equ 3010 (
    echo   OK (Neustart empfohlen)
) else (
    echo   Exit=%errorlevel%
)
goto :eof
