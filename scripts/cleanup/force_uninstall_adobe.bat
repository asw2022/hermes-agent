@echo off
echo =============================================
echo Adobe CS3 - Force Uninstall via Installer Store Clean
echo =============================================
echo.

:: Check Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo FEHLER: Administrator-Rechte erforderlich!
    pause
    exit /b 1
)

echo Entferne Adobe CS3 aus dem Windows Installer Store...
echo.

:: Produkt-GUIDs entfernen aus HKLM\SOFTWARE\Classes\Installer\Products
for %%G in (
    "A2D81E70-2A98-4A08-A628-94388B063C5E"
    "73B5D990-04EA-4751-B10F-5534770B91F2"
    "B9B35331-B7E4-4E5C-BF4C-7BC87856124D"
    "90176341-0A8B-4CCC-A78D-F862228A6B95"
    "C2D69781-F392-4118-A5A7-C7E9C38DBFC2"
    "184CE391-7E0E-4C63-9935-D7A10EDFD3C6"
    "54793AA1-5001-42F4-ABB6-C364617C6078"
    "FF29A7E2-FF40-4D07-B7E4-2093DE59E10A"
    "8E6808E2-613D-4FCD-81A2-6C8FA8E03312"
    "29F05234-DCBB-4FE0-88DC-5160C9250312"
    "8D2BA474-F406-4710-9AE4-D4F22D21F0DD"
    "DD7DB3C5-6FA3-4FA3-8A71-C2F2940EB029"
    "E69AE897-9E0B-485C-8552-7841F48D42D8"
    "29E5EA97-5F74-4A57-B8B2-D4F169117183"
    "D2559B88-CC9D-4B48-81BB-F492BAA9C48C"
    "08B32819-6EEF-4057-AEDA-5AB681A36A23"
    "B3BF6689-A81D-40D8-9A86-4AC4ACD9FC1C"
    "802771A9-A856-4A41-ACF7-1450E523C923"
    "9C9824D9-9000-4373-A6A5-D0E5D4831394"
    "D0DFF92A-492E-4C40-B862-A74A173C25C5"
    "6FF5DD7A-FE28-4439-B8CF-1E9AF4EA0A61"
    "DADD7B8A-BCB0-44F5-967A-ECB6B4F2ECD9"
    "04AF207D-9A77-465A-8B76-991F6AB66245"
    "F01F79AD-1F47-4685-AE4E-CCFA4EA9FF7C"
    "A2B242BD-FF8D-4840-9DAA-9170EABEC59C"
    "6ABE0BEE-D572-4FE8-B434-9E72A289431B"
) do (
    echo Entferne Produkt %%G ...
    reg delete "HKLM\SOFTWARE\Classes\Installer\Products\%%G" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Installer\Products\%%G" /f >nul 2>&1
)

echo.
echo Entferne aus UpgradeCodes...
:: Adobe CS3 UpgradeCode
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\00C304D1-2F00-4754-8E5E-6595A0E7D9C2" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\18ABC01E-2FB9-4FB2-9649-1D84921FC8D9" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\5706662A-D30B-46B6-A252-71530E8112C6" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\67297EAD-5FDD-4D0C-BEA3-3C6A0FEDDFB8" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\79E6A112-74E2-4E14-BD84-2EBE955D0F3E" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\8E27AF4D-5A0A-4CE0-A6AA-9C1C4C16A3CE" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\E52CD7A8-C6D8-4819-94F4-F2CB0E48F32C" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Installer\UpgradeCodes\F3360C3F-1A9D-45B2-85E2-AD0BE1BB7A5E" /f >nul 2>&1

echo.
echo Entferne Adobe CS3 Patches...
reg delete "HKLM\SOFTWARE\Classes\Installer\Patches" /v "*" /f >nul 2>&1

echo.
echo Entferne Adobe CS3 Features...
reg delete "HKLM\SOFTWARE\Classes\Installer\Features" /v "*" /f >nul 2>&1

echo.
echo =============================================
echo Fertig! Bitte PC neu starten.
echo =============================================
pause
