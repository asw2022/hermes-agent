ErrorActionPreference = SilentlyContinue

$zipPath = "C:\Users\asw\adb2.zip"
$extractPath = "C:\tools\platform-tools"
$adbUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

Write-Host "1. Downloading ADB..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $adbUrl -OutFile $zipPath -UseBasicParsing
Write-Host "   Size: $([math]::Round((Get-Item $zipPath).Length/1MB,1)) MB"

Write-Host "2. Extracting..."
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
$adbExe = Join-Path $extractPath "platform-tools\adb.exe"
Write-Host "   adb.exe: $(Test-Path $adbExe)"

Remove-Item $zipPath -Force

Write-Host "3. ADB Version..."
& $adbExe --version

Write-Host "4. Connecting to Fire TV Stick 192.168.0.136..."
& $adbExe connect 192.168.0.136:5555

Write-Host "5. Devices..."
& $adbExe devices -l

$devicesOutput = & $adbExe devices 2>&1
if ($devicesOutput -match "192.168.0.136") {
    Write-Host "6. Fire TV Stick Info..."
    & $adbExe -s 192.168.0.136:5555 shell getprop ro.product.model
    & $adbExe -s 192.168.0.136:5555 shell getprop ro.product.brand
    & $adbExe -s 192.168.0.136:5555 shell getprop ro.build.version.release
    
    Write-Host "7. Media Apps..."
    & $adbExe -s 192.168.0.136:5555 shell pm list packages | Where-Object {
        $_ -match "amazon|netflix|prime|kodi|youtube|plex|spotify|disney|jellyfin"
    }
    Write-Host "DONE!"s
} else {
    Write-Host "Fire TV Stick NOT connected!"
}
