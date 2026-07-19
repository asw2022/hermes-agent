import os

results = []

# Check all drives for AI tools
drives = ['C:', 'D:', 'E:', 'G:', 'I:']
ai_keywords = ['ollama', 'lm-studio', 'lmstudio', 'stable-diffusion', 'comfyui', 'comfy', 
               'kobold', 'textgen', 'llama', 'hugging', 'transformers', 'diffus',
               'ai-tool', 'ai_tool', 'chatgpt', 'claude', 'codex', 'copilot',
               'whisper', 'bard', 'gemini', 'mistral', 'mixtral']

for drive in drives:
    for folder in [f'{drive}/Users/asw', f'{drive}/']:
        if not os.path.exists(folder):
            continue
        try:
            for item in os.listdir(folder):
                low = item.lower().replace(' ', '').replace('-', '').replace('_', '')
                if any(k.replace('-','').replace('_','') in low for k in ai_keywords):
                    if item not in ['.', '..']:
                        results.append(f"{folder}/{item}")
        except:
            pass

# Check Program Files for AI
for pf in ["C:/Program Files", "C:/Program Files (x86)"]:
    if not os.path.exists(pf):
        continue
    try:
        for item in os.listdir(pf):
            low = item.lower()
            if any(k in low for k in ['nvidia', 'cuda', 'tensorrt', 'directml', 'openvino']):
                results.append(f"{pf}/{item}")
    except:
        pass

# Check Hermes for AI model providers
hermes_plugins = "I:/Hermes-USB-Portable-main/data/plugins"
if os.path.exists(hermes_plugins):
    ai_plugins = []
    for item in os.listdir(hermes_plugins):
        low = item.lower()
        if any(k in low for k in ['model', 'inference', 'llm', 'ai', 'openai', 'anthropic', 'openrouter', 'ollama', 'lmstudio', 'codex']):
            ai_plugins.append(item)
    if ai_plugins:
        results.append(f"Hermes AI plugins: {', '.join(ai_plugins)}")

# Check Hermes skills for AI
skills_dir = "I:/Hermes-USB-Portable-main/data/skills"
if os.path.exists(skills_dir):
    for skill in os.listdir(skills_dir):
        low = skill.lower()
        if any(k in low for k in ['ai', 'ml', 'model', 'llm', 'codex', 'claude']):
            results.append(f"Hermes skill: {skill}")

# Check for .codex auth
if os.path.exists("C:/Users/asw/.codex/auth.json"):
    results.append("Codex CLI auth: CONFIGURED")

# Summary
print("=== KI Tools & AI auf dem PC ===\n")
unique = []
for r in results:
    # Deduplicate
    base = r.split('/')[0] + '/' + r.split('/')[1] if '/' in r else r
    if base not in [u.split('/')[0] + '/' + u.split('/')[1] if '/' in u else u for u in unique]:
        unique.append(r)

for r in sorted(set(results)):
    print(f"  {r}")

print(f"\nGesamt: {len(set(results))} KI/Amp;amp;AI Einträge")
