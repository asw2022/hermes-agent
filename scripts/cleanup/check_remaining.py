import subprocess, os

# Clean D:\temp if exists, and E:\temp leftovers
paths_to_check = [
    'D:\\temp',
    'E:\\temp',
]

for p in paths_to_check:
    if os.path.exists(p):
        items = os.listdir(p)
        total_size = 0
        for item in items:
            fp = os.path.join(p, item)
            try:
                if os.path.isfile(fp):
                    total_size += os.path.getsize(fp)
            except:
                pass
        print(f"{p}: {len(items)} items, ~{total_size/1024/1024/1024:.2f} GB")
    else:
        print(f"{p}: NOT FOUND")

# Also check D:\Download for remaining large files
d_download = 'D:\\Download'
if os.path.exists(d_download):
    items = os.listdir(d_download)
    print(f"\nD:\\Download remaining items: {len(items)}")
    for item in items:
        fp = os.path.join(d_download, item)
        try:
            if os.path.isfile(fp):
                size = os.path.getsize(fp)
                if size > 10*1024*1024:
                    print(f"  {item}: {size/1024/1024/1024:.2f} GB")
        except:
            pass
