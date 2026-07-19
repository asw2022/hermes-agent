import subprocess

ip = '192.168.0.200'

cmd = f"""
$ip = '{ip}'
$ports = @(22,80,135,139,443,445,3389,5900,8080)
foreach ($p in $ports) {{
    $t = New-Object System.Net.Sockets.TcpClient
    $r = $t.BeginConnect($ip, $p, $null, $null)
    $w = $r.AsyncWaitHandle.WaitOne(800)
    if ($w -and $t.Connected) {{
        Write-Output \"Port $p : OPEN\"
    }}
    $t.Close()
}}
"""

r = subprocess.run(['powershell','-NoProfile','-Command', cmd], capture_output=True, timeout=20)
print(r.stdout.decode('cp1252','replace').strip()[:500])
if r.stderr:
    print("ERR:", r.stderr.decode('cp1252','replace').strip()[:200])
