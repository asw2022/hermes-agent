# Mount Hermes VHDX at startup
$VhdxPath = "G:\test\Streams_Fotos_Bilder.vhdx"

# Check if already mounted (I: drive exists)
$vol = Get-Volume -DriveLetter I -ErrorAction SilentlyContinue
if ($vol) {
    Write-Host "I: already mounted, skipping."
    exit 0
}

# Mount the VHDX
Write-Host "Mounting $VhdxPath ..."
try {
    Mount-VHD -Path $VhdxPath -ReadOnly
    # Wait briefly for the volume to come online
    Start-Sleep -Seconds 3
    
    # Verify I: is now available
    $vol = Get-Volume -DriveLetter I -ErrorAction SilentlyContinue
    if ($vol) {
        Write-Host "VHDX mounted successfully. I: is online."
    } else {
        Write-Host "WARNING: VHDX mounted but I: not detected. Check Disk Management."
    }
} catch {
    Write-Host "ERROR: Failed to mount VHDX: $_"
    exit 1
}
