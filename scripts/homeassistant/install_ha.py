import subprocess

# Create venv
print("=== Creating venv ===")
r = subprocess.run(
    ['G:\\Users\\asw\\AppData\\Local\\Programs\\Python\\Python312\\python.exe', '-m', 'venv', 'C:\\Users\\asw\\ha-venv-py312'],
    capture_output=True, text=True, timeout=60
)
print(r.stdout)
if r.returncode != 0:
    print("STDERR:", r.stderr)
else:
    print("Venv created!")

# Install HA
print("\n=== Installing HA ===")
r = subprocess.run(
    ['C:\\Users\\asw\\ha-venv-py312\\Scripts\\pip.exe', 'install', 'homeassistant==2024.3.3'],
    capture_output=True, text=True, timeout=300
)
print(r.stdout[-3000:] if r.stdout else "No stdout")
if r.returncode != 0:
    print("STDERR:", r.stderr[-2000:] if r.stderr else "None")
else:
    print("HA installed!")
