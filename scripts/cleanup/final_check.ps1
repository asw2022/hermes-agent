$d = Get-PSDrive C
Write-Host ("C: Free=" + [math]::Round($d.Free/1GB,2) + " GB | Used=" + [math]::Round($d.Used/1GB,2) + " GB")
