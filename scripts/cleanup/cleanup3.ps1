$ErrorActionPreference = "SilentlyContinue"

# Winsxs sizes
$winsxs = "C:\Windows\WinSxS"
$winsxsSize = (Get-ChildItem -Path $winsxs -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$winsxsCleanup = (Get-ChildItem -Path "$winsxs\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Get-ChildItem -Path "$winsxs\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ("WinSxS Total: " + [math]::Round($winsxsSize/1GB, 2) + " GB | Temp cleared: " + [math]::Round($winsxsCleanup/1MB, 1) + " MB")

# Installer temp cleanup
$installer = "C:\Windows\Installer"
$installerSize = (Get-ChildItem -Path $installer -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host ("Installer Total: " + [math]::Round($installerSize/1GB, 2) + " GB (not touched - system-critical)")

# Check Windows.old
if (Test-Path "C:\Windows.old") {
    $woSize = (Get-ChildItem -Path "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Write-Host ("Windows.old FOUND: " + [math]::Round($woSize/1GB, 2) + " GB - can be removed via cleanmgr!")
} else {
    Write-Host "No Windows.old found"
}
