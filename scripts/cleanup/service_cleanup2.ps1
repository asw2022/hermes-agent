$ErrorActionPreference = 'SilentlyContinue'
$logFile = 'C:\Users\asw\service_cleanup.log'

function Write-Log($msg) {
    $ts = Get-Date -Format 'HH:mm:ss'
    "$ts | $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
    Write-Host $msg
}

Write-Log '=== SERVICE CLEANUP START ==='

$disableServices = @(
    'CDPUserSvc'
    'CDPSvc'
    'PhoneSvc'
    'Fax'
    'DiagTrack'
    'dmwappushservice'
    'MapsBroker'
    'lfsvc'
    'RemoteRegistry'
    'RetailDemo'
)

foreach ($name in $disableServices) {
    $svc = Get-Service -Name $name -EA SilentlyContinue
    if ($svc) {
        try {
            Stop-Service -Name $name -Force -EA SilentlyContinue
            Set-Service -Name $name -StartupType Disabled -EA Stop
            Write-Log "DISABLED: $($svc.DisplayName) ($name)"
        } catch {
            Write-Log "SKIP: $name - $_"
        }
    } else {
        Write-Log "NOT FOUND: $name"
    }
}

# CrossDevice Platform service (instance-per-user)
Write-Log '--- Cross Device Platform ---'
Get-Service -Name 'CDPUserSvc*' -EA SilentlyContinue | ForEach-Object {
    try {
        Set-Service -Name $_.Name -StartupType Disabled -EA Stop
        Write-Log "DISABLED: $($_.DisplayName) ($($_.Name))"
    } catch {
        Write-Log "SKIP: $($_.Name) - $_"
    }
}

# Phone Link / CrossDevice scheduled tasks
Write-Log '--- Phone Link Scheduled Tasks ---'
$tasks = @(
    '\Microsoft\Windows\HelloFace\*'
    '\Microsoft\Windows\CrossDevice\*'
    '\Microsoft\Windows\Phone\*'
)
# Just disable the services for now - scheduled tasks without schtasks binary

Write-Log ''
Write-Log '=== SERVICE CLEANUP COMPLETE ==='
