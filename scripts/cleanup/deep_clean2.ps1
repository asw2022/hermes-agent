$ErrorActionPreference = "SilentlyContinue"
$totalFreed = 0

# 1. npm-cache (AppData\Local) - delete directly without scanning
Write-Host "=== npm-cache (AppData\Local) ==="
$npmLocal = "C:\Users\asw\AppData\Local\npm-cache"
if (Test-Path $npmLocal) {
    # Use robocopy to delete faster (mirror empty dir)
    $emptyDir = "C:\Users\asw\AppData\Local\_empty_npm"
    if (-not (Test-Path $emptyDir)) { New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null }
    robocopy $emptyDir $npmLocal /MIR /NFL /NDL /NJH /NJS | Out-Null
    Remove-Item $npmLocal -Force -ErrorAction SilentlyContinue
    Remove-Item $emptyDir -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted npm-cache (AppData\Local)"
} else {
    Write-Host "Not found"
}

# 2. npm-cache (AppData\Roaming)
Write-Host ""
Write-Host "=== npm-cache (AppData\Roaming) ==="
$npmRoam = "C:\Users\asw\AppData\Roaming\npm-cache"
if (Test-Path $npmRoam) {
    $emptyDir = "C:\Users\asw\AppData\Local\_empty_npm2"
    if (-not (Test-Path $emptyDir)) { New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null }
    robocopy $emptyDir $npmRoam /MIR /NFL /NDL /NJH /NJS | Out-Null
    Remove-Item $npmRoam -Force -ErrorAction SilentlyContinue
    Remove-Item $emptyDir -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted npm-cache (AppData\Roaming)"
} else {
    Write-Host "Not found"
}

# 3. pip cache
Write-Host ""
Write-Host "=== pip cache ==="
$pipPaths = @(
    "C:\Users\asw\AppData\Local\pip\cache",
    "C:\Users\asw\AppData\Roaming\pip\cache"
)
foreach ($p in $pipPaths) {
    if (Test-Path $p) {
        $emptyDir = "C:\Users\asw\AppData\Local\_empty_pip"
        if (-not (Test-Path $emptyDir)) { New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null }
        robocopy $emptyDir $p /MIR /NFL /NDL /NJH /NJS | Out-Null
        Remove-Item $p -Force -ErrorAction SilentlyContinue
        Remove-Item $emptyDir -Force -ErrorAction SilentlyContinue
        Write-Host ("Deleted: " + $p)
    }
}

# 4. Edge Crashpad
Write-Host ""
Write-Host "=== Edge Crashpad ==="
$edgeCrash = "C:\Users\asw\AppData\Local\Microsoft\Edge\User Data\Crashpad\reports"
if (Test-Path $edgeCrash) {
    $before = (Get-ChildItem -Path $edgeCrash -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $edgeCrash -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not found"
}

# 5. Chrome Crashpad
Write-Host ""
Write-Host "=== Chrome Crashpad ==="
$chromeCrash = "C:\Users\asw\AppData\Local\Google\Chrome\User Data\Crashpad\reports"
if (Test-Path $chromeCrash) {
    $before = (Get-ChildItem -Path $chromeCrash -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $chromeCrash -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not found"
}

# 6. Edge component_crx_cache - large files only
Write-Host ""
Write-Host "=== Edge crx_cache (>50MB) ==="
$edgeCrx = "C:\Users\asw\AppData\Local\Microsoft\Edge\User Data\component_crx_cache"
if (Test-Path $edgeCrx) {
    $large = Get-ChildItem -Path $edgeCrx -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 50MB }
    $before = ($large | Measure-Object -Property Length -Sum).Sum
    $large | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB (" + ($large | Measure-Object).Count + " files)")
} else {
    Write-Host "Not found"
}

# 7. Edge ProvenanceData (AI model)
Write-Host ""
Write-Host "=== Edge ProvenanceData ==="
$edgeProv = "C:\Users\asw\AppData\Local\Microsoft\Edge\User Data\ProvenanceData"
if (Test-Path $edgeProv) {
    $before = (Get-ChildItem -Path $edgeProv -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $edgeProv -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not found"
}

# 8. WebCache
Write-Host ""
Write-Host "=== WebCache ==="
$webCache = "C:\Users\asw\AppData\Local\Microsoft\Windows\WebCache"
if (Test-Path $webCache) {
    $before = (Get-ChildItem -Path $webCache -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $webCache -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $before
    Write-Host ("Freed: " + [math]::Round($before/1MB, 1) + " MB")
} else {
    Write-Host "Not found"
}

Write-Host ""
Write-Host ("=== TOTAL THIS RUN: " + [math]::Round($totalFreed/1MB, 1) + " MB (" + [math]::Round($totalFreed/1024MB, 2) + " GB) ===")
