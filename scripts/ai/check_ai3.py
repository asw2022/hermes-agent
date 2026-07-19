import os

results = []

# 1. Ollama
ollama_dir = "C:/Users/asw/AppData/Local/ollama"
if os.path.exists(ollama_dir):
    models_dir = os.path.join(ollama_dir, "models")
    if os.path.exists(models_dir):
        models = os.listdir(models_dir)
        results.append(("Ollama", f"{len(models)} models installed"))
    else:
        results.append(("Ollama", "installed, no models"))

# 2. LM Studio
lmstudio = "C:/Users/asw/AppData/Local/lm-studio"
lmstudio2 = "C:/Users/asw/.lmstudio"
if os.path.exists(lmstudio) or os.path.exists(lmstudio2):
    results.append(("LM Studio", "INSTALLED"))

# 3. ComfyUI
for comfy in ["C:/Users/asw/AppData/Local/ComfyUI", "C:/Users/asw/ComfyUI"]:
    if os.path.exists(comfy):
        results.append(("ComfyUI", f"at {comfy}"))

# 4. Stable Diffusion (various)
sd_paths = [
    "C:/Users/asw/AppData/Local/stable-diffusion",
    "C:/Users/asw/stable-diffusion",
    "C:/stable-diffusion",
]
for p in sd_paths:
    if os.path.exists(p):
        results.append(("Stable Diffusion", p))

# 5. Python ML packages
import sys as _sys
site_pkgs = set()
for sp in _sys.path:
    if 'site-packages' in sp and os.path.exists(sp):
        for pkg in ['torch', 'tensorflow', 'transformers', 'diffusers', 'llama_cpp', 'onnxruntime', 'openai', 'anthropic', 'google.generativeai']:
            if os.path.exists(os.path.join(sp, pkg)):
                site_pkgs.add(pkg)
if site_pkgs:
    results.append(("Python ML libs", ", ".join(sorted(site_pkgs))))

# 6. Check PATH for AI tools
ai_tools = ['ollama', 'llama-server', 'comfyui', 'stable-diffusion']
for tool in ai_tools:
    for path_dir in os.environ.get('PATH', '').split(';'):
        if os.path.exists(os.path.join(path_dir, tool + '.exe')):
            results.append((tool, f"in PATH at {path_dir}"))

# 7. Desktop/program shortcuts
desktop = "C:/Users/asw/Desktop"
if os.path.exists(desktop):
    for item in os.listdir(desktop):
        if any(k in item.lower() for k in ['ai', 'chat', 'gpt', 'claude', 'ollama', 'lm studio', 'stable', 'diffus', 'comfy', 'kobold', 'textgen', 'llama']):
            results.append(("Desktop shortcut", item))

# 8. Public desktop
pub_desk = "C:/Users/Public/Desktop"
if os.path.exists(pub_desk):
    for item in os.listdir(pub_desk):
        if any(k in item.lower() for k in ['ai', 'chat', 'gpt', 'claude', 'ollama', 'lm studio', 'stable', 'diffus', 'comfy']):
            results.append(("Public Desktop", item))

# 9. Hermes plugins
plugins_dir = "I:/Hermes-USB-Portable-main/data/plugins"
if os.path.exists(plugins_dir):
    for item in os.listdir(plugins_dir):
        results.append(("Hermes plugin", item))

# 10. Docker AI containers
import subprocess
try:
    dock = subprocess.run(['docker', 'ps', '-a', '--format', '{{.Names}}'], capture_output=True, text=True, timeout=5)
    if dock.returncode == 0 and dock.stdout.strip():
        for line in dock.stdout.strip().split('\n'):
            results.append(("Docker container", line))
except:
    pass

# Print
print("=== KI / AI Tools auf deinem PC ===\n")
for name, detail in results:
    print(f"  {name}: {detail}")

if not results:
    print("  Keine KI-Tools gefunden.")
