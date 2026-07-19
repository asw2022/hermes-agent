$ErrorActionPreference = "SilentlyContinue"
$winsxs = "C:\Windows\WinSxS"
$winsxsCleanup = (Get-ChildItem -Path "$winsxs\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Get-ChildItem -Path "$winsxs\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ("WinSxS Temp cleared: " + [math]::Round($winsxsCleanup/1MB, 1) + " MB")

if (Test-Path "C:\Windows.old") {
    Write-Host "Windows.old FOUND - cleanmgr will handle it"
} else {
    Write-Host "No Windows.old"
}

# Check free space after all cleanups
$drive = Get-PSDrive C
Write-Host ("Drive C: Free = " + [math]::Round($drive.Free/1GB, 2) + " GB")
