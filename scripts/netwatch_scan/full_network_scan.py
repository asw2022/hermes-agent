import subprocess, json, socket, os
from datetime import datetime

def ps(cmd, timeout=10):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

def ping(ip, timeout=1000):
    r = subprocess.run(['ping', '-n', '1', '-w', str(timeout), ip], capture_output=True, timeout=3)
    return r.returncode == 0

devices = json.loads(open('C:/Users/asw/.homeassistant/devices.json'))['devices']
results = {}

# 1. Ping all devices
print("=== PING SCAN ===")
for name, info in devices.items():
    ip = info['ip']
    online = ping(ip, 1500)
    status = "ONLINE" if online else "OFFLINE"
    
    # DNS lookup for online devices
    hostname = "?"
    if online:
        try:
            hostname = socket.getfqdn(ip)
            if hostname == ip:
                hostname = "(kein DNS)"
        except:
            hostname = "(unaufloesbar)"
    
    results[name] = {
        "ip": ip,
        "status": status,
        "hostname": hostname,
        "type": info.get('type','?'),
        "os": info.get('os','?')
    }
    print(f"  {name:15s} {ip:16s} {status:8s} {hostname}")

# 2. Check for new devices (ARP cache vs known)
print("\n=== NEUE GERAETE ===")
known_ips = {info['ip'] for info in devices.values()}
arp_output = ps("Get-NetNeighbor -State Reachable,Stale -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notmatch '^127\\.' -and $_.IPAddress -notmatch '^169\\.254' -and $_.IPAddress -notmatch '^224\\.' -and $_.IPAddress -ne '255.255.255.255' -and $_.IPAddress -notmatch '^::'} | Select-Object IPAddress,LinkLayerAddress | Format-List")

arp_ips = {}
for line in arp_output.split('\n'):
    line = line.strip()
    if line.startswith('IPAddress'):
        ip = line.split(':')[1].strip()
    elif line.startswith('LinkLayerAddress'):
        mac = line.split(':')[1].strip()
        arp_ips[ip] = mac

new_ips = set(arp_ips.keys()) - known_ips
if new_ips:
    for ip in sorted(new_ips):
        try:
            h = socket.getfqdn(ip)
            if h == ip: h = "?"
        except:
            h = "?"
        print(f"  NEU: {ip}  MAC: {arp_ips[ip]}  Host: {h}")
else:
    print("  Keine neuen Geraete gefunden")

# 3. Port scan online devices
print("\n=== PORT SCAN (Online Geraete) ===")
for name, res in results.items():
    if res['status'] != 'ONLINE':
        continue
    ip = res['ip']
    open_ports = []
    common = [22, 80, 135, 139, 443, 445, 3389, 5900, 8080, 8123]
    for port in common:
        cmd = f"Test-NetConnection -ComputerName {ip} -Port {port} -WarningAction SilentlyContinue | Select-Object TcpTestSucceeded"
        out = ps(cmd, timeout=3)
        if 'TcpTestSucceeded : True' in out:
            open_ports.append(port)
    if open_ports:
        print(f"  {name}: {', '.join(str(p) for p in open_ports)}")
    else:
        print(f"  {name}: keine offenen Ports")

# 4. Save results
output = {
    "scan_time": datetime.now().isoformat(),
    "devices": results,
    "new_devices": [{"ip": ip, "mac": arp_ips[ip]} for ip in new_ips]
}

with open('C:/Users/asw/.homeassistant/network_status.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print("\nScan gespeichert: C:/Users/asw/.homeassistant/network_status.json")
