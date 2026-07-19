import subprocess

script = 'C:\\Users\\asw\\scan_drive.ps1'
for drive in ['D:', 'E:', 'G:']:
    print(f"\n=== {drive} ===")
    result = subprocess.run(
        ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, drive],
        capture_output=True, timeout=15
    )
    # Handle encoding
    try:
        out = result.stdout.decode('utf-8').strip()
    except:
        out = result.stdout.decode('cp1252', errors='replace').strip()
    if out:
        print(out[:2000])
    if result.returncode != 0:
        try:
            err = result.stderr.decode('cp1252', errors='replace').strip()[:200]
        except:
            err = "decode error"
        if err:
            print(f"ERR: {err}")
