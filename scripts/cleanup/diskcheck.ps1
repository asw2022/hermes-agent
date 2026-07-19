
# Consolidate disk analysis
Write-Host "=== INSTALLED PROGRAMS (Top 25 by size) ==="
$ErrorActionPreference = 'SilentlyContinue'

$progs = @()
$regPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

foreach ($path in $regPaths) {
    $progs += Get-ItemProperty $path -ErrorAction SilentlyContinue | 
        Where-Object { $_.EstimatedSize -gt 0 } |
        Select-Object @{N='Name';E={$_.DisplayName}}, 
                      @{N='SizeMB';E={[math]::Round($_.EstimatedSize/1024,1)}},
                      @{N='Publisher';E={$_.Publisher}},
                      @{N='Version';E={$_.DisplayVersion}}
}

$progs | Sort-Object SizeMB -Descending | 
    Select-Object -First 25 | 
    ForEach-Object { Write-Host ("  {0,10:N0} MB  {1}" -f $_.SizeMB, $_.Name) }

Write-Host ""
Write-Host "=== WINDOWS FOLDER TOP-LEVEL SIZES ==="
$winsub = @('WinSxS','Installer','SoftwareDistribution','System32','SysWOW64','Temp','Prefetch','Fonts','Globalization')
foreach ($dir in $winsub) {
    $full = Join-Path 'C:\Windows' $dir
    if (Test-Path $full) {
        $items = Get-ChildItem $full -Recurse -Force -ErrorAction SilentlyContinue
        $sizeMB = [math]::Round(($items | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host ("  {0,10:N0} MB  C:\Windows\{1}" -f $sizeMB, $dir)
    }
}

Write-Host ""
Write-Host "=== USER TOP-LEVEL DIR SIZES ==="
$userDirs = @('Desktop','Documents','Downloads','Music','Pictures','Videos','AppData\Local','AppData\Roaming')
foreach ($dir in $userDirs) {
    $full = Join-Path 'C:\Users\asw' $dir
    if (Test-Path $full) {
        $items = Get-ChildItem $full -Recurse -Force -ErrorAction SilentlyContinue -Depth 1
        # Count only top-level for speed
        $topItems = Get-ChildItem $full -Force -ErrorAction SilentlyContinue
        Write-Host ("  {0,-30}  top-level items: {1}" -f $topItems.Count, $dir)
    }
}

Write-Host ""
Write-Host "=== SYSTEM FILES ==="
$hiber = Get-ChildItem C:\hiberfil.sys -Force -ErrorAction SilentlyContinue
$page = Get-ChildItem C:\pagefile.sys -Force -ErrorAction SilentlyContinue
$swap = Get-ChildItem C:\swapfile.sys -Force -ErrorAction SilentlyContinue

if ($hiber) { Write-Host ("  {0,10:N0} MB  hiberfil.sys" -f ($hiber.Length/1MB)) } else { Write-Host "  hiberfil.sys: nicht gefunden" }
if ($page) { Write-Host ("  {0,10:N0} MB  pagefile.sys" -f ($page.Length/1MB)) } else { Write-Host "  pagefile.sys: nicht gefunden" }
if ($swap) { Write-Host ("  {0,10:N0} MB  swapfile.sys" -f ($swap.Length/1MB)) } else { Write-Host "  swapfile.sys: nicht gefunden" }

Write-Host ""
Write-Host "=== TEMP SUMMARY ==="
$userTemp = [System.IO.Path]::GetTempPath()
$winTemp = 'C:\Windows\Temp'
$userTempFiles = (Get-ChildItem $userTemp -Force -ErrorAction SilentlyContinue).Count
$winTempFiles = (Get-ChildItem $winTemp -Force -ErrorAction SilentlyContinue).Count
Write-Host "  User Temp files: $userTempFiles"
Write-Host "  Win  Temp files: $winTempFiles"

Write-Host ""
Write-Host "=== SERVICES (Running) ==="
Get-Service | Where-Object { $_.Status -eq 'Running' } | 
    Select-Object -First 15 Name,DisplayName | 
    ForEach-Object { Write-Host ("  {0,-40} {1}" -f $_.Name, $_.DisplayName) }
