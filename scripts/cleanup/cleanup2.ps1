# Deep cleanup - Stage 2
$ErrorActionPreference = "SilentlyContinue"
$totalFreed = 0

# 1. Windows %TEMP% subfolder cleanup (older items)
$tempRoot = "C:\Users\asw\AppData\Local\Temp"
$oldTemp = Get-ChildItem -Path $tempRoot -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
$before = ($oldTemp | Measure-Object -Property Length -Sum).Sum
$oldTemp | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$totalFreed += $before
Write-Host ("Temp >7 days: " + [math]::Round($before/1MB, 1) + " MB")

# 2. Windows log files
$logPath = "C:\Windows\Logs"
if (Test-Path $logPath) {
    $before = (Get-ChildItem -Path $logPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $logPath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Win Logs: " + [math]::Round($before/1MB, 1) + " MB")
}

# 3. .tmp files on C: root
$tmpFiles = Get-ChildItem -Path "C:\tmp" -Force -ErrorAction SilentlyContinue
$before = ($tmpFiles | Measure-Object -Property Length -Sum).Sum
$tmpFiles | Remove-Item -Force -ErrorAction SilentlyContinue
$totalFreed += $before
Write-Host ("C:\tmp: " + [math]::Round($before/1MB, 1) + " MB")

# 4. pip cache
$pipCache = "$env:LOCALAPPDATA\pip\Cache"
if (Test-Path $pipCache) {
    $before = (Get-ChildItem -Path $pipCache -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $pipCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("pip Cache: " + [math]::Round($before/1MB, 1) + " MB")
}

# 5. npm cache
$npmCache = "$env:APPDATA\npm-cache"
if (Test-Path $npmCache) {
    $before = (Get-ChildItem -Path $npmCache -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $npmCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("npm Cache: " + [math]::Round($before/1MB, 1) + " MB")
}

# 6. Crash dumps & minidumps
$crashPaths = @("C:\Users\asw\CrashDumps", "C:\ProgramData\Microsoft\Windows\WER")
foreach ($p in $crashPaths) {
    if (Test-Path $p) {
        $before = (Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $before
        Write-Host ("$p : " + [math]::Round($before/1MB, 1) + " MB")
    }
}

Write-Host ""
Write-Host ("=== Stage 2 Freed: " + [math]::Round($totalFreed/1MB, 1) + " MB ===")
