import subprocess

def ps(cmd, timeout=15):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Check if SSH is open on Babel-PC
print("=== SSH Port Check ===")
print(ps("Test-NetConnection -ComputerName 192.168.0.200 -Port 22 -WarningAction SilentlyContinue | Select-Object TcpTestSucceeded | Format-List"))

# Check for other common Linux remote access ports
print("\n=== Other Ports ===")
for port in [22, 80, 443, 3389, 5900, 5901, 8080, 8123, 9090]:
    result = ps(f"Test-NetConnection -ComputerName 192.168.0.200 -Port {port} -WarningAction SilentlyContinue | Select-Object TcpTestSucceeded | Format-List")
    if "TcpTestSucceeded" in result:
        print(f"Port {port}: OFFEN")
