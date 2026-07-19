import subprocess

def ps(cmd, timeout=10):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Start SSH server temporarily
print("Starting SSH server...")
print(ps("Set-Service -Name 'sshd' -StartupType Manual; Start-Service -Name 'sshd'"))
print(ps("Get-Service sshd | Select-Object Name,Status,StartType | Format-List"))

# Allow SSH through firewall temporarily
print("\nFirewall rule...")
print(ps("New-NetFirewallRule -DisplayName 'SSH Temp' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -ErrorAction SilentlyContinue | Out-Null; Write-Output 'Rule added'"))

# Get current user for SSH
print("\nCurrent user:")
print(ps("$env:USERNAME"))
