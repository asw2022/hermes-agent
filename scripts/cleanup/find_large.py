# Find large files on C:
import os

print("=== Suche groesste Dateien auf C: ===\n")

large_files = []
for root, dirs, files in os.walk("C:\\"):
    # Skip some system dirs that cause issues
    dirs[:] = [d for d in dirs if d not in ['WindowsApps']]
    for f in files:
        try:
            fp = os.path.join(root, f)
            size = os.path.getsize(fp)
            if size > 100*1024*1024:  # > 100 MB
                large_files.append((size, fp))
        except:
            pass

large_files.sort(reverse=True)
for size, path in large_files[:30]:
    print(f"{size/1024/1024/1024:6.2f} GB  {path}")

print(f"\nGesamt: {len(large_files)} Dateien > 100 MB")
total = sum(s for s,p in large_files)
print(f"Summe: {total/1024/1024/1024:.2f} GB")
