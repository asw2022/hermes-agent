$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== ADB Fire TV Stick Setup ==="

# Find adb
$adb = $null
$adbPaths = @(
    "C:\Users\asw\.local\bin\adb.exe",
    "C:\Program Files\Android\platform-tools\adb.exe", 
    "C:\platform-tools\adb.exe"
)
foreach ($p in $adbPaths) {
    if (Test-Path $p) { $adb = $p; break }
}

if (-not $adb) {
    $whereAdb = Get-Command adb.exe -ErrorAction SilentlyContinue
    if ($whereAdb) { $adb = $whereAdb.Source }
}

if ($adb) {
    Write-Host "ADB: $adb"
    
    Write-Host "`nConnecting to 192.168.0.136:5555..."
    & $adb connect 192.168.0.136:5555
    
    Write-Host "`nDevices:"
    & $adb devices -l
    
    Write-Host "`nDevice Info:"
    $model = & $adb -s 192.168.0.136:5555 shell getprop ro.product.model 2>$null
    Write-Host "Model: $model"
    $product = & $adb -s 192.168.0.136:5555 shell getprop ro.product.name 2>$null
    Write-Host "Product: $product"
    
    Write-Host "`nConnected TV Apps:"
    & $adb -s 192.168.0.136:5555 shell pm list packages 2>$null | Where-Object {
        $_ -match "amazon|fire|netflix|prime|kodi|youtube|plex|spotify|music|tv" | ForEach-Object { Write-Host "  $_" }
    }
} else {
    Write-Host "ADB not found! Installing via winget..."
    winget install --id Google.PlatformTools --accept-package-agreements --accept-source-agreements
    Write-Host "Please re-run this script after ADB installation."
}
