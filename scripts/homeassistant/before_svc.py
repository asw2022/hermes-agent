import subprocess

def ps(cmd, timeout=15):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

print("=== VORHER - Dienste-Status ===")
for svc in ['TermService', 'sshd', 'SSDPSRV', 'upnphost']:
    result = ps(f"Get-Service -Name '{svc}' -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-List")
    if result:
        print(result)
    else:
        print(f"{svc}: NOT FOUND")
