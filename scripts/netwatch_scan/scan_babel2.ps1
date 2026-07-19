$ip = '192.168.0.200'

Write-Output "=== Babel-PC Deep Scan ==="

# 1. Alle Ports 1-1024 scannen (schnell)
Write-Output "`n--- Schneller Portscan (1-1024) ---"
$openPorts = @()
for ($p = 1; $p -le 1024; $p++) {
    $t = New-Object System.Net.Sockets.TcpClient
    $r = $t.BeginConnect($ip, $p, $null, $null)
    $w = $r.AsyncWaitHandle.WaitOne(300)
    if ($w -and $t.Connected) {
        $openPorts += $p
        Write-Output "Port $p : OPEN"
    }
    $t.Close()
}
if ($openPorts.Count -eq 0) {
    Write-Output "Keine offenen Ports im Bereich 1-1024"
}

# 2. Versuche HTTP
Write-Output "`n--- HTTP Check ---"
try {
    $resp = Invoke-WebRequest -Uri "http://$ip" -TimeoutSec 5 -ErrorAction Stop
    Write-Output "HTTP Status: $($resp.StatusCode)"
    Write-Output "Server: $($resp.Headers['Server'])"
} catch {
    Write-Output "HTTP: Nicht erreichbar oder kein Webserver"
}

# 3. Versuche HTTPS
Write-Output "`n--- HTTPS Check ---"
try {
    $resp = Invoke-WebRequest -Uri "https://$ip" -TimeoutSec 5 -ErrorAction Stop
    Write-Output "HTTPS Status: $($resp.StatusCode)"
} catch {
    Write-Output "HTTPS: Nicht erreichbar"
}

# 4. ICMP Detail
Write-Output "`n--- ICMP Detail ---"
ping -n 3 $ip

# 5. Traceroute
Write-Output "`n--- Traceroute ---"
tracert -d -h 5 $ip 2>&1 | Select-Object -First 10 | ForEach-Object { Write-Output $_ }

# 6. MAC OUI Lookup
Write-Output "`n--- MAC Analyse ---"
$mac = "00-21-85-5A-0C-E3"
Write-Output "MAC: $mac"
Write-Output "OUI: 00-21-85"
Write-Output "Hersteller: Realtek Semiconductor (wahrscheinlich Realtek-Netzwerkadapter)"
