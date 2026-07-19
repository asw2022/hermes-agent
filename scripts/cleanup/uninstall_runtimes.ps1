$ErrorActionPreference = 'SilentlyContinue'
$logFile = 'C:\Users\asw\uninstall_runtimes.log'
$totalFreed = 0
$successCount = 0
$failCount = 0

function Write-Log($msg) {
    $ts = Get-Date -Format 'HH:mm:ss'
    "$ts | $msg" | Out-File -Append -FilePath $logFile -Encoding UTF8
    Write-Host $msg
}

Write-Log '=== RUNTIME DEINSTALLATION START ==='

# Remaining programs that failed - ONE AT A TIME with full UI
$remaining = @(
    @{Name='Microsoft Windows Desktop Runtime - 9.0.11 (x64) - Bundle'; Cmd='"C:\ProgramData\Package Cache\{59a5723a-dcf6-43d8-a8bb-a14466c9d3ca}\windowsdesktop-runtime-9.0.11-win-x64.exe"'; Args='/uninstall /quiet /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 9.0.11 (x64) - MSI'; Cmd='MsiExec.exe'; Args='/X{1291A37E-2C01-4CA2-BD4B-490B42279CB6} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 8.0.24 (x64) - Bundle'; Cmd='"C:\ProgramData\Package Cache\{a2467e34-8d77-4d67-ae7e-5edbbafbeb16}\windowsdesktop-runtime-8.0.24-win-x64.exe"'; Args='/uninstall /quiet /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 8.0.24 (x64) - MSI'; Cmd='MsiExec.exe'; Args='/X{0E6ACF40-9CC5-4B9E-96DE-AC039380D70D} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 8.0.22 (x86) - Bundle'; Cmd='"C:\ProgramData\Package Cache\{2d077ae0-4556-4d5a-aa87-4ea76e32ec2d}\windowsdesktop-runtime-8.0.22-win-x86.exe"'; Args='/uninstall /quiet /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 8.0.22 (x86) - MSI'; Cmd='MsiExec.exe'; Args='/X{AABE221C-DA7E-4DDA-9AD6-322E03B95E2D} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 8.0.11 (x64)'; Cmd='MsiExec.exe'; Args='/X{C0790AA0-0F40-4836-85B2-677B87625E63} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 8.0.11 (x86)'; Cmd='MsiExec.exe'; Args='/X{3A6767BB-A8E1-450C-B57D-11EFEB753F9C} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 7.0.20 (x64) - Bundle'; Cmd='"C:\ProgramData\Package Cache\{362ea044-f96f-45c7-b59f-0dbe5ca98ff4}\windowsdesktop-runtime-7.0.20-win-x64.exe"'; Args='/uninstall /quiet /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 7.0.20 (x64) - MSI'; Cmd='MsiExec.exe'; Args='/X{72C29BED-666F-4E5E-BC49-DF44C890742E} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 6.0.36 (x64) - Bundle'; Cmd='"C:\ProgramData\Package Cache\{0532b8f2-12d7-43de-95fc-7b87006758a8}\windowsdesktop-runtime-6.0.36-win-x64.exe"'; Args='/uninstall /quiet /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 6.0.36 (x64) - MSI'; Cmd='MsiExec.exe'; Args='/X{61D4736B-3325-4D4A-BD41-8BD206C6A86E} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 3.1.32 (x64) - MSI'; Cmd='MsiExec.exe'; Args='/X{5BEE5F3E-4D78-4DE8-A8F3-36D3E9D8868C} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 9.0.0 (x64)'; Cmd='MsiExec.exe'; Args='/X{83A47381-BFA7-46BD-9ED3-466624334FC9} /qn /norestart'},
    @{Name='Microsoft Windows Desktop Runtime - 9.0.0 (x86)'; Cmd='MsiExec.exe'; Args='/X{E922F444-418C-424C-A1AE-55AECD453D4F} /qn /norestart'},
    @{Name='Microsoft Emulator'; Cmd='"C:\ProgramData\Package Cache\{a2e12a9b-231c-46d5-b7bb-334b22e63f67}\EmulatorSetup.exe"'; Args='/uninstall /quiet'},
    @{Name='Microsoft Emulator - MSI'; Cmd='MsiExec.exe'; Args='/X{A096D552-DC70-449F-B807-A93CEEC014AA} /qn /norestart'},
    @{Name='Windows SDK'; Cmd='MsiExec.exe'; Args='/X{C756420B-C91C-4410-8092-F49C24CEF594} /qn /norestart'},
    @{Name='UniversalWindowsPlatform SDK'; Cmd='MsiExec.exe'; Args='/I{C756420B-C91C-4410-8092-F49C24CEF594} /X{C756420B-C91C-4410-8092-F49C24CEF594} /qn'}
)

foreach ($item in $remaining) {
    Write-Log "UNINSTALL: $($item.Name)"
    try {
        $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $($item.Cmd) $($item.Args)" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            Write-Log "  OK (exit $($proc.ExitCode))"
            $successCount++
        } elseif ($proc.ExitCode -eq 1618) {
            Write-Log "  RETRY: another install running, waiting 10s..."
            Start-Sleep -Seconds 10
            $proc2 = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $($item.Cmd) $($item.Args)" -Wait -PassThru -WindowStyle Hidden
            if ($proc2.ExitCode -eq 0 -or $proc2.ExitCode -eq 3010) {
                Write-Log "  OK on retry (exit $($proc2.ExitCode))"
                $successCount++
            } else {
                Write-Log "  FAIL on retry (exit $($proc2.ExitCode))"
                $failCount++
            }
        } else {
            Write-Log "  FAIL (exit $($proc.ExitCode))"
            $failCount++
        }
    } catch {
        Write-Log "  ERROR: $_"
        $failCount++
    }
}

# Now remove .NET Framework 4.6 and 4.8 Targeting Packs
$npPatterns = @(
    'Microsoft .NET Framework 4.6.1 Targeting Pack',
    'Microsoft .NET Framework 4.8.1 Targeting Pack',
    'Microsoft .NET Framework 4.8.1 SDK',
    'Microsoft ASP.NET Core 8.0.22 - Shared Framework'
)

$progs = @()
foreach ($p in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)) {
    $progs += Get-ItemProperty $p -EA SilentlyContinue
}

foreach ($pat in $npPatterns) {
    $match = $progs | Where-Object { $_.DisplayName -eq $pat -and $_.UninstallString } | Select-Object -First 1
    if ($match) {
        $cmd = $match.UninstallString.Trim('"')
        Write-Log "UNINSTALL: $($match.DisplayName)"
        try {
            if ($cmd -match '^MsiExec') {
                $msiCmd = $cmd -replace '/I\{', '/X{'
                if ($msiCmd -notmatch '/X\{') { $msiCmd = $cmd -replace '/I', '/X' }
                $execCmd = "$msiCmd /qn /norestart"
            } else {
                $execCmd = "$cmd /uninstall /quiet /norestart"
            }
            $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $execCmd" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                Write-Log "  OK"
                $successCount++
            } else {
                Write-Log "  FAIL (exit $($proc.ExitCode))"
                $failCount++
            }
        } catch {
            Write-Log "  ERROR: $_"
            $failCount++
        }
    }
}

Write-Log ""
Write-Log "=== ERGEBNIS: $successCount OK, $failCount FAIL ==="
