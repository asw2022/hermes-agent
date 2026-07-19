$ErrorActionPreference = "SilentlyContinue"
$minSize = 100MB

# 1. Downloads
Write-Host "=== Downloads ==="
$dl = "C:\Users\asw\Downloads"
if (Test-Path $dl) {
    Get-ChildItem -Path $dl -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -gt $minSize } |
        Sort-Object Length -Descending |
        Select-Object -First 15 |
        ForEach-Object { "$([math]::Round($_.Length/1MB,1)) MB  $($_.FullName)" }
} else {
    Write-Host "not found"
}

# 2. Specific large AppData subfolders (non-recursive top-level size)
Write-Host ""
Write-Host "=== AppData\Local folders (>500MB) ==="
$localAppData = "C:\Users\asw\AppData\Local"
if (Test-Path $localAppData) {
    Get-ChildItem -Path $localAppData -Directory -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            # Quick size estimate via Get-ChildItem (shallow + 1 level)
            $size = (Get-ChildItem -Path $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            if ($size -gt 500MB) {
                "$([math]::Round($size/1MB,0)) MB  $($_.Name)"
            }
        }
}
