$ErrorActionPreference = "SilentlyContinue"

# Enable all cleanmgr flags for sagerun:1
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

$items = @(
    "Active Setup Temp Folders",
    "BranchCache",
    "D3D Shader Cache",
    "Delivery Optimization Files",
    "Diagnostic Log Data Store",
    "Downloaded Program Files",
    "Internet Cache Files",
    "Old ChkDsk Files",
    "Previous Installations",
    "Recycle Bin",
    "Setup Log Files",
    "System error memory dump files",
    "System error minidump files",
    "Temporary Files",
    "Temporary Setup Files",
    "Thumbnail Cache",
    "Update Cleanup",
    "User file versions",
    "Windows Defender",
    "Windows Error Reporting Archive Files",
    "Windows Error Reporting Queue Files",
    "Windows Error Reporting System Archive Files",
    "Windows Error Reporting System Queue Files",
    "Windows ESD installation files",
    "Windows Upgrade Log Files"
)

$setCount = 0
foreach ($item in $items) {
    $fullPath = Join-Path $regPath $item
    if (Test-Path $fullPath) {
        Set-ItemProperty -Path $fullPath -Name "StateFlags0001" -Value 0x00000002 -ErrorAction SilentlyContinue
        $setCount++
    }
}
Write-Host "Configured $setCount items"

# Run cleanmgr silently with our preset
Write-Host "Starting cleanmgr /sagerun:1 ..."
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden

Write-Host "Started. Check progress via Task Manager (cleanmgr.exe) or wait ~1-5 min."
