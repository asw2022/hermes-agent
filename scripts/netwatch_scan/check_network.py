import subprocess, re

def ps(cmd, timeout=10):
    r = subprocess.run(['powershell','-NoProfile','-Command', cmd],
                       capture_output=True, timeout=timeout)
    return r.stdout.decode('cp1252','replace').strip()

print("=== Netzwerk-Adapter ===")
print(ps("Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object Name,InterfaceDescription,LinkSpeed | Format-Table -AutoSize"))

print("\n=== IP Konfiguration ===")
print(ps("Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object InterfaceAlias,IPAddress,PrefixLength | Format-Table -AutoSize"))

print("\n=== Gateway ===")
print(ps("Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object NextHop,InterfaceAlias | Format-Table -AutoSize"))

print("\n=== DNS Server ===")
print(ps("Get-DnsClientServerAddress | Where-Object {$_.AddressFamily -eq 2 -and $_.ServerAddresses.Count -gt 0} | Select-Object InterfaceAlias,ServerAddresses | Format-Table -AutoSize"))

print("\n=== WLAN Info ===")
print(ps("netsh wlan show interfaces 2>$null | Select-String 'SSID','Signal','Channel','Radio'"))

print("\n=== Aktive Verbindungen (Top 20) ===")
print(ps("Get-NetTCPConnection -State Established | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,OwningProcess | Sort-Object RemoteAddress | Select-Object -First 20 | Format-Table -AutoSize"))

print("\n=== ARP Cache (bekannte Geraete) ===")
print(ps("Get-NetNeighbor -State Reachable,Stale | Where-Object {$_.IPAddress -ne '127.0.0.1'} | Select-Object IPAddress,LinkLayerAddress,InterfaceAlias | Sort-Object IPAddress | Format-Table -AutoSize"))
