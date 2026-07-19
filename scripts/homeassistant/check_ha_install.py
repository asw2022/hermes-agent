import subprocess

pip = 'C:\\Users\\asw\\ha-venv-py312\\Scripts\\pip.exe'

# Check if HA is installed
r = subprocess.run([pip, 'list'], capture_output=True, text=True, timeout=30)
print("=== Installed Packages ===")
for line in r.stdout.split('\n'):
    if 'homeassistant' in line.lower():
        print(f"  HA: {line}")

# Check HA version
r2 = subprocess.run([pip, 'show', 'homeassistant'], capture_output=True, text=True, timeout=10)
print("\n=== HA Details ===")
print(r2.stdout if r2.returncode == 0 else "HA NOT FOUND")
