$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$output = @()
$output += "=== NETWATCH | $ts ==="

$output += ""
$output += "-- ADAPTER --"
Get-NetAdapter | Where-Object { $_.PhysicalMediaType -ne "Unspecified" } | ForEach-Object {
    $speed = [math]::Round($_.Speed / 1MB, 0)
    $output += ("[{0}] {1} | {2} | {3} | {4} Mbps" -f $_.InterfaceIndex, $_.Name, $_.Status, $_.MediaConnectionState, $speed)
}

$output += ""
$output += "-- IPv4 --"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" } | ForEach-Object {
    $prefix = if ($_.PrefixLength) { $_.PrefixLength } else { "?" }
    $output += ("{0}/{1} -> {2} [{3}]" -f $_.IPAddress, $prefix, $_.InterfaceAlias, $_.InterfaceIndex)
}

$output += ""
$output += "-- GATEWAY --"
Get-NetRoute -DestinationPrefix "0.0.0.0/0" | ForEach-Object {
    $output += ("{0} -> {1} [{2}] Metric={3}" -f $_.DestinationPrefix, $_.NextHop, $_.InterfaceAlias, $_.RouteMetric)
}

$output += ""
$output += "-- ARP/NEIGHBORS --"
$neighbors = Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.State -eq "Reachable" } | Select-Object -First 15
if ($neighbors) {
    $neighbors | ForEach-Object {
        $output += ("{0} | {1} | {2} | {3}" -f $_.IPAddress, $_.LinkLayerAddress, $_.State, $_.InterfaceAlias)
    }
} else {
    $output += "(none)"
}

$output += ""
$output += "-- TCP ESTABLISHED --"
$tcp = Get-NetTCPConnection -State Established | Select-Object -First 15
if ($tcp) {
    $tcp | ForEach-Object {
        $proc = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        $output += ("{0}:{1} -> {2}:{3} | {4} | PID={5}" -f $_.LocalAddress, $_.LocalPort, $_.RemoteAddress, $_.RemotePort, $proc, $_.OwningProcess)
    }
} else {
    $output += "(none)"
}

$output += ""
$output += "-- PING ROUTER (192.168.0.1) --"
$pingR = Test-Connection 192.168.0.1 -Count 3 -ErrorAction SilentlyContinue
$routerOk = $true
$routerMs = 0
if ($pingR -and ($pingR | Measure-Object).Count -gt 0) {
    $routerMs = [math]::Round(($pingR | Measure-Object ResponseTime -Average).Average, 1)
    $lostR = 3 - ($pingR | Measure-Object).Count
    $output += ("Avg: {0}ms | Lost: {1}/3" -f $routerMs, $lostR)
    if ($routerMs -gt 100) {
        $output += "WARNUNG: Router Ping >100ms!"
        $routerOk = $false
    }
    if ($lostR -gt 0) {
        $output += "WARNUNG: Router Paketverlust!"
        $routerOk = $false
    }
} else {
    $output += "FAILED (no response)"
    $output += "WARNUNG: Router nicht erreichbar!"
    $routerOk = $false
}

$output += ""
$output += "-- PING DNS (8.8.8.8) --"
$pingD = Test-Connection 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue
$dnsMs = 0
if ($pingD -and ($pingD | Measure-Object).Count -gt 0) {
    $dnsMs = [math]::Round(($pingD | Measure-Object ResponseTime -Average).Average, 1)
    $lostD = 3 - ($pingD | Measure-Object).Count
    $output += ("Avg: {0}ms | Lost: {1}/3" -f $dnsMs, $lostD)
} else {
    $output += "FAILED (no response)"
}

# Counts for summary
$adapterCount = (Get-NetAdapter | Where-Object { $_.PhysicalMediaType -ne "Unspecified" } | Measure-Object).Count
$neighborCount = (Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.State -eq "Reachable" } | Measure-Object).Count
$tcpCount = (Get-NetTCPConnection -State Established | Measure-Object).Count
$routerStr = if ($routerOk) { "{0}ms" -f $routerMs } else { "{0}ms WARN" -f $routerMs }
$dnsStr = "{0}ms" -f $dnsMs

$output += ""
$output += ("SUMMARY | {0} Adapter | {1} Geraete | {2} Verbindungen | Router: {3} | DNS: {4}" -f $adapterCount, $neighborCount, $tcpCount, $routerStr, $dnsStr)

# Write to console and append to log
$logDir = "D:\Hermes-USB-Portable-main\data\netwatch"
$logFile = Join-Path $logDir "net_log.txt"

# Ensure directory exists
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# Enforce 40-line limit per entry (keep it compact)
$outLines = $output | Select-Object -First 40

$separator = "`n"
($outLines -join $separator) | Tee-Object -FilePath $logFile -Append | Write-Output
