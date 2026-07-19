$ip = '192.168.0.200'

Write-Output "=== Babel-PC Untersuchung ==="

# Port scan
Write-Output "`n--- Port Scan ---"
$ports = @(22,80,135,139,443,445,3389,5900,8080)
foreach ($p in $ports) {
    $t = New-Object System.Net.Sockets.TcpClient
    $r = $t.BeginConnect($ip, $p, $null, $null)
    $w = $r.AsyncWaitHandle.WaitOne(1000)
    if ($w -and $t.Connected) {
        Write-Output "Port $p : OPEN"
    }
    $t.Close()
}

# DNS
Write-Output "`n--- DNS ---"
try {
    $h = [System.Net.Dns]::GetHostEntry($ip)
    Write-Output "Hostname: $($h.HostName)"
    Write-Output "Aliases:  $($h.Aliases -join ', ')"
} catch {
    Write-Output "DNS failed"
}

# NetBIOS
Write-Output "`n--- NetBIOS ---"
nbtstat -A $ip 2>&1 | ForEach-Object { Write-Output $_ }

# ARP
Write-Output "`n--- ARP ---"
arp -a $ip 2>&1 | ForEach-Object { Write-Output $_ }

# SMB shares
Write-Output "`n--- SMB Shares ---"
net view \\$ip 2>&1 | ForEach-Object { Write-Output $_ }

# WMI query (if accessible)
Write-Output "`n--- WMI (OS Info) ---"
try {
    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ip -ErrorAction Stop
    Write-Output "OS: $($os.Caption)"
    Write-Output "Version: $($os.Version)"
    Write-Output "Build: $($os.BuildNumber)"
} catch {
    Write-Output "WMI Zugriff fehlgeschlagen (keine Admin-Rechte oder Firewall)"
}
