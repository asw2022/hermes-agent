$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$lines = [System.Collections.Generic.List[string]]::new()

# 1. ADAPTER (compact: only physical + status)
$lines.Add("=== NETWATCH $ts ===")
$adapters = @(Get-NetAdapter | Where-Object { $_.PhysicalMediaType -ne 'Unspecified' })
$phys = @($adapters | Where-Object { $_.Status -eq 'Up' })
$lines.Add("--- ADAPTER ---")
foreach ($a in $adapters) {
    $spd = [math]::Round($a.Speed / 1000000)
    $lines.Add("$($a.Name) $($a.Status) $($spd)Mbps")
}

# 2. IP (only non-link-local 169.254.x.x for brevity, plus main)
$lines.Add("--- IPv4 ---")
$mainIP = $null
foreach ($ip in @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' })) {
    if ($ip.IPAddress -notmatch '^169\.254\.' -and $ip.IPAddress -notmatch '^fe80') {
        $lines.Add("$($ip.InterfaceAlias) $($ip.IPAddress)/$($ip.PrefixLength)")
        if ($ip.IPAddress -match '^192\.168\.0\.') { $mainIP = $ip.IPAddress }
    }
}

# 3. Gateway
$lines.Add("--- GATEWAY ---")
$gw = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -First 1
$lines.Add("GW: $($gw.NextHop) IF: $($gw.InterfaceAlias)")

# 4. ARP (max 10)
$lines.Add("--- ARP (max 10) ---")
$neighbors = @(Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.State -in @('Reachable','Stale') } | Select-Object -First 10)
foreach ($n in $neighbors) {
    $lines.Add("$($n.IPAddress) $($n.LinkLayerAddress) $($n.State)")
}

# 5. TCP (max 10, only external)
$lines.Add("--- TCP EST (max 10) ---")
$tcpConns = @(Get-NetTCPConnection -State Established | Where-Object { $_.RemoteAddress -notmatch '^(127\.|0\.0\.0\.0|::|fe80)' } | Select-Object -First 10)
foreach ($t in $tcpConns) {
    $procName = 'Unknown'
    try { $procName = (Get-Process -Id $t.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch {}
    $ra = $t.RemoteAddress; $rp = $t.RemotePort
    $lines.Add("$procName $ra`:$rp")
}

# 6. Ping Router
$lines.Add("--- PING ROUTER ---")
$pingR = @(Test-Connection -ComputerName 192.168.0.1 -Count 3 -ErrorAction SilentlyContinue)
$avgR = $null
if ($pingR.Count -gt 0) {
    $avgR = [math]::Round(($pingR | Measure-Object -Property ResponseTime -Average).Average)
    $lines.Add("Router: $($avgR)ms")
} else {
    $lines.Add("Router: FAIL")
}

# 7. Ping DNS
$lines.Add("--- PING DNS ---")
$pingD = @(Test-Connection -ComputerName 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue)
$avgD = $null
if ($pingD.Count -gt 0) {
    $avgD = [math]::Round(($pingD | Measure-Object -Property ResponseTime -Average).Average)
    $lines.Add("DNS: $($avgD)ms")
} else {
    $lines.Add("DNS: FAIL")
}

# Warnings
if ($null -ne $avgR -and $avgR -gt 100) {
    $lines.Add("WARN: Router ping ${avgR}ms >100ms")
}
if ($pingR.Count -eq 0) {
    $lines.Add("WARN: Router UNREACHABLE")
}

# Summary
$adapterCount = @($adapters).Count
$arpCount = @($neighbors).Count
$tcpCount = @(Get-NetTCPConnection -State Established).Count
$routerSummary = if ($null -ne $avgR) { "$avgR ms" } else { 'FAIL' }
$dnsSummary = if ($null -ne $avgD) { "$avgD ms" } else { 'FAIL' }
$lines.Add("SUM: $adapterCount Adapter | $arpCount Geraete | $tcpCount Verbindungen | Router: $routerSummary | DNS: $dnsSummary")

# Cap to 40 lines
$outLines = @($lines | Select-Object -First 40)
$out = $outLines -join "`r`n"

# Append to file
$logFile = 'D:\Hermes-USB-Portable-main\data\netwatch\net_log.txt'
$dir = Split-Path $logFile -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
Add-Content -Path $logFile -Value $out
Add-Content -Path $logFile -Value ''
Write-Output $out
