$ErrorActionPreference = 'SilentlyContinue'
$logFile = "C:\Users\asw\uninstall_log.txt"
$totalFreed = 0
$successCount = 0
$failCount = 0

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
    Write-Host $msg
}

Write-Log "=== SDK DEINSTALLATION START ==="

$patterns = @(
    '*Windows Desktop Runtime*',
    '*ASP.NET Core*',
    '*MacCatalyst*',
    '*iOS.Ref*',
    '*Android.Sdk*',
    '*Maui*',
    '*UniversalWindowsPlatform*SDK*',
    '*Windows SDK*',
    '*Microsoft Emulator*',
    '*NetStandard SDK*',
    '*Portable Library*',
    '*GameInput*',
    '*Update Health*',
    '*NET Framework 4.6*',
    '*NET Framework 4.8*'
)

$progs = @()
foreach ($p in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)) {
    $progs += Get-ItemProperty $p -EA SilentlyContinue
}

$seen = @{}
$toUninstall = @()

foreach ($pat in $patterns) {
    foreach ($prog in ($progs | Where-Object { $_.DisplayName -like $pat -and $_.UninstallString })) {
        $key = $prog.PSChildName
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $toUninstall += [PSCustomObject]@{
                Name = $prog.DisplayName
                Cmd = $prog.UninstallString
                SizeMB = [math]::Round($prog.EstimatedSize/1024,0)
            }
        }
    }
}

Write-Log "Found $($toUninstall.Count) programs to uninstall"

foreach ($item in ($toUninstall | Sort-Object SizeMB -Descending)) {
    $cmd = $item.Cmd.Trim('"')
    $name = $item.Name
    
    if ($cmd -match '^MsiExec\.exe') {
        # Convert /I to /X for uninstall, add quiet
        $msiCmd = $cmd -replace '/I\{', '/X{'
        if ($msiCmd -notmatch '/X\{') {
            $msiCmd = $cmd -replace '/I', '/X'
        }
        $execCmd = "$msiCmd /qn /norestart"
    } elseif ($cmd -match '\.exe') {
        $execCmd = "$cmd /uninstall /quiet /norestart"
    } else {
        Write-Log "SKIP: $name (no recognized uninstaller)"
        continue
    }
    
    Write-Log "UNINSTALL: $name ($($item.SizeMB) MB)"
    
    try {
        $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $execCmd" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            Write-Log "  OK (exit $($proc.ExitCode))"
            $successCount++
            $totalFreed += $item.SizeMB
        } else {
            Write-Log "  FAIL (exit $($proc.ExitCode))"
            $failCount++
        }
    } catch {
        Write-Log "  ERROR: $_"
        $failCount++
    }
}

Write-Log ""
Write-Log "=== ERGEBNIS: $successCount OK, $failCount FAIL, ~$totalFreed MB freigegeben ==="
