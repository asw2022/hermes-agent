import subprocess, os

# D: files to delete
d_files = [
    'D:\\Download\\win11.iso',
    'D:\\Download\\haiku-r1beta4-x86_64-anyboot.iso',
    'D:\\Download\\OneDrive-2024-10-17.zip',
    'D:\\Google Album update 2023 Fotos\\takeout-20230628T204215Z-003.zip',
]
d_root_files = [
    'D:\\Star Trek Strange New Worlds.rar',
]

# Check sizes and delete D: files
total_freed = 0
for f in d_files + d_root_files:
    if os.path.exists(f):
        size = os.path.getsize(f)
        print(f"DELETE: {f} ({size/1024/1024/1024:.2f} GB)")
        total_freed += size
    else:
        print(f"NOT FOUND: {f}")

print(f"\nD: total to free: {total_freed/1024/1024/1024:.2f} GB")
print("---")

# E: files to delete
e_files = [
    'E:\\OneDrive Backup vom 07.05.2022\\OneDrive-2022-05-07.zip',
    'E:\\temp\\3DMark-v1-5-893.zip',
]

e_total = 0
for f in e_files:
    if os.path.exists(f):
        size = os.path.getsize(f)
        print(f"DELETE: {f} ({size/1024/1024/1024:.2f} GB)")
        e_total += size
    else:
        print(f"NOT FOUND: {f}")

print(f"E: total to free: {e_total/1024/1024/1024:.2f} GB")
