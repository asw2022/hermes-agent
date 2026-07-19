import subprocess, os

# CPU
r = subprocess.run(['powershell','-NoProfile','-Command','Get-WmiObject Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors | Format-List'], capture_output=True, timeout=10)
print("=== CPU ===")
print(r.stdout.decode('cp1252','replace').strip())

# RAM
r = subprocess.run(['powershell','-NoProfile','-Command','Get-WmiObject Win32_PhysicalMemory | Manufacturer,Capacity,Speed | Format-List'], capture_output=True, timeout=10)
print("\n=== RAM ===")
print(r.stdout.decode('cp1252','replace').strip())

# GPU
r = subprocess.run(['powershell','-NoProfile','-Command','Get-WmiObject Win32_VideoController | Select-Object Name,AdapterRAM,DriverVersion | Format-List'], capture_output=True, timeout=10)
print("\n=== GPU ===")
print(r.stdout.decode('cp1252','replace').strip())

# Disk sizes
r = subprocess.run(['powershell','-NoProfile','-Command','Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | DeviceID,Size,FreeSpace | Format-Table -AutoSize'], capture_output=True, timeout=10)
print("\n=== Disks ===")
print(r.stdout.decode('cp1252','replace').strip())
