import subprocess

def ps(cmd, timeout=30):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Read HA version and config
print(ps("Get-Content 'C:\\Users\\asw\\.homeassistant\\.HA_VERSION' -ErrorAction SilentlyContinue"))

# Check hass.exe for the --ignore-os-check flag
print(ps("& 'C:\\Users\\asw\\ha-venv\\Scripts\\hass.exe' --help 2>&1 | Select-String 'ignore|os-check'"))

# Start with ignore OS check
print("\nStarting HA with --ignore-os-check...")
ps("$env:PYTHONIOENCODING='utf-8'; & 'C:\\Users\\asw\\ha-venv\\Scripts\\hass.exe' --config 'C:\\Users\\asw\\.homeassistant' --ignore-os-check 2>&1 | Out-File 'C:\\Users\\asw\\ha_startup.log' -Encoding utf8")
print(ps("Get-Content 'C:\\Users\\asw\\ha_startup.log' -Tail 20"))
