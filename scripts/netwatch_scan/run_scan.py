import subprocess, sys, os

def scan_drive(drive, script_path):
    result = subprocess.run(
        ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
         '-File', script_path, drive],
        capture_output=True, text=True, timeout=15,
        cwd='C:\\Users\\asw'
    )
    out = result.stdout.strip()
    err = result.stderr.strip()[:200] if result.stderr else ''
    return out, err

script = 'C:\\Users\\asw\\scan_drive.ps1'

for drive in ['D:', 'E:', 'G:']:
    print(f"\n=== {drive} ===")
    out, err = scan_drive(drive, script)
    if out:
        print(out[:3000])
    if err:
        print(f"ERR: {err}")
