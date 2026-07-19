$ip = "192.168.0.3"
Write-Host "=== Ping ==="
Test-Connection -ComputerName $ip -Count 2 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ("Response: " + $_.ResponseTime + " ms") }

Write-Host ""
Write-Host "=== Port Scan ==="
$ports = @(80, 443, 8080, 8443, 9000, 3000, 5000, 8000, 8888)
foreach ($p in $ports) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $connect = $tcp.BeginConnect($ip, $p, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(800, $false)
    if ($wait -and $tcp.Connected) {
        Write-Host ("Port " + $p + " OPEN")
    }
    $tcp.Close()
}

Write-Host ""
Write-Host "=== HTTP Probe ==="
try {
    $r = Invoke-WebRequest -Uri ("http://" + $ip) -TimeoutSec 5 -ErrorAction Stop
    Write-Host ("HTTP Status: " + $r.StatusCode)
    Write-Host ("Server: " + $r.Headers["Server"])
    $title = ""
    if ($r.Content -match "<title>(.*?)</title>") { $title = $Matches[1] }
    if ($title) { Write-Host ("Title: " + $title) }
} catch {
    Write-Host ("HTTP error")
}

Write-Host ""
Write-Host "=== mDNS / Hostname ==="
try {
    $he = [System.Net.Dns]::GetHostEntry($ip)
    Write-Host ("Hostname: " + $he.HostName)
} catch {
    Write-Host "No reverse DNS"
}
