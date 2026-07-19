$ip = "192.168.0.3"
Write-Host "=== Ping ==="
Test-Connection -ComputerName $ip -Count 2 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ("Response from " + $_.Address + ": " + $_.ResponseTime + " ms") }

Write-Host ""
Write-Host "=== Port Scan (common) ==="
$ports = @(80, 443, 8080, 8443, 9000, 3000, 5000, 8000, 8888, 49152)
foreach ($p in $ports) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $connect = $tcp.BeginConnect($ip, $p, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(500, $false)
    if ($wait -and $tcp.Connected) {
        Write-Host ("Port " + $p + " OPEN")
    }
    $tcp.Close()
}

Write-Host ""
Write-Host "=== HTTP Probe ==="
try {
    $r = Invoke-WebRequest -Uri "http://$ip" -TimeoutSec 5 -ErrorAction SilentlyContinue
    Write-Host ("HTTP " + $r.StatusCode + " - " + $r.Headers["Server"])
    Write-Host ("Title: " + ($r.Content -match '<title>(.*?)</title>' | Out-Null; $Matches[1]))
} catch {
    Write-Host ("HTTP failed: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "=== mDNS / hostname ==="
try {
    $hostEntry = [System.Net.Dns]::GetHostEntry($ip)
    Write-Host ("Hostname: " + $hostEntry.HostName)
} catch {
    Write-Host "No reverse DNS"
}
