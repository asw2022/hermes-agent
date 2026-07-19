@echo off
echo =============================================
echo Adobe CS3 Deinstallation via Registry-Clean
echo =============================================
echo.

:: Check Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo FEHLER: Dieses Script braucht Administrator-Rechte.
    echo Rechtsklick -^> Als Administrator ausfuehren
    pause
    exit /b 1
)

echo Entferne Adobe CS3 Registry-Eintraege...

:: Adobe CS3 Product GUIDs - WOW6432Node (32-bit on 64-bit Windows)
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{A2D81E70-2A98-4A08-A628-94388B063C5E}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{73B5D990-04EA-4751-B10F-5534770B91F2}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{B9B35331-B7E4-4E5C-BF4C-7BC87856124D}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{90176341-0A8B-4CCC-A78D-F862228A6B95}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{C2D69781-F392-4118-A5A7-C7E9C38DBFC2}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{184CE391-7E0E-4C63-9935-D7A10EDFD3C6}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{54793AA1-5001-42F4-ABB6-C364617C6078}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{FF29A7E2-FF40-4D07-B7E4-2093DE59E10A}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{8E6808E2-613D-4FCD-81A2-6C8FA8E03312}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{29F05234-DCBB-4FE0-88DC-5160C9250312}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{8D2BA474-F406-4710-9AE4-D4F22D21F0DD}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{DD7DB3C5-6FA3-4FA3-8A71-C2F2940EB029}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{E69AE897-9E0B-485C-8552-7841F48D42D8}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{29E5EA97-5F74-4A57-B8B2-D4F169117183}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{D2559B88-CC9D-4B48-81BB-F492BAA9C48C}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{08B32819-6EEF-4057-AEDA-5AB681A36A23}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{B3BF6689-A81D-40D8-9A86-4AC4ACD9FC1C}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{802771A9-A856-4A41-ACF7-1450E523C923}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{9C9824D9-9000-4373-A6A5-D0E5D4831394}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{D0DFF92A-492E-4C40-B862-A74A173C25C5}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{6FF5DD7A-FE28-4439-B8CF-1E9AF4EA0A61}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{DADD7B8A-BCB0-44F5-967A-ECB6B4F2ECD9}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{04AF207D-9A77-465A-8B76-991F6AB66245}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{F01F79AD-1F47-4685-AE4E-CCFA4EA9FF7C}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{A2B242BD-FF8D-4840-9DAA-9170EABEC59C}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{6ABE0BEE-D572-4FE8-B434-9E72A289431B}" /f >nul 2>&1

echo Registry-Clean abgeschlossen.
echo.

:: Also try direct Uninstall paths
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{A2D81E70-2A98-4A08-A628-94388B063C5E}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B9B35331-B7E4-4E5C-BF4C-7BC87856124D}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{29F05234-DCBB-4FE0-88DC-5160C9250312}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{9C9824D9-9000-4373-A6A5-D0E5D4831394}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{D0DFF92A-492E-4C40-B862-A74A173C25C5}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F01F79AD-1F47-4685-AE4E-CCFA4EA9FF7C}" /f >nul 2>&1

echo.
echo =============================================
echo Adobe CS3 wurde entfernt.
echo Bitte starten Sie den PC neu.
echo =============================================
pause
