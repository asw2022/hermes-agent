import subprocess

def ps(cmd, timeout=60):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

# Parallel ping sweep using runspaces
print("=== Netzwerk-Scan (192.168.0.x, 192.168.1.x, 10.x.x.x) ===")
result = ps("""
$subnets = @('192.168.0','192.168.1','10.0.0')
foreach ($subnet in $subnets) {
    1..254 | ForEach-Object -Parallel {
        $ip = "$using:subnet.$_"
        if (Test-Connection -Count 1 -Quiet -ComputerName $ip -Timeout 150) {
            try {
                $h = [System.Net.Dns]::GetHostEntry($ip).HostName
            } catch {
                $h = '?'
            }
            $mac = (Get-NetNeighbor -IPAddress $ip -ErrorAction SilentlyContinue | Select-Object -First 1).LinkLayerAddress
            Write-Output "$ip|$h|$mac"
        }
    } -ThrottleLimit 50
}
""", timeout=45)

for line in result.split('\n'):
    line = line.strip()
    if '|' in line:
        parts = line.split('|')
        ip = parts[0]
        host = parts[1] if len(parts) > 1 else '?'
        mac = parts[2] if len(parts) > 2 else '?'
        name = host if host != '?' else '(unaufloesbar)'
        print(f"  {ip}  {name}  MAC: {mac}")

if not result.strip():
    print("  Keine Geraete gefunden (oder Timeout)")

# Also check ARP for any known devices
print("\n=== ARP Cache Geraete ===")
arp = ps("Get-NetNeighbor -State Reachable,Stale -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notmatch '^127\\.' -and $_.IPAddress -notmatch '^169\\.254' -and $_.IPAddress -notmatch '^224\\.' -and $_.IPAddress -ne '255.255.255.255' -and $_.IPAddress -notmatch '^::'} | Select-Object IPAddress,LinkLayerAddress | Sort-Object IPAddress | Format-Table -AutoSize")
print(arp if arp else "  Keine")
