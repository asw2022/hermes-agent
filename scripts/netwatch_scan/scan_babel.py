import subprocess

ip = '192.168.0.200'

# Single PowerShell command for port scan + info
cmd = f"""
$ip = '{ip}'
$ports = @(22,80,135,139,443,445,3389,5900,8080)
foreach ($p in $ports) {{
    $t = New-Object System.Net.Sockets.TcpClient
    $r = $t.BeginConnect($ip, $p, $null, $null)
    $w = $r.AsyncWaitHandle.WaitOne(800)
    if ($w -and $t.Connected) {{
        Write-Output "Port $p : OPEN"
    }}
    $t.Close()
}}

# NetBIOS
$nbt = nbtstat -A $ip 2>&1
Write-Output "`nNetBIOS: $nbt"

# ARP
$arp = arp -a $ip 2>&1
Write-Output "`nARP: $arp"
"""

r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=30)
print(r.stdout.decode('cp1252','replace').strip()[:1000])
if r.stderr:
    print("ERR:", r.stderr.decode('cp1252','replace').strip()[:200])
