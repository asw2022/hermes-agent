$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$out = @()
$out += "========== Netzwerkueberwachung $ts =========="
$out += "--- Adapter ---"
$adapters = Get-NetAdapter -Physical | Select-Object Name,Status,LinkSpeed
$out += ($adapters | Format-Table -AutoSize | Out-String).Trim()
$out += "--- IPv4 ---"
$addres4 = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne '127.0.0.1' })
foreach ($a in $addres4) {
    $out += "$($a.InterfaceAlias)  $($a.IPAddress)/$($a.PrefixLength)"
}
$out += "--- Gateway ---"
$gws = @(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue)
foreach ($g in $gws) {
    $out += "GW: $($g.NextHop)  Metric: $($g.RouteMetric)  IF: $($g.InterfaceAlias)"
}
$out += "--- ARP (max 15) ---"
$neighbors = @(Get-NetNeighbor -ErrorAction SilentlyContinue | Where-Object { $_.State -in @('Reachable','Stale','Delay','Probe') } | Select-Object -First 15)
foreach ($n in $neighbors) {
    $out += "$($n.IPAddress)  $($n.LinkLayerAddress)  $($n.State)  $($n.InterfaceAlias)"
}
$out += "--- TCP Established (max 15) ---"
$tcp = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select-Object -First 15)
foreach ($t in $tcp) {
    $procName = "?"
    try { $procName = (Get-Process -Id $t.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch {}
    $out += "$procName  $($t.LocalAddress):$($t.LocalPort) -> $($t.RemoteAddress):$($t.RemotePort)"
}
$out += "--- Ping Router ---"
$router = "192.168.0.1"
if ($gws.Count -gt 0) { $router = $gws[0].NextHop }
$pingOut = $null
try { $pingOut = Test-Connection $router -Count 3 -ErrorAction Stop } catch { $out += "Router ($router): FEHLER - $_"; $pingOut = $null }
if ($pingOut) {
    $vals = @($pingOut | ForEach-Object {
        if ($_.ResponseTime) { [int]$_.ResponseTime } elseif ($_.StatusCode -eq 0) { 0 } else { $null }
    } | Where-Object { $_ -ne $null })
    if ($vals.Count -gt 0) {
        $avg = [math]::Round(($vals | Measure-Object -Average).Average)
        $mn  = ($vals | Measure-Object -Minimum).Minimum
        $mx  = ($vals | Measure-Object -Maximum).Maximum
        $loss = [math]::Round((3 - $vals.Count) / 3 * 100)
        $out += "Latency: ${avg}ms (min=${mn}ms, max=${mx}ms, ${loss}% Verlust)"
    } else {
        $out += "Router ($router): keine Latency-Daten"
    }
}
$out += "--- Ping DNS (8.8.8.8) ---"
$pingDNS = $null
try { $pingDNS = Test-Connection "8.8.8.8" -Count 3 -ErrorAction Stop } catch { $out += "DNS (8.8.8.8): FEHLER - $_"; $pingDNS = $null }
if ($pingDNS) {
    $vals2 = @($pingDNS | ForEach-Object {
        if ($_.ResponseTime) { [int]$_.ResponseTime } elseif ($_.StatusCode -eq 0) { 0 } else { $null }
    } | Where-Object { $_ -ne $null })
    if ($vals2.Count -gt 0) {
        $avg2 = [math]::Round(($vals2 | Measure-Object -Average).Average)
        $mn2  = ($vals2 | Measure-Object -Minimum).Minimum
        $mx2  = ($vals2 | Measure-Object -Maximum).Maximum
        $loss2 = [math]::Round((3 - $vals2.Count) / 3 * 100)
        $out += "Latency: ${avg2}ms (min=${mn2}ms, max=${mx2}ms, ${loss2}% Verlust)"
    } else {
        $out += "DNS (8.8.8.8): keine Latency-Daten"
    }
}
# Summary
$physCount = (@(Get-NetAdapter -Physical)).Count
$arpCount  = ($neighbors | Measure-Object).Count
$tcpCount  = (@(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue)).Count
$warn = ""
if ($vals -and ($vals | Measure-Object -Average).Average -gt 100) { $warn = " [WARNUNG: Router-Latency >100ms!]" }
$out += ""
$out += "SUM: $physCount physisch | $arpCount ARP dynamisch | $tcpCount Verbindungen | Router: $([math]::Round(($vals|Measure-Object -Average).Average))ms | DNS: $([math]::Round(($vals2|Measure-Object -Average).Average))ms$warn"
Add-Content -Path "D:\Hermes-USB-Portable-main\data\netwatch\net_log.txt" -Value ($out -join "`n")
Write-Output ($out -join "`n")
