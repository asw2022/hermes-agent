$ErrorActionPreference = 'SilentlyContinue'
$logFile = 'C:\Users\asw\uninstall_remaining.log'

function Write-Log($msg) {
    $ts = Get-Date -Format 'HH:mm:ss'
    "$ts | $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
    Write-Host $msg
}

Write-Log '=== REMAINING SDK CLEANUP ==='

$targets = @(
    'Microsoft.Android.Sdk.Windows',
    'Microsoft NetStandard SDK',
    'Microsoft .NET Framework 4.6.1 Targeting Pack',
    'Microsoft .NET Framework 4.8.1 Targeting Pack',
    'Microsoft .NET Framework 4.8 SDK',
    'Microsoft .NET Framework 4.8.1 SDK',
    'Microsoft.iOS.Ref.net9.0_18.1'
)

$progs = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -EA SilentlyContinue

foreach ($target in $targets) {
    $matches = $progs | Where-Object { $_.DisplayName -like "*$target*" -and $_.UninstallString }
    foreach ($match in $matches) {
        $sizeMB = [math]::Round($match.EstimatedSize/1024,0)
        Write-Log "UNINSTALL: $($match.DisplayName) ($sizeMB MB)"
        
        $cmd = $match.UninstallString.Trim('"')
        if ($cmd -match '^MsiExec') {
            $msiCmd = $cmd -replace '/I\{', '/X{'
            if ($msiCmd -notmatch '/X\{') { $msiCmd = $cmd -replace '/I', '/X' }
            Write-Log "  CMD: $msiCmd /qn /norestart"
            $proc = Start-Process cmd.exe -ArgumentList "/c `"$msiCmd /qn /norestart`"" -Wait -PassThru -WindowStyle Hidden
            Write-Log "  RESULT: exit $($proc.ExitCode)"
        } elseif ($cmd -match '\.exe') {
            Write-Log "  CMD: $cmd /uninstall /quiet /norestart"
            $proc = Start-Process cmd.exe -ArgumentList "/c `"$cmd`" /uninstall /quiet /norestart" -Wait -PassThru -WindowStyle Hidden
            Write-Log "  RESULT: exit $($proc.ExitCode)"
        } else {
            Write-Log "  SKIP: no recognized uninstaller"
        }
        
        Start-Sleep -Seconds 3
    }
}

# Also try to remove UWP SDK - this one is tricky
Write-Log ''
Write-Log '=== UWP SDK ==='
$uwpProgs = $progs | Where-Object { $_.DisplayName -like '*UniversalWindowsPlatform*' -and $_.UninstallString }
if ($uwpProgs) {
    foreach ($p in $uwpProgs) {
        Write-Log "FOUND: $($p.DisplayName) ($([math]::Round($p.EstimatedSize/1024,0)) MB)"
        Write-Log "  $($p.UninstallString)"
        $cmd = $p.UninstallString.Trim('"')
        if ($cmd -match '\.exe') {
            Write-Log "  Trying: $cmd /uninstall /quiet"
            $proc = Start-Process cmd.exe -ArgumentList "/c `"$cmd`" /uninstall /quiet /norestart" -Wait -PassThru -WindowStyle Hidden
            Write-Log "  RESULT: exit $($proc.ExitCode)"
        }
    }
} else {
    Write-Log 'Not found in registry'
}

Write-Log ''
Write-Log '=== COMPLETE ==='
