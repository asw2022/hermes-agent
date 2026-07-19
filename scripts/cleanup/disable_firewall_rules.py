import subprocess

def ps(cmd, timeout=15):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Disable RDP firewall rules
print("Firewall: RDP-Regeln deaktivieren...")
result = ps("Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue | Disable-NetFirewallRule -ErrorAction SilentlyContinue; Write-Output 'OK'")
print(f"  {result}")

# Disable SSH firewall rule if exists
print("Firewall: SSH-Regel deaktivieren...")
result = ps("Get-NetFirewallRule -DisplayName '*SSH*' -ErrorAction SilentlyContinue | Disable-NetFirewallRule -ErrorAction SilentlyContinue; Write-Output 'OK'")
print(f"  {result}")

# Disable UPnP firewall rules
print("Firewall: UPnP-Regeln deaktivieren...")
result = ps("Get-NetFirewallRule -DisplayGroup 'UPnP' -ErrorAction SilentlyContinue | Disable-NetFirewallRule -ErrorAction SilentlyContinue; Write-Output 'OK'")
print(f"  {result}")

# Disable Network Discovery firewall rules
print("Firewall: Network Discovery deaktivieren...")
result = ps("Get-NetFirewallRule -DisplayGroup 'Network Discovery' -ErrorAction SilentlyContinue | Set-NetFirewallRule -Enabled False -ErrorAction SilentlyContinue; Write-Output 'OK'")
print(f"  {result}")

print("\n=== PORTS NACHHER ===")
print(ps("Get-NetTCPConnection -State Listen | Where-Object { $_.LocalAddress -eq '0.0.0.0' -and $_.LocalPort -in @(22,3389,554,1900) } | Select-Object LocalPort,OwningProcess | Format-Table -AutoSize"))
