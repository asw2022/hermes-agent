import subprocess

def ps(cmd, timeout=10):
    r = subprocess.run(['powershell','-NoProfile','Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Check for native Python installations (not Hermes USB)
print("=== Python Installationen ===")
print(ps("Get-Command python*,python3* -ErrorAction SilentlyContinue | Select-Object Source | Format-Table -AutoSize"))
