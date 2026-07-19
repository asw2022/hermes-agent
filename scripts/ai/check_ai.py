# Check for AI/ML tools and models
import os, subprocess, glob

results = []

# HuggingFace cache
hf_cache = os.path.expanduser('~/.cache/huggingface')
if os.path.exists(hf_cache):
    results.append(f"HuggingFace cache: EXISTS at {hf_cache}")

# Ollama
ollama_dir = "C:/Users/asw/AppData/Local/ollama"
if os.path.exists(ollama_dir):
    models_dir = os.path.join(ollama_dir, "models")
    if os.path.exists(models_dir):
        models = os.listdir(models_dir)
        results.append(f"Ollama: {len(models)} models")

# LM Studio
lmstudio = "C:/Users/asw/AppData/Local/lm-studio"
if os.path.exists(lmstudio):
    results.append("LM Studio: INSTALLED")

# ComfyUI
comfy = "C:/Users/asw/AppData/Local/ComfyUI"
if os.path.exists(comfy):
    results.append("ComfyUI: INSTALLED")

# Stable Diffusion
sd_paths = [
    "C:/Users/asw/AppData/Local/stable-diffusion",
    "C:/Users/asw/stable-diffusion",
]
for p in sd_paths:
    if os.path.exists(p):
        results.append(f"Stable Diffusion: {p}")

# Python ML packages
try:
    ml_pkgs = subprocess.run(['python3', '-c', '''
import importlib
pkgs = ['torch', 'tensorflow', 'transformers', 'diffusers', 'llama_cpp', 'onnxruntime', 'ollama', 'openai', 'anthropic']
found = []
for p in pkgs:
    try:
        importlib.import_module(p)
        found.append(p)
    except: pass
print(",".join(found))
'''], capture_output=True, text=True, timeout=10)
    if ml_pkgs.stdout.strip():
        results.append(f"Python ML packages: {ml_pkgs.stdout.strip()}")
except:
    pass

# CUDA / NVIDIA
nvidia_smi = subprocess.run(['nvidia-smi', '--query-gpu=name,memory.total', '--format=csv,noheader'], 
    capture_output=True, text=True, timeout=5)
if nvidia_smi.returncode == 0:
    results.append(f"GPU: {nvidia_smi.stdout.strip()}")

# Check for AI-related programs in Program Files
pf_dirs = ["C:/Program Files", "C:/Program Files (x86)", "C:/Users/asw/AppData/Local/Programs"]
ai_keywords = ['cuda', 'tensorrt', 'deeplearning', 'ai', 'ml', 'neural']
for pf in pf_dirs:
    if os.path.exists(pf):
        try:
            for item in os.listdir(pf):
                if any(k in item.lower() for k in ai_keywords):
                    results.append(f"Program: {item}")
        except:
            pass

# Print results
for r in results:
    print(r)

if not results:
    print("No AI/ML tools found locally.")
