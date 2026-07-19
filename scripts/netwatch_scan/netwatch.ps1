$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$lines = @()
$lines += "=== NETWATCH $ts ==="

# 1. Adapter
$adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
foreach ($a in $adapters) {
    $lines += "ADAPTER: $($a.Name) | $($a.Status) | $($a.LinkSpeed)"
}

# 2. IPs
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' }
foreach ($ip in $ips) {
    $lines += "  IP: $($ip.IPAddress)/$($ip.PrefixLength) [$($ip.InterfaceAlias)]"
}

# 3. Gateways
$gws = Get-NetRoute -DestinationPrefix '0.0.0.0/0'
foreach ($gw in $gws) {
    $lines += "  GW: $($gw.NextHop) [$($gw.InterfaceAlias)]"
}

# 4. ARP (max 15)
$neighbors = Get-NetNeighbor | Where-Object { $_.State -eq 'Reachable' } | Select-Object -First 15
$arpCount = 0
foreach ($n in $neighbors) {
    $lines += "  ARP: $($n.IPAddress) -> $($n.LinkLayerAddress)"
    $arpCount++
}

# 5. TCP Established (max 15)
$tcpConns = Get-NetTCPConnection -State Established | Select-Object -First 15
$tcpCount = 0
foreach ($t in $tcpConns) {
    $proc = try { (Get-Process -Id $t.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { 'N/A' }
    $lines += "  TCP: $($t.LocalAddress):$($t.LocalPort) -> $($t.RemoteAddress):$($t.RemotePort) [$proc]"
    $tcpCount++
}

# 6. Ping Router
$routerIP = ($gws | Select-Object -First 1).NextHop
if ($routerIP) {
    $pingR = Test-Connection $routerIP -Count 3 -ErrorAction SilentlyContinue
    if ($pingR) {
        $avgR = [math]::Round(($pingR | Measure-Object -Property ResponseTime -Average).Average, 1)
        $lines += "  PING ROUTER ($routerIP): ${avgR}ms"
        if ($avgR -gt 100) {
            $lines += "    *** WARNUNG: ROUTER LATENZ HOCH (${avgR}ms) ***"
        }
    } else {
        $avgR = -1
        $lines += "  PING ROUTER ($routerIP): FAILED"
        $lines += "    *** WARNUNG: ROUTER NICHT ERREICHBAR! ***"
    }
} else {
    $avgR = -1
    $lines += "  PING ROUTER: NO GATEWAY FOUND"
    $lines += "    *** WARNUNG: KEIN GATEWAY GEFUNDEN! ***"
}

# 7. Ping Google DNS
$pingD = Test-Connection 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue
if ($pingD) {
    $avgD = [math]::Round(($pingD | Measure-Object -Property ResponseTime -Average).Average, 1)
    $lines += "  PING DNS (8.8.8.8): ${avgD}ms"
} else {
    $avgD = -1
    $lines += "  PING DNS (8.8.8.8): FAILED"
    $lines += "    *** WARNUNG: DNS NICHT ERREICHBAR! ***"
}

$lines += ""

$logDir = "D:\Hermes-USB-Portable-main\data\netwatch"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$lines | Out-File -Append -FilePath "$logDir\net_log.txt" -Encoding utf8

# Summary
$adCount = ($adapters | Measure-Object).Count
$routerStr = if ($avgR -lt 0) { "FAIL" } else { "${avgR}ms" }
$dnsStr = if ($avgD -lt 0) { "FAIL" } else { "${avgD}ms" }
Write-Output "SUMMARY: $adCount Adapter | $arpCount Geraete | $tcpCount Verbindungen | Router: $routerStr | DNS: $dnsStr"
