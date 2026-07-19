$ErrorActionPreference = "SilentlyContinue"

# Set ALL cleanmgr flags in the registry (0x00000001 = all items enabled)
# Using the proper registry path that cleanmgr reads for automated runs
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

# List of all items we want to clean
$items = @(
    "Active Setup Temp Folders",
    "BranchCache",
    "D3D Shader Cache",
    "Delivery Optimization Files",
    "Diagnostic Log Data Store",
    "Downloaded Program Files",
    "Internet Cache Files",
    "Old ChkDsk",
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

$set = 0
$total = $items.Count

foreach ($item in $items) {
    $fullPath = Join-Path $regPath $item
    if (Test-Path $fullPath) {
        Set-ItemProperty -Path $fullPath -Name "StateFlags0001" -Value 0x00000002 -ErrorAction SilentlyContinue
        $set++
        Write-Host "Set: $item"
    } else {
        Write-Host "Not found: $item"
    }
}

Write-Host ""
Write-Host ("Configured " + $set + " of " + $total + " items for cleanmgr")
Write-Host ""
Write-Host "Running cleanmgr /sagerun:1 ..."

# Run cleanmgr with the flags we just set
Start-Process -FilePath "cleanmgr" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden -PassThru

Write-Host ""
Write-Host "=== DONE ==="
