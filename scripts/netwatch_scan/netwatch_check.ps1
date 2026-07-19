$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$log = 'D:\Hermes-USB-Portable-main\data\netwatch\net_log.txt'

$dir = Split-Path $log -Parent
if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

$out = @()
$out += "=== NETWATCH $ts ==="

# 1. Adapters
$out += '--- Adapter ---'
$out += (Get-NetAdapter -Physical | Select Name, Status, LinkSpeed | Format-Table -AutoSize | Out-String)

# 2. IPv4 Addresses
$out += '--- IP / Subnet ---'
$out += (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select IPAddress, PrefixLength, InterfaceAlias | Format-Table -AutoSize | Out-String)

# 3. Gateway
$out += '--- Gateway ---'
$out += (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select NextHop, InterfaceAlias, RouteMetric | Format-Table -AutoSize | Out-String)

# 4. ARP
$out += '--- ARP (max 15) ---'
$out += (Get-NetNeighbor -State Reachable,Delay,Probe -ErrorAction SilentlyContinue | Select -First 15 IPAddress, LinkLayerAddress, State | Format-Table -AutoSize | Out-String)

# 5. TCP Connections
$out += '--- TCP Established (max 15) ---'
$tcpLines = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select -First 15 | ForEach-Object {
    $proc = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    [PSCustomObject]@{
        Local  = "$($_.LocalAddress):$($_.LocalPort)"
        Remote = "$($_.RemoteAddress):$($_.RemotePort)"
        Proc   = $proc
        State  = $_.State
    }
}
$out += ($tcpLines | Format-Table -AutoSize | Out-String)

# 6. Ping Router
$out += '--- Ping Router 192.168.0.1 ---'
$pr = Test-Connection 192.168.0.1 -Count 3 -ErrorAction SilentlyContinue
if ($pr) {
    $ravg = [math]::Round(($pr | Measure-Object ResponseTime -Average).Average, 0)
    $out += "Router: OK, Avg=${ravg}ms"
    if ($ravg -gt 100) { $out += '*** WARNUNG: Router Ping >100ms! ***' }
    $routerMs = $ravg
} else {
    $out += 'Router: FAILED'
    $out += '*** WARNUNG: Router nicht erreichbar! ***'
    $routerMs = 'FAIL'
}

# 7. Ping DNS
$out += '--- Ping DNS 8.8.8.8 ---'
$pd = Test-Connection 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue
if ($pd) {
    $davg = [math]::Round(($pd | Measure-Object ResponseTime -Average).Average, 0)
    $out += "DNS: OK, Avg=${davg}ms"
    $dnsMs = $davg
} else {
    $out += 'DNS: FAILED'
    $out += '*** WARNUNG: DNS nicht erreichbar! ***'
    $dnsMs = 'FAIL'
}

# Counts
$adaptCount = (Get-NetAdapter -Physical -ErrorAction SilentlyContinue).Count
$arpCount = (Get-NetNeighbor -State Reachable,Delay,Probe -ErrorAction SilentlyContinue | Select -First 15).Count
$tcpCount = (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select -First 15).Count

$out += ''
$out += "SUMMARY | $adaptCount Adapter | $arpCount Geraete | $tcpCount Verbindungen | Router: ${routerMs}ms | DNS: ${dnsMs}ms"
$out += ''

Add-Content -Path $log -Value ($out -join "`n")
Write-Output ($out -join "`n")
