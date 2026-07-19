$ErrorActionPreference = 'SilentlyContinue'
$logFile = 'C:\Users\asw\service_cleanup.log'

function Write-Log($msg) {
    $ts = Get-Date -Format 'HH:mm:ss'
    "$ts | $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
    Write-Host $msg
}

Write-Log '=== SERVICE CLEANUP START ==='

# Services safe to disable (not needed for most users)
$disableServices = @(
    'CDPUserSvc',         # CrossDevice / Phone Link
    'CDPSvc',             # Connected Devices Platform
    'PhoneSvc',           # Phone Service
    'Fax',                # Fax
    'wisvc',              # Windows Insider (if not needed)
    'DiagTrack',          # Diagnostics Tracking
    'dmwappushservice',   # WAP Push
    'MapsBroker',         # Downloaded Maps Manager
    'lfsvc',              # Geolocation
    'RemoteRegistry',     # Remote Registry
    'RetailDemo',         # Retail Demo
    'WbioSrvc',           # Biometric (if no fingerprint)
)

foreach ($name in $disableServices) {
    $svc = Get-Service -Name $name -EA SilentlyContinue
    if ($svc) {
        try {
            Stop-Service -Name $name -Force -EA SilentlyContinue
            Set-Service -Name $name -StartupType Disabled -EA Stop
            Write-Log "DISABLED: $($svc.DisplayName) ($name)"
        } catch {
            Write-Log "SKIP: $($svc.DisplayName) ($name) - $_"
        }
    } else {
        Write-Log "NOT FOUND: $name"
    }
}

# Disable CrossDevice specifically
Write-Log ""
Write-Log '=== CROSS DEVICE PLATFORM ==='
$cdpSvc = Get-Service -Name 'CDPSvc' -EA SilentlyContinue
$cdpUser = Get-Service -Name 'CDPUserSvc_*' -EA SilentlyContinue
if ($cdpSvc) {
    Set-Service -Name 'CDPSvc' -StartupType Disabled -EA SilentlyContinue
    Write-Log "CDPSvc disabled"
}

Write-Log ''
Write-Log '=== DONE ==='
