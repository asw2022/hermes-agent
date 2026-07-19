import subprocess

def ps(cmd, timeout=10):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

print("=== Docker Status ===")
print(ps("docker info 2>&1 | Select-Object -First 10"))
print("\n=== Docker Context ===")
print(ps("docker context ls 2>&1"))
print("\n=== Docker Desktop ===")
print(ps("Get-Process -Name 'Docker*','docker*' -ErrorAction SilentlyContinue | Select-Object Name,Id | Format-Table -AutoSize"))
