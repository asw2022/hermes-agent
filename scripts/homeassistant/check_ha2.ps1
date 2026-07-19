$hw = Get-ChildItem "C:\Users\asw\ha-venv\Scripts\hass.exe" -ErrorAction SilentlyContinue
if ($hw) {
    Write-Host "hass.exe: YES ($([math]::Round($hw.Length/1KB,0)) KB)"
} else {
    Write-Host "hass.exe: NOT FOUND"
}

# 2. Can we import it?
$py = "C:\Users\asw\ha-venv\Scripts\python.exe"
if (Test-Path $py) {
    $v = & $py -c "import homeassistant; print('HA v' + homeassistant.__version__)" 2>&1
    Write-Host "HA import: $v"
}

# 3. Disk
$d = Get-PSDrive C
Write-Host "C: Free=$([math]::Round($d.Free/1GB,1)) GB"
