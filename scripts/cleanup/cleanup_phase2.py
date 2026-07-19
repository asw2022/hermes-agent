# Cleanup C: - Phase 2
import subprocess, os, shutil

freed = 0

# 1. Code cache (VS Code / Codex)
print("=== 1. Code Cache ===")
for p in [
    "C:/Users/asw/AppData/Local/Code/cache",
    "C:/Users/asw/AppData/Local/Code/CachedData",
    "C:/Users/asw/AppData/Local/Code/logs",
    "C:/Users/asw/AppData/Roaming/Code/logs",
]:
    if os.path.exists(p):
        try:
            size = sum(os.path.getsize(os.path.join(r,f)) for r,d,fs in os.walk(p) for f in fs)
            shutil.rmtree(p, ignore_errors=True)
            freed += size
            print(f"   {p}: {size/1024/1024:.1f} MB")
        except: pass

# 2. Windows Installer Backup Cache (safe to delete)
print("\n=== 2. Installer PatchCache ===")
pc = "C:/Windows/Installer/$PatchCache$"
if os.path.exists(pc):
    try:
        size = sum(os.path.getsize(os.path.join(r,f)) for r,d,fs in os.walk(pc) for f in fs)
        shutil.rmtree(pc, ignore_errors=True)
        freed += size
        print(f"   PatchCache: {size/1024/1024:.1f} MB")
    except Exception as e:
        print(f"   Error: {e}")

# 3. Delivery Optimization
print("\n=== 3. Delivery Optimization ===")
do = "C:/Windows/SoftwareDistribution/DeliveryOptimization"
if os.path.exists(do):
    try:
        size = sum(os.path.getsize(os.path.join(r,f)) for r,d,fs in os.walk(do) for f in fs)
        shutil.rmtree(do, ignore_errors=True)
        freed += size
        print(f"   DO: {size/1024/1024:.1f} MB")
    except: pass

# 4. Windows Update Download (already cleaned but check again)
print("\n=== 4. Win Update Download ===")
sdd = "C:/Windows/SoftwareDistribution/Download"
if os.path.exists(sdd):
    try:
        files = []
        for r,d,fs in os.walk(sdd):
            for f in fs:
                try: files.append(os.path.getsize(os.path.join(r,f)))
                except: pass
        size = sum(files)
        if size > 0:
            shutil.rmtree(sdd, ignore_errors=True)
            freed += size
            print(f"   Download: {size/1024/1024:.1f} MB")
        else:
            print(f"   Download: already empty")
    except: pass

# 5. Temp nochmal
print("\n=== 5. Temp Erneut ===")
tmp = "C:/Users/asw/AppData/Local/Temp"
if os.path.exists(tmp):
    try:
        size = sum(os.path.getsize(os.path.join(r,f)) for r,d,fs in os.walk(tmp) for f in fs)
        if size > 10*1024*1024:  # > 10 MB
            # Delete files older than 7 days
            import time
            now = time.time()
            deleted = 0
            for r,d,fs in os.walk(tmp):
                for f in fs:
                    fp = os.path.join(r,f)
                    try:
                        if os.path.getmtime(fp) < now - 7*86400:
                            os.remove(fp)
                            deleted += 1
                    except: pass
            print(f"   Deleted {deleted} old temp files")
        else:
            print(f"   Temp: only {size/1024/1024:.1f} MB")
    except: pass

print(f"\n=== Phase 2 gesamt: {freed/1024/1024:.1f} MB ===")
