import subprocess
import json
import datetime
import re

def run_ps(cmd):
    result = subprocess.run(
        ["powershell", "-NoProfile", "-Command", cmd],
        capture_output=True, text=True, timeout=30
    )
    return result.stdout.strip(), result.stderr.strip()

lines = []
lines.append(f"=== Netzwerk-Überwachung {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===")

# 1. Get-NetAdapter (physisch, Status, Speed)
out, _ = run_ps("Get-NetAdapter | Where-Object { $_.InterfaceDescription -notmatch 'Virtual|Hyper-V|Bluetooth|Loopback' } | Select-Object Name, Status, LinkSpeed, InterfaceDescription | Format-List")
lines.append("[Adapter]")
for m in re.finditer(r'Name\s*:\s*(.+)\s*Status\s*:\s*(.+)\s*LinkSpeed\s*:\s*(.+)', out, re.DOTALL):
    lines.append(f"  {m.group(1).strip()} | {m.group(2).strip()} | {m.group(3).strip()}")

# 2. Get-NetIPAddress IPv4
out, _ = run_ps("Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } | Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-List")
lines.append("[IPv4]")
for m in re.finditer(r'InterfaceAlias\s*:\s*(.+)\s*IPAddress\s*:\s*(.+)\s*PrefixLength\s*:\s*(.+)', out, re.DOTALL):
    lines.append(f"  {m.group(1).strip()}: {m.group(2).strip()}/{m.group(3).strip()}")

# 3. Default Gateway
out, _ = run_ps("Get-Route 0.0.0.0/0' 2>$null | Select-Object NextHop, InterfaceAlias | Format-List")
if not run_ps("Get-Route 0.0.0.0/0'")[0].strip():
    # fallback
    lines.append("[Gateway] N/A")
else:
    lines.append("[Gateway]")

# 4. ARP (max 15)
out, _ = run_ps("Get-NetNeighbor -AddressFamily IPv4 | Where-Object State -eq 'Reachable' | Select-Object -First 15 IPAddress, LinkLayerAddress, State | Format-List")
lines.append("[ARP - Reachable Devices]")
arp_count = 0
for m in re.finditer(r'IPAddress\s*:\s*(.+)\s*LinkLayerAddress\s*:\s*(.+)\s*State\s*:\s*(.+)', out, re.DOTALL):
    arp_count += 1
    lines.append(f"  {m.group(1).strip()} -> {m.group(2).strip()}")

# 5. TCP Connections Established (max 15)
out, _ = run_ps("Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select-Object -First 15 LocalPort, RemoteAddress, RemotePort, State, OwningProcess | ForEach-Object { $_.OwningProcess }")
# Better approach
out, _ = run_ps(
    "$conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select-Object -First 15 LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess; "
    "foreach($c in $conns) { $proc = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName; Write-Output \"$($c.LocalAddress):$($c.LocalPort) -> $($c.RemoteAddress):$($c.RemotePort) [$proc]\" }"
)
lines.append("[TCP Established]")
tcp_count = 0
for line in out.splitlines():
    line = line.strip()
    if line:
        tcp_count += 1
        lines.append(f"  {line}")

# 6. Ping Router
ping_router = "FAIL"
try:
    out, _ = run_ps("Test-Connection 192.168.0.1 -Count 3 -ErrorAction SilentlyContinue | Measure-Object ResponseTime -Average | Select-Object Average")
    avg_ms = float(out.splitlines()[-1].strip())
    ping_router = f"{avg_ms:.0f}ms"
    if avg_ms > 100:
        lines.append(f"[WARNUNG] Router Ping >100ms: {avg_ms:.0f}ms")
except:
    lines.append("[WARNUNG] Router Ping FEHLGESCHLAGEN")

# 7. Ping Google DNS
ping_dns = "FAIL"
try:
    out, _ = run_ps("Test-Connection 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue | Measure-Object ResponseTime -Average | Select-Object Average")
    avg_ms = float(out.splitlines()[-1].strip())
    ping_dns = f"{avg_ms:.0f}ms"
    if avg_ms > 100:
        lines.append(f"[WARNUNG] DNS Ping >100ms: {avg_ms:.0f}ms")
except:
    lines.append("[WARNUNG] DNS Ping FEHLGESCHLAGEN")

# Summary
adapter_count = len(re.findall(r'Name\s*:', re.search(r's|Status.*LinkSpeed[\s\S]*?(\[', ').group() if re.search(r's|Status.*LinkSpeed[\s\S]*?(\[', out) else ''))
# Use actual counts from parsed data

summary = f"ZUSAMMENFASSUNG | {arp_count} ARP devices | {tcp_count} TCP conn | Router: {ping_router} | DNS: {ping_dns}"
lines.append(summary)
lines.append("")

# Write to file
content = "\n".join(lines)
with open(r"D:\Hermes-USB-Portable-main\data\netwatch\net_log.txt", "a", encoding="utf-8") as f:
    f.write(content + "\n")

print(content)
