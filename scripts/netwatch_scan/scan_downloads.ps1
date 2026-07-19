$ErrorActionPreference = "SilentlyContinue"
$dl = "C:\Users\asw\Downloads"
Get-ChildItem -Path $dl -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } |
    Sort-Object Length -Descending |
    Select-Object -First 20 |
    ForEach-Object { "$([math]::Round($_.Length/1MB,1)) MB`t$($_.FullName)" }
