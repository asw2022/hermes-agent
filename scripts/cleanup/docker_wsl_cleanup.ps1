$ErrorActionPreference = 'SilentlyContinue'
$logFile = 'C:\Users\asw\docker_wsl_cleanup.log'

function Write-Log($msg) {
    $ts = Get-Date -Format 'HH:mm:ss'
    "$ts | $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
    Write-Host $msg
}

Write-Log '=== DOCKER / WSL CLEANUP START ==='

# Stop and unregister WSL distros
Write-Log 'Stopping WSL distros...'
wsl --terminate Debian 2>&1 | Out-Null
wsl --terminate Ubuntu 2>&1 | Out-Null
wsl --terminate docker-desktop 2>&1 | Out-Null
Start-Sleep -Seconds 5

Write-Log 'Unregistering WSL distros...'
wsl --unregister Debian 2>&1 | ForEach-Object { Write-Log "  $_" }
wsl --unregister Ubuntu 2>&1 | ForEach-Object { Write-Log "  $_" }
wsl --unregister docker-desktop 2>&1 | ForEach-Object { Write-Log "  $_" }

# Docker Desktop deinstallation
Write-Log 'Checking Docker Desktop uninstall...'
$dockerProgs = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -EA SilentlyContinue |
    Where-Object { $_.DisplayName -like '*Docker*' }

foreach ($d in $dockerProgs) {
    Write-Log "Found: $($d.DisplayName)"
    if ($d.UninstallString) {
        $cmd = $d.UninstallString.Trim('"')
        Write-Log "Uninstalling: $cmd"
        if ($cmd -match '^MsiExec') {
            $msiCmd = $cmd -replace '/I\{', '/X{'
            if ($msiCmd -notmatch '/X\{') { $msiCmd = $cmd -replace '/I', '/X' }
            $proc = Start-Process cmd.exe -ArgumentList "/c $msiCmd /qn /norestart" -Wait -PassThru -WindowStyle Hidden
        } else {
            $proc = Start-Process cmd.exe -ArgumentList "/c $cmd /uninstall /quiet /norestart" -Wait -PassThru -WindowStyle Hidden
        }
        Write-Log "  Result: exit $($proc.ExitCode)"
    }
}

# Clean up Docker data folders
Write-Log 'Cleaning Docker data folders...'
$dockerPaths = @(
    "$env:LOCALAPPDATA\Docker",
    "C:\ProgramData\Docker",
    "C:\Program Files\Docker"
)

foreach ($p in $dockerPaths) {
    if (Test-Path $p) {
        $mb = [math]::Round((Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)
        Write-Log "Removing: $p ($mb MB)"
        Remove-Item $p -Recurse -Force -EA SilentlyContinue
    }
}

# WSL feature deactivation (optional - save more space)
Write-Log 'Disabling WSL Windows feature...'
dism.exe /online /Disable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux /NoRestart 2>&1 | ForEach-Object { Write-Log "  $_" }

Write-Log ''
Write-Log '=== CLEANUP COMPLETE ==='
