import os, shutil

temp_path = 'E:\\temp'
if os.path.exists(temp_path):
    items = os.listdir(temp_path)
    total_size = 0
    deleted = 0
    errors = 0
    for item in items:
        fp = os.path.join(temp_path, item)
        try:
            if os.path.isfile(fp):
                total_size += os.path.getsize(fp)
                os.remove(fp)
                deleted += 1
            elif os.path.isdir(fp):
                shutil.rmtree(fp, ignore_errors=True)
                deleted += 1
        except:
            errors += 1
    remaining = os.listdir(temp_path) if os.path.exists(temp_path) else []
    print(f"E:\\temp: deleted {deleted} items, {errors} errors")
    print(f"Freed: ~{total_size/1024/1024/1024:.2f} GB")
    print(f"Remaining: {len(remaining)} items")
else:
    print("E:\\temp: NOT FOUND")
