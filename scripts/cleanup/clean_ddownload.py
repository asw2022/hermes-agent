import os

files = [
    'D:\\Download\\fireiso-2.0.0-amd64.iso',
    'D:\\Download\\G.I. Joe - The Rise of Cobra (EU).cso',
    'D:\\Download\\XigmaNAS-x64-LiveCD-13.2.0.5.9876.iso',
]

total = 0
for f in files:
    if os.path.exists(f):
        size = os.path.getsize(f)
        os.remove(f)
        total += size
        print(f"DELETED: {os.path.basename(f)} ({size/1024/1024/1024:.2f} GB)")
    else:
        print(f"NOT FOUND: {f}")

print(f"\nFreed: {total/1024/1024/1024:.2f} GB")

# Show what's left in Download
d = 'D:\\Download'
remaining = os.listdir(d)
print(f"\nD:\\Download remaining: {len(remaining)} items")
for item in remaining:
    fp = os.path.join(d, item)
    if os.path.isfile(fp):
        size = os.path.getsize(fp)
        if size > 1024*1024:
            print(f"  {item}: {size/1024/1024:.1f} MB")
