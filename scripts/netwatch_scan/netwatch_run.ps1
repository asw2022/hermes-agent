$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$out = @()
$out += '===================================================='
$out += "  NetWatch  $stamp"
$out += '===================================================='

# 1. Adapter
$out += '--- ADAPTER ---'
$adapters = Get-NetAdapter -Physical | Format-List Name,Status,LinkSpeed,InterfaceDescription | Out-String
$out += $adapters.Trim()

# 2. IPv4
$out += '--- IPv4 ---'
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^169\.254' } | Format-List InterfaceAlias,IPAddress,PrefixLength | Out-String
$out += $ips.Trim()

# 3. Gateway
$out += '--- GATEWAY ---'
$gws = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Format-List InterfaceAlias,NextHop,RouteMetric | Out-String
$out += $gws.Trim()

# 4. ARP
$out += '--- ARP (Reachable, max 15) ---'
$arp = Get-NetNeighbor -State Reachable | Select-Object -First 15 IPAddress,MACAddress,InterfaceAlias | Format-List | Out-String
$out += $arp.Trim()

# 5. TCP Established
$out += '--- TCP Established (max 15) ---'
$tcp = Get-NetTCPConnection -State Established | Select-Object -First 15 | ForEach-Object {
    $p = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    [PSCustomObject]@{LA=$_.LocalAddress;LP=$_.LocalPort;RA=$_.RemoteAddress;RP=$_.RemotePort;Proc=$p}
} | Format-List | Out-String
$out += $tcp.Trim()

# 6. Ping Router
$out += '--- PING ROUTER (192.168.0.1) ---'
$pingR = Test-Connection -ComputerName 192.168.0.1 -Count 3 -ErrorAction SilentlyContinue
if ($pingR) {
    $avgR = ($pingR | Measure-Object -Property ResponseTime -Average).Average
    $out += ('avg: ' + [math]::Round($avgR,1) + 'ms')
    if ($avgR -gt 100) { $out += '[!] WARNUNG: Router Ping >100ms' }
} else {
    $out += 'FAIL - nicht erreichbar'
    $out += '[!] WARNUNG: Router nicht erreichbar'
    $avgR = -1
}

# 7. Ping DNS
$out += '--- PING DNS (8.8.8.8) ---'
$pingD = Test-Connection -ComputerName 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue
if ($pingD) {
    $avgD = ($pingD | Measure-Object -Property ResponseTime -Average).Average
    $out += ('avg: ' + [math]::Round($avgD,1) + 'ms')
} else {
    $out += 'FAIL - nicht erreichbar'
    $out += '[!] WARNUNG: Google DNS nicht erreichbar'
    $avgD = -1
}

# Summary
$adpCount = @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }).Count
$arpCount = @(Get-NetNeighbor -State Reachable | Select-Object -First 15).Count
$tcpCount = @(Get-NetTCPConnection -State Established).Count
$out += ''
$out += ('SUMMARY | Adapters:' + $adpCount + ' | Devices:' + $arpCount + ' | Conns:' + $tcpCount + ' | Router:' + [math]::Round($avgR,0) + 'ms | DNS:' + [math]::Round($avgD,0) + 'ms')
$out += ''

$result = $out -join "`n"
Write-Output $result

# Append to log
$logDir = 'D:\Hermes-USB-Portable-main\data\netwatch'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir 'net_log.txt'
Add-Content -Path $logFile -Value $result
Write-Output "[LOGGED -> $logFile]"
