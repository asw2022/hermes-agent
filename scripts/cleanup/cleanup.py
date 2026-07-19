import subprocess, os, shutil

def rm_rf(path):
    """Force remove directory or file"""
    if os.path.exists(path):
        try:
            if os.path.isdir(path):
                shutil.rmtree(path, ignore_errors=True)
            else:
                os.remove(path)
            return True
        except:
            return False
    return False

total_freed = 0

# 1. User Temp
print("1. User Temp...")
count = 0
for f in os.listdir("C:/Users/asw/AppData/Local/Temp"):
    fp = os.path.join("C:/Users/asw/AppData/Local/Temp", f)
    try:
        size = os.path.getsize(fp) if os.path.isfile(fp) else 0
        rm_rf(fp)
        total_freed += size
        count += 1
    except:
        pass
print(f"   {count} items removed, {total_freed/1024/1024:.1f} MB")

# 2. Windows Temp
print("2. Windows Temp...")
c = 0
for f in os.listdir("C:/Windows/Temp"):
    fp = os.path.join("C:/Windows/Temp", f)
    try:
        size = os.path.getsize(fp) if os.path.isfile(fp) else 0
        rm_rf(fp)
        total_freed += size
        c += 1
    except:
        pass
print(f"   {c} items, freed so far: {total_freed/1024/1024:.1f} MB")

# 3. Prefetch
print("3. Prefetch...")
c = 0
for f in os.listdir("C:/Windows/Prefetch"):
    fp = os.path.join("C:/Windows/Prefetch", f)
    try:
        size = os.path.getsize(fp) if os.path.isfile(fp) else 0
        rm_rf(fp)
        total_freed += size
        c += 1
    except:
        pass
print(f"   {c} items, freed so far: {total_freed/1024/1024:.1f} MB")

# 4. INetCache
print("4. INetCache...")
rm_rf("C:/Users/asw/AppData/Local/Microsoft/Windows/INetCache")
print("   Done")

# 5. pip cache
print("5. pip cache...")
rm_rf("C:/Users/asw/AppData/Local/pip/cache")
print("   Done")

# 6. .cache subdirectories (claude, codex-runtimes, n8n, yt-dlp)
print("6. .cache Ordner...")
cache_dir = "C:/Users/asw/.cache"
for sub in ["claude", "codex-runtimes", "n8n", "yt-dlp"]:
    sp = os.path.join(cache_dir, sub)
    if os.path.exists(sp):
        try:
            files = []
            for root, dirs, fs in os.walk(sp):
                for f in fs:
                    try: files.append(os.path.getsize(os.path.join(root, f)))
                    except: pass
            size = sum(files)
            shutil.rmtree(sp, ignore_errors=True)
            total_freed += size
            print(f"   {sub}: {len(files)} files, {size/1024/1024:.1f} MB")
        except:
            print(f"   {sub}: error")

# 7. CBS.log
print("7. CBS Log...")
cbs = "C:/Windows/Logs/CBS/CBS.log"
if os.path.exists(cbs):
    try:
        size = os.path.getsize(cbs)
        os.remove(cbs)
        total_freed += size
        print(f"   CBS.log: {size/1024/1024:.1f} MB")
    except:
        print("   CBS.log: locked")

# 8. DeliveryOptimization cache
print("8. DeliveryOptimization...")
rm_rf("C:/Windows/SoftwareDistribution/DeliveryOptimization/Cache")
print("   Done")

# 9. Thumbnail cache
print("9. Thumbnail cache...")
c = 0
explorer_thumb = "C:/Users/asw/AppData/Local/Microsoft/Windows/Explorer"
if os.path.exists(explorer_thumb):
    for f in os.listdir(explorer_thumb):
        if "thumbcache" in f.lower() or "iconcache" in f.lower():
            fp = os.path.join(explorer_thumb, f)
            try:
                size = os.path.getsize(fp)
                os.remove(fp)
                total_freed += size
                c += 1
            except:
                pass
print(f"   {c} cache files removed")

print(f"\n=== TOTAL FREED: {total_freed/1024/1024:.1f} MB ===")
