import subprocess, os, winreg

# Find Adobe programs via registry
adobe_programs = []

# Check both 32-bit and 64-bit registry
for hive, path in [
    (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
    (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"),
    (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
]:
    try:
        key = winreg.OpenKey(hive, path)
        i = 0
        while True:
            try:
                subkey_name = winreg.EnumKey(key, i)
                subkey = winreg.OpenKey(key, subkey_name)
                try:
                    name = winreg.QueryValueEx(subkey, "DisplayName")[0]
                    if "Adobe" in str(name):
                        try:
                            uninstall = winreg.QueryValueEx(subkey, "UninstallString")[0]
                        except:
                            uninstall = "N/A"
                        try:
                            version = winreg.QueryValueEx(subkey, "DisplayVersion")[0]
                        except:
                            version = "?"
                        try:
                            size = winreg.QueryValueEx(subkey, "EstimatedSize")[0]
                            size_mb = round(size / 1024, 1)
                        except:
                            size_mb = "?"
                        adobe_programs.append({
                            "name": name,
                            "version": version,
                            "uninstall": uninstall,
                            "size_mb": size_mb
                        })
                except:
                    pass
                winreg.CloseKey(subkey)
                i += 1
            except WindowsError:
                break
        winreg.CloseKey(key)
    except:
        pass

# Also check common Adobe folders
adobe_folders = []
for base in ["C:/Program Files/Adobe", "C:/Program Files (x86)/Adobe", "C:/Users/asw/AppData/Local/Adobe", "C:/Users/asw/AppData/Roaming/Adobe"]:
    if os.path.exists(base):
        try:
            size = sum(os.path.getsize(os.path.join(r,f)) for r,d,fs in os.walk(base) for f in fs if os.path.isfile(os.path.join(r,f)))
            adobe_folders.append((base, round(size/1024/1024, 1)))
        except:
            adobe_folders.append((base, "?"))

print("=== Adobe Programme (Registry) ===")
total_size = 0
for p in sorted(adobe_programs, key=lambda x: x['name']):
    print(f"  {p['name']}")
    print(f"    Version: {p['version']}")
    print(f"    Size: {p['size_mb']} MB")
    print(f"    Uninstall: {p['uninstall'][:80]}")
    if isinstance(p['size_mb'], (int, float)):
        total_size += p['size_mb']

print(f"\n  Total: {len(adobe_programs)} Programme, ~{total_size} MB")

print("\n=== Adobe Ordner ===")
for path, size in adobe_folders:
    print(f"  {path}: {size} MB")

# Save uninstall commands
print("\n=== Uninstall Commands ===")
for p in adobe_programs:
    print(f"REM {p['name']}")
    print(f"{p['uninstall']}")
    print()
