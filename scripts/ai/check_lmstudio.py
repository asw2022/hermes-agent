import os, json

lmstudio_base = "C:/Users/asw/AppData/Local/lm-studio"
lmstudio_models = "C:/Users/asw/.lmstudio"
results = []

# Check main LM Studio dir
if os.path.exists(lmstudio_base):
    results.append(f"LM Studio installed: {lmstudio_base}")
    for item in os.listdir(lmstudio_base):
        full = os.path.join(lmstudio_base, item)
        if os.path.isdir(full):
            # Get folder size (top-level files only)
            try:
                files = [os.path.join(full, f) for f in os.listdir(full) if os.path.isfile(os.path.join(full, f))]
                size = sum(os.path.getsize(f) for f in files)
                if size > 1024*1024:
                    results.append(f"  {item}: {size/1024/1024/1024:.2f} GB")
                elif size > 0:
                    results.append(f"  {item}: {size/1024/1024:.1f} MB")
            except:
                results.append(f"  {item}: (cannot read)")
        else:
            size = os.path.getsize(full)
            if size > 1024*1024:
                results.append(f"  {item}: {size/1024/1024:.1f} MB (file)")

# Check .lmstudio for downloaded models
if os.path.exists(lmstudio_models):
    results.append(f"\nLM Studio models dir: {lmstudio_models}")
    
    # models subdirectory
    models_dir = os.path.join(lmstudio_models, "models")
    if os.path.exists(models_dir):
        results.append("Downloaded models:")
        for publisher in os.listdir(models_dir):
            pub_path = os.path.join(models_dir, publisher)
            if os.path.isdir(pub_path):
                for model in os.listdir(pub_path):
                    model_path = os.path.join(pub_path, model)
                    if os.path.isdir(model_path):
                        # Calculate model size
                        try:
                            model_files = []
                            for root, dirs, files in os.walk(model_path):
                                for f in files:
                                    fp = os.path.join(root, f)
                                    try:
                                        model_files.append(os.path.getsize(fp))
                                    except:
                                        pass
                            total_size = sum(model_files)
                            size_str = f"{total_size/1024/1024/1024:.2f} GB" if total_size > 1024*1024*1024 else f"{total_size/1024/1024:.1f} MB"
                            results.append(f"  {publisher}/{model}: {size_str}")
                        except:
                            results.append(f"  {publisher}/{model}: (error reading)")
                    else:
                        size = os.path.getsize(model_path)
                        size_str = f"{size/1024/1024/1024:.2f} GB" if size > 1024*1024*1024 else f"{size/1024/1024:.1f} MB"
                        results.append(f"  {publisher}/{model}: {size_str} (file)")
    else:
        results.append("  No 'models' subdirectory found")
    
    # Check for other model locations
    for sub in ["blobs", "bin", "cache"]:
        sub_path = os.path.join(lmstudio_models, sub)
        if os.path.exists(sub_path):
            results.append(f"\n{sub} dir: EXISTS")
            try:
                items = os.listdir(sub_path)
                results.append(f"  Items: {len(items)}")
            except:
                pass
    
    # Check config
    config_file = os.path.join(lmstudio_models, "config.json")
    if os.path.exists(config_file):
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            results.append(f"\nConfig keys: {', '.join(config.keys())}")
        except:
            results.append("\nConfig: EXISTS (cannot parse)")
else:
    results.append("LM Studio models dir not found")
    
    # Alternative locations
    alt_paths = [
        "C:/Users/asw/.cache/lm-studio",
        "C:/Users/asw/AppData/Roaming/lm-studio",
    ]
    for alt in alt_paths:
        if os.path.exists(alt):
            results.append(f"Alternative: {alt}")

for r in results:
    print(r)
