import subprocess

def ps(cmd, timeout=10):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

print("=== HA Suche ===")
print(ps("Get-ChildItem 'C:\\Users\\asw\\ha-venv\\Scripts' -Filter 'homeassistant*' | Select-Object Name | Format-List"))
print(ps("Get-ChildItem 'C:\\Users\\asw\\.homeassistant' | Select-Object Name | Format-List"))
