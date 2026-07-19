import subprocess

def ps(cmd, timeout=15):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

total_freed = 0

# 1. User Temp
print("1. User Temp (362 MB)...")
r = ps("Get-ChildItem 'C:\\Users\\asw\\AppData\\Local\\Temp' -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Write-Output 'Done'")
print(f"   {r}")

# 2. Windows Temp
print("2. Windows Temp...")
r = ps("Get-ChildItem 'C:\\Windows\\Temp' -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Write-Output 'Done'")
print(f"   {r}")

# 3. Prefetch
print("3. Prefetch...")
r = ps("Get-ChildItem 'C:\\Windows\\Prefetch' -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue; Write-Output 'Done'")
print(f"   {r}")

# 4. INetCache
print("4. INetCache...")
r = ps("Get-ChildItem 'C:\\Users\\asw\\AppData\\Local\\Microsoft\\Windows\\INetCache' -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Write-Output 'Done'")
print(f"   {r}")

# 5. pip cache
print("5. pip cache...")
r = ps("pip cache purge 2>&1; Write-Output 'Done'")
print(f"   {r}")

# 6. npm cache
print("6. npm cache...")
r = ps("npm cache clean --force 2>&1; Write-Output 'Done'")
print(f"   {r}")

# 7. .cache Ordner checken was drin ist
print("\n7. .cache Analyse...")
r = ps("Get-ChildItem 'C:\\Users\\asw\\.cache' -Directory -ErrorAction SilentlyContinue | Select-Object Name | Format-Table -AutoSize")
print(f"   Subdirs:\n{r}")

print("\n=== Cleanup Phase 1 Done ===")
