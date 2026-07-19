$ErrorActionPreference = "SilentlyContinue"

# pip cache via robocopy
$pipPaths = @(
    "C:\Users\asw\AppData\Local\pip\cache",
    "C:\Users\asw\AppData\Roaming\pip\cache"
)
$emptyDir = "C:\Users\asw\AppData\Local$$_empty"
if (-not (Test-Path $emptyDir)) { New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null }
foreach ($p in $pipPaths) {
    if (Test-Path $p) {
        robocopy $emptyDir $p /MIR /NFL /NDL /NJH /NJS | Out-Null
        Remove-Item $p -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host ("Deleted: " + $p)
    } else {
        Write-Host ("Not found: " + $p)
    }
}
Remove-Item $emptyDir -Force -Recurse -ErrorAction SilentlyContinue

# Edge Crashpad
$edgeCrash = "C:\Users\asw\AppData\Local\Microsoft\Edge\User Data\Crashpad\reports"
if (Test-Path $edgeCrash) {
    Remove-Item "$edgeCrash\*" -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Edge Crashpad cleared"
} else { Write-Host "Edge Crashpad: not found" }

# Chrome Crashpad
$chromeCrash = "C:\Users\asw\AppData\Local\Google\Chrome\User Data\Crashpad\reports"
if (Test-Path $chromeCrash) {
    Remove-Item "$chromeCrash\*" -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Chrome Crashpad cleared"
} else { Write-Host "Chrome Crashpad: not found" }

# WebCache
$webCache = "C:\Users\asw\AppData\Local\Microsoft\Windows\WebCache"
if (Test-Path $webCache) {
    Remove-Item "$webCache\*" -Force -ErrorAction SilentlyContinue
    Write-Host "WebCache cleared"
}

Write-Host "=== DONE ==="
