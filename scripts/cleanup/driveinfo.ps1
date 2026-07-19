$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$usedGB = [math]::Round($drive.Used / 1GB, 2)
$totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
Write-Host ("C: Drive - Free: " + $freeGB + " GB | Used: " + $usedGB + " GB | Total: " + $totalGB + " GB")
