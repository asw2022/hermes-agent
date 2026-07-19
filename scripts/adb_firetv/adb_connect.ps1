$ErrorActionPreference = "SilentlyContinue"
$adb = "C:\platform-tools\platform-tools\adb.exe"

if (Test-Path $adb) {
    Write-Host "ADB found: $adb"
    & $adb version
    Write-Host ""
    Write-Host "Connecting to Fire TV Stick 192.168.0.136:5555..."
    & $adb connect 192.168.0.136:5555
    Write-Host ""
    & $adb devices -l
    Write-Host ""
    Write-Host "Device Info:"
    & $adb -s 192.168.0.136:5555 shell getprop ro.product.model
    & $adb -s 192.168.0.136:5555 shell getprop ro.product.brand
    & $adb -s 192.168.0.136:5555 shell getprop ro.build.version.release
} else {
    Write-Host "ADB NOT found, checking directory..."
    Get-ChildItem "C:\platform-tools" -Recurse -Filter "adb.exe" | ForEach-Object { Write-Host $_.FullName }
}
