import subprocess, socket, struct, os

def ps(cmd, timeout=30):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# 1. ARP Cache - bereits bekannte Geraete
print("=== ARP Cache (bereits bekannte Geraete) ===")
arp = ps("Get-NetNeighbor -State Reachable,Stale -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notmatch '^169\\.254' -and $_.IPAddress -notmatch '^224\\.' -and $_.IPAddress -ne '255.255.255.255' } | Select-Object IPAddress,LinkLayerAddress,InterfaceAlias | Sort-Object IPAddress | Format-Table -AutoSize")
print(arp if arp else "  Leer")

# 2. Quick Ping Sweep 192.168.0.x (Hauptnetz)
print("\n=== Ping Scan 192.168.0.x (1-50) ===")
for i in range(1, 51):
    ip = f"192.168.0.{i}"
    try:
        r = subprocess.run(['ping', '-n', '1', '-w', '300', ip], capture_output=True, timeout=2)
        if r.returncode == 0:
            # Try DNS resolution
            try:
                hostname = socket.getfqdn(ip)
                if hostname == ip:
                    hostname = "(kein DNS)"
            except:
                hostname = "(unaufloesbar)"
            # Try to get MAC
            mac = "?"
            try:
                arp_r = subprocess.run(['arp', '-a', ip], capture_output=True, text=True, timeout=3)
                for line in arp_r.stdout.split('\n'):
                    if ip in line:
                        parts = line.split()
                        for p in parts:
                            if ':' in p or '-' in p:
                                mac = p.strip()
                                break
            except:
                pass
            print(f"  {ip}  HOST: {hostname}  MAC: {mac}")
    except:
        pass
