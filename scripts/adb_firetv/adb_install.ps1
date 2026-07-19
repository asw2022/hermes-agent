$ErrorActionPreference = "SilentlyContinue"

$zipPath = "C:\Users\asw\adb.zip"
$extractPath = "C:\tools"

Write-Host "=== ADB Install ==="
Write-Host "Zip: $(Test-Path $zipPath)"
Write-Host "Size: $([math]::Round((Get-Item $zipPath -ErrorAction SilentlyContinue).Length/1MB,1)) MB"

Write-Host "`nExtracting..."
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$adbExe = Join-Path $extractPath "platform-tools\adb.exe"
Write-Host "adb.exe: $(Test-Path $adbExe)"

if (Test-Path $adbExe) {
    & $adbExe version
    
    Write-Host "`nConnecting to Fire TV Stick..."
    & $adbExe connect 192.168.0.136:5555
    
    Write-Host "`nDevices:"
    & $adbExe devices -l
    
    $devs = & $adbExe devices 2>&1
    if ($devs -match "192.168.0.136") {
        Write-Host "`nFire TV Info:"
        & $adbExe -s 192.168.0.136:5555 shell getprop ro.product.model
        & $adbExe -s 192.168.0.136:5555 shell getprop ro.product.brand
        & $adbExe -s 192.168.0.136:5555 shell getprop ro.build.version.release
        
        Write-Host "`nMedia Apps:"
        & $adbExe -s 192.168.0.136:5555 shell pm list packages 2>$null | Where-Object {
            $_ -match "amazon|netflix|prime|kodi|youtube|plex|spotify|disney|jellyfin|twitch"
        }
    } else {
        Write-Host "Fire TV NOT connected!"
    }
    
    # Cleanup
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "`nCleaned up"
    
    Write-Host "`nDONE!"
} else {
    Write-Host "ADB NOT found after extraction!"
    Get-ChildItem $extractPath -Recurse -Filter "*.exe" | ForEach-Object { Write-Host $_.FullName }
}
