import subprocess

def ps(cmd, timeout=10):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

print("=== Venv Contents ===")
print(ps("Get-ChildItem 'C:\\Users\\asw\\ha-venv-py312\\Lib\\site-packages' -Directory | Select-Object Name | Format-Table -AutoSize"))

print("\n=== pip list ===")
print(ps("& 'C:\\Users\\asw\\ha-venv-py312\\Scripts\\pip.exe' list 2>&1"))
