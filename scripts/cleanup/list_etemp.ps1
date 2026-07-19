$items = Get-ChildItem 'E:\temp' -Force | Sort-Object Length -Descending | Select-Object -First 15
foreach ($i in $items) {
    Write-Output "$($i.Name): $([math]::Round($i.Length/1MB,1)) MB"
}
