import subprocess, json, os, time
from datetime import datetime

# Simple ping monitor for Babel-PC
BABEL_IP = "192.168.0.200"
LOG_FILE = "C:/Users/asw/.homeassistant/babel_pc_status.json"

def ping(ip):
    r = subprocess.run(['ping', '-n', '1', '-w', '1000', ip], capture_output=True, timeout=3)
    return r.returncode == 0

status = {
    "device": "Babel-PC (Linux)",
    "ip": BABEL_IP,
    "mac": "00-21-85-5A-0C-E3",
    "timestamp": datetime.now().isoformat(),
    "online": ping(BABEL_IP),
    "response_ms": None
}

# Measure response time
if status["online"]:
    r = subprocess.run(['ping', '-n', '3', '-w', '1000', BABEL_IP], capture_output=True, timeout=10)
    out = r.stdout.decode('cp1252', errors='replace')
    for line in out.split('\n'):
        if 'Minimum' in line or 'Mittelwert' in line:
            status["response_ms"] = line.strip()
            break

# Save status
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
with open(LOG_FILE, 'w') as f:
    json.dump(status, f, indent=2, ensure_ascii=False)

# Print
print(f"Babel-PC Status: {'ONLINE' if status['online'] else 'OFFLINE'}")
print(f"  IP: {BABEL_IP}")
print(f"  Time: {status['timestamp']}")
if status.get('response_ms'):
    print(f"  Latency: {status['response_ms']}")
