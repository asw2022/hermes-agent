$ip = '192.168.0.200'

Write-Output "=== Babel-PC Targeted Scan ==="

# Key ports only
$ports = @{
    21 = "FTP"
    22 = "SSH"
    23 = "Telnet"
    25 = "SMTP"
    53 = "DNS"
    80 = "HTTP"
    110 = "POP3"
    111 = "RPC"
    135 = "MS-RPC"
    139 = "NetBIOS"
    143 = "IMAP"
    389 = "LDAP"
    443 = "HTTPS"
    445 = "SMB"
    636 = "LDAPS"
    993 = "IMAPS"
    995 = "POP3S"
    1433 = "MSSQL"
    1521 = "Oracle"
    2049 = "NFS"
    3306 = "MySQL"
    3389 = "RDP"
    5432 = "PostgreSQL"
    5900 = "VNC"
    5985 = "WinRM"
    8080 = "HTTP-Alt"
    8443 = "HTTPS-Alt"
    9090 = "WebUI"
    10000 = "Webmin"
}

foreach ($p in $ports.GetEnumerator() | Sort-Object Key) {
    $t = New-Object System.Net.Sockets.TcpClient
    $r = $t.BeginConnect($ip, $p.Key, $null, $null)
    $w = $r.AsyncWaitHandle.WaitOne(800)
    if ($w -and $t.Connected) {
        Write-Output "Port $($p.Key) ($($p.Value)): OPEN"
    }
    $t.Close()
}

# MAC
Write-Output "`n=== MAC ==="
$mac = "00-21-85-5A-0C-E3"
Write-Output "MAC: $mac"
Write-Output "OUI 00-21-85: Realtek Semiconductor Corp."

# Ping
Write-Output "`n=== Ping ==="
ping -n 2 $ip | ForEach-Object { Write-Output $_ }
