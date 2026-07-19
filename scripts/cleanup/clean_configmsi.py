import subprocess

# G: Config.Msi - Windows Installer cache, safe to delete contents
# Use PowerShell since it's a system folder
result = subprocess.run(
    ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
     '''$path = "G:\\Config.Msi"
if (Test-Path $path) {
    $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue
    $size = ($items | Measure-Object -Property Length -Sum).Sum
    Write-Output "Config.Msi: $($items.Count) items, $([math]::Round($size/1GB,2)) GB"
    # Delete contents but not the folder itself
    $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    $remaining = (Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Output "Remaining: $remaining items"
} else {
    Write-Output "Config.Msi: NOT FOUND"
}'''],
    capture_output=True, timeout=30
)
try:
    print(result.stdout.decode('cp1252', errors='replace').strip())
except:
    print(result.stdout.decode('utf-8', errors='replace').strip())
if result.stderr:
    print("ERR:", result.stderr.decode('cp1252', errors='replace').strip()[:300])
