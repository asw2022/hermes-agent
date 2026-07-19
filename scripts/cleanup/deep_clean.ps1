$ErrorActionPreference = "SilentlyContinue"
$totalFreed = 0

# 1. npm cache
Write-Host "=== npm cache ==="
$npmCache = "$env:APPDATA\npm-cache"
if (Test-Path $npmCache) {
    $before = (Get-ChildItem -Path $npmCache -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $npmCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not present"
}

# 2. pip cache
Write-Host ""
Write-Host "=== pip cache ==="
$pipCache = "$env:LOCALAPPDATA\pip\cache"
if (Test-Path $pipCache) {
    $before = (Get-ChildItem -Path $pipCache -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $pipCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not present"
}

# 3. Edge Crashpad dumps
Write-Host ""
Write-Host "=== Edge Crashpad dumps ==="
$edgeCrash = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Crashpad\reports"
if (Test-Path $edgeCrash) {
    $before = (Get-ChildItem -Path $edgeCrash -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $edgeCrash -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not present"
}

# 4. Chrome Crashpad dumps
Write-Host ""
Write-Host "=== Chrome Crashpad dumps ==="
$chromeCrash = "$env:LOCALAPPDATA\Google\Chrome\User Data\Crashpad\reports"
if (Test-Path $chromeCrash) {
    $before = (Get-ChildItem -Path $chromeCrash -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $chromeCrash -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not present (Chrome may not be installed)"
}

# 5. Firefox Crashpad dumps
Write-Host ""
Write-Host "=== Firefox Crashpad dumps ==="
$ffCrash = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $ffCrash) {
    $before = (Get-ChildItem -Path $ffCrash -Recurse -Filter "*.dmp" -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $ffCrash -Recurse -Filter "*.dmp" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
}

# 6. WER (Windows Error Reporting) - all drives
Write-Host ""
Write-Host "=== WER ReportQueue ==="
$werPaths = @(
    "C:\ProgramData\Microsoft\Windows\WER\ReportQueue",
    "C:\ProgramData\Microsoft\Windows\WER\ReportArchive"
)
foreach ($p in $werPaths) {
    if (Test-Path $p) {
        $before = (Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $before
        Write-Host ("$p : " + [math]::Round($before/1MB, 1) + " MB")
    }
}

# 7. Windows WebCache
Write-Host ""
Write-Host "=== WebCache ==="
$webCache = "$env:LOCALAPPDATA\Microsoft\Windows\WebCache"
if (Test-Path $webCache) {
    $before = (Get-ChildItem -Path $webCache -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $webCache -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
}

# 8. Edge component cache (the large crx file)
Write-Host ""
Write-Host "=== Edge component_crx_cache (files >50MB) ==="
$edgeCrx = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\component_crx_cache"
if (Test-Path $edgeCrx) {
    $largeFiles = Get-ChildItem -Path $edgeCrx -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 50MB }
    $before = ($largeFiles | Measure-Object -Property Length -Sum).Sum
    $largeFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB (" + ($largeFiles | Measure-Object).Count + " files)")
}

Write-Host ""
Write-Host ("=== TOTAL FREED: " + [math]::Round($totalFreed/1MB, 1) + " MB (" + [math]::Round($totalFreed/1024MB, 2) + " GB) ===")
