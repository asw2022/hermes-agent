import subprocess

def ps(cmd, timeout=15):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

print("=" * 60)
print("NETZWERK-VERKEHR NACH PROZESS")
print("=" * 60)

# Get all TCP connections with process names
result = ps("""
Get-NetTCPConnection -State Established | Where-Object { $_.RemoteAddress -notmatch '^127\\.' } | ForEach-Object {
    $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $procName = if($proc) { $proc.ProcessName } else { "PID:"+$_.OwningProcess }
    Write-Output "$procName|$($_.LocalAddress):$($_.LocalPort)|$($_.RemoteAddress):$($_.RemotePort)"
} | Sort-Object
""", timeout=15)

# Group by process
conns = {}
for line in result.split('\n'):
    line = line.strip()
    if '|' not in line:
        continue
    parts = line.split('|')
    proc = parts[0]
    local = parts[1]
    remote = parts[2] if len(parts) > 2 else ''
    if proc not in conns:
        conns[proc] = []
    conns[proc].append(f"  {local} -> {remote}")

for proc, lines in sorted(conns.items()):
    print(f"\n[{proc}] ({len(lines)} Verbindungen)")
    for l in lines:
        print(l)

print("\n" + "=" * 60)
print("OFFENE LISTENING-PORTS")
print("=" * 60)

result2 = ps("""
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalAddress -match '^(0\\.0\\.0\\.0|127\\.|192\\.168\\.)' } | ForEach-Object {
    $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $procName = if($proc) { $proc.ProcessName } else { "PID:"+$_.OwningProcess }
    Write-Output "$procName|$($_.LocalAddress):$($_.LocalPort)"
} | Sort-Object
""", timeout=15)

listeners = {}
for line in result2.split('\n'):
    line = line.strip()
    if '|' not in line:
        continue
    proc, addr = line.split('|', 1)
    if proc not in listeners:
        listeners[proc] = []
    listeners[proc].append(addr)

for proc, addrs in sorted(listeners.items()):
    print(f"\n[{proc}]")
    for a in addrs:
        print(f"  LAUSCHT auf {a}")

print("\n" + "=" * 60)
print("SICHERHEITS-CHECK")
print("=" * 60)

# Check for suspicious: listening on 0.0.0.0 with high port
print("\n[WAN-Faehige Ports (0.0.0.0)]")
result3 = ps("""
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalAddress -eq '0.0.0.0' } | ForEach-Object {
    $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    $procName = if($proc) { $proc.ProcessName+" (PID:"+$_.OwningProcess+")" } else { "PID:"+$_.OwningProcess }
    Write-Output "$procName | Port $($_.LocalPort)"
} | Sort-Object
""", timeout=15)
print(result3 if result3 else "  Keine")

# Windows Firewall status
print("\n[Firewall Status]")
result4 = ps("Get-NetFirewallProfile | Format-Table Name,Enabled -AutoSize")
print(result4 if result4 else "  Check fehlgeschlagen")

# Check for RDP
print("\n[RDP / Remote Desktop]")
result5 = ps("Get-ItemProperty 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue | Select-Object fDenyTSConnections | Format-List")
print(result5 if result5 else "  Nicht konfiguriert")

# Check UAC
print("\n[UAC]")
result6 = ps("Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System' -Name EnableLUA -ErrorAction SilentlyContinue | Select-Object EnableLUA | Format-List")
print(result6 if result6 else "  Nicht konfiguriert")
