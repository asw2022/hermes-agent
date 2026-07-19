$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
Write-Host "C: Free=$freeGB GB | Used=$([math]::Round($drive.Used/1GB,2)) GB"
wo Test-Path "C:\Windows.old"
if (Test-Path "C:\Windows.old") {
    Write-Host "Windows.old: YES - will be offered by cleanmgr"
} else {
    Write-Host "Windows.old: no"
}
