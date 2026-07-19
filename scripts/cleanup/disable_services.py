import subprocess

def ps(cmd, timeout=20):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

results = []

# 1. RDP (Remote Desktop Services) - disable service and firewall
print("1/4: RDP deaktivieren...")
result = ps("Set-Service -Name 'TermService' -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name 'TermService' -Force -ErrorAction SilentlyContinue; Write-Output 'OK'")
results.append(f"RDP TermService: {result}")

# 2. SSH Server
print("2/4: SSH deaktivieren...")
result = ps("Set-Service -Name 'sshd' -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name 'sshd' -Force -ErrorAction SilentlyContinue; Write-Output 'OK'")
results.append(f"SSH sshd: {result}")

# 3. SSDP Discovery (UPnP)
print("3/4: SSDP deaktivieren...")
result = ps("Set-Service -Name 'SSDPSRV' -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name 'SSDPSRV' -Force -ErrorAction SilentlyContinue; Write-Output 'OK'")
results.append(f"SSDP: {result}")

# 4. UPnP Device Host (Media Streaming basis)
print("4: UPnP Host deaktivieren...")
result = ps("Set-Service -Name 'upnphost' -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name 'upnphost' -Force -ErrorAction SilentlyContinue; Write-Output 'OK'")
results.append(f"UPnP Host: {result}")

# 5. Windows Media Player Network Sharing
print("5: WMP Network Sharing deaktivieren...")
result = ps("Set-Service -Name 'WMPNetworkSvc' -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name 'WMPNetworkSvc' -Force -ErrorAction SilentlyContinue; Write-Output 'OK'")
results.append(f"WMPNetwork: {result}")

print("\n=== ERGEBNISSE ===")
for r in results:
    print(f"  {r}")

# Verify
print("\n=== NACHHER - Status ===")
for svc in ['TermService','sshd','SSDPSRV','upnphost','WMPNetworkSvc']:
    result = ps(f"Get-Service -Name '{svc}' -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-List")
    if result:
        print(f"{svc}: {result}")
    else:
        print(f"{svc}: NOT FOUND")
