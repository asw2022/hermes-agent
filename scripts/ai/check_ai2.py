import os, glob

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
    else:
        results.append(f"Ollama: INSTALLED (no models dir)")

# LM Studio
lmstudio = "C:/Users/asw/AppData/Local/lm-studio"
if os.path.exists(lmstudio):
    results.append("LM Studio: INSTALLED")

# ComfyUI
for comfy in ["C:/Users/asw/AppData/Local/ComfyUI", "C:/Users/asw/ComfyUI"]:
    if os.path.exists(comfy):
        results.append(f"ComfyUI: {comfy}")

# Stable Diffusion
sd_paths = ["C:/Users/asw/AppData/Local/stable-diffusion", "C:/Users/asw/stable-diffusion"]
for p in sd_paths:
    if os.path.exists(p):
        results.append(f"Stable Diffusion: {p}")

# Python ML packages - check site-packages
import sys
site_pkgs = []
for sp in sys.path:
    if 'site-packages' in sp or 'dist-packages' in sp:
        if os.path.exists(sp):
            for pkg in ['torch', 'tensorflow', 'transformers', 'diffusers', 'llama_cpp', 'onnxruntime', 'ollama', 'openai', 'anthropic']:
                if os.path.exists(os.path.join(sp, pkg)):
                    site_pkgs.append(pkg)
if site_pkgs:
    results.append(f"Python ML packages: {', '.join(site_pkgs)}")

# GPU - find nvidia-smi
nvidia_paths = glob.glob("C:/Program Files/NVIDIA Corporation/NVSMI/nvidia-smi.exe")
if not nvidia_paths:
    nvidia_paths = glob.glob("C:/Windows/System32/nvidia-smi.exe")
if nvidia_paths:
    results.append("nvidia-smi: FOUND")
else:
    results.append("nvidia-smi: NOT FOUND (no NVIDIA GPU or drivers)")

# AI-related programs
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

# Hermes AI tools
results.append("")
results.append("=== Hermes AI Tools ===")
hermes_home = "I:/Hermes-USB-Portable-main"
if os.path.exists(hermes_home):
    # Check for model providers
    plugins_dir = os.path.join(hermes_home, "data", "plugins")
    if os.path.exists(plugins_dir):
        for item in os.listdir(plugins_dir):
            results.append(f"Plugin: {item}")

# Check for local LLM runtimes
results.append("")
results.append("=== Local LLM Runtimes ===")
runtime_checks = [
    ("llama.cpp", "C:/Users/asw/AppData/Local/llama.cpp"),
    ("llama.cpp", "I:/Hermes-USB-Portable-main/.cache/runtimes"),
    ("Ollama", ollama_dir),
    ("LM Studio", lmstudio),
]
for name, path in runtime_checks:
    if os.path.exists(path):
        results.append(f"{name}: {path}")

for r in results:
    print(r)
