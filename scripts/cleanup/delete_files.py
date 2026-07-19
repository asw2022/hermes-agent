import subprocess, os

# Delete D: files
d_files = [
    'D:\\Download\\win11.iso',
    'D:\\Download\\haiku-r1beta4-x86_64-anyboot.iso',
    'D:\\Download\\OneDrive-2024-10-17.zip',
    'D:\\Google Album update 2023 Fotos\\takeout-20230628T204215Z-003.zip',
    'D:\\Star Trek Strange New Worlds.rar',
]

d_freed = 0
for f in d_files:
    try:
        size = os.path.getsize(f)
        os.remove(f)
        d_freed += size
        print(f"DELETED: {os.path.basename(f)} ({size/1024/1024/1024:.2f} GB)")
    except Exception as e:
        print(f"ERROR: {f}: {e}")

print(f"D: freed {d_freed/1024/1024/1024:.2f} GB\n")

# Delete E: files
e_files = [
    'E:\\OneDrive Backup vom 07.05.2022\\OneDrive-2022-05-07.zip',
    'E:\\temp\\3DMark-v1-5-893.zip',
]

e_freed = 0
for f in e_files:
    try:
        size = os.path.getsize(f)
        os.remove(f)
        e_freed += size
        print(f"DELETED: {os.path.basename(f)} ({size/1024/1024/1024:.2f} GB)")
    except Exception as e:
        print(f"ERROR: {f}: {e}")

print(f"E: freed {e_freed/1024/1024/1024:.2f} GB")
