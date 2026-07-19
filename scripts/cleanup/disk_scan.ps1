Get-PSDrive C,D,E,G | Format-Table Name, @{N='UsedGB';E={[math]::Round($_.Used/1GB,1)}}, @{N='FreeGB';E={[math]::Round($_.Free/1GB,2)}} -AutoSize

Write-Output "`n=== C: Users/asw Ordner ==="
Get-ChildItem 'C:\Users\asw' -Directory | ForEach-Object {
    $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
    Write-Output ('{0,8:N1} MB  {1}' -f ($s/1MB), $_.FullName)
} | Sort-Object { [double]($_ -replace ' +.*','') } -Descending | Select-Object -First 10

Write-Output "`n=== C: Windows Ordner ==="
Get-ChildItem 'C:\Windows' -Directory | ForEach-Object {
    $s = (Get-ChildItem $_.FullName -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
    Write-Output ('{0,8:N1} MB  {1}' -f ($s/1MB), $_.FullName)
} | Sort-Object { [double]($_ -replace ' +.*','') } -Descending | Select-Object -First 10

Write-Output "`n=== D: Ordner ==="
Get-ChildItem 'D:\' -Directory -Force | ForEach-Object {
    $f = Get-ChildItem $_.FullName -File -Force -ErrorAction SilentlyContinue
    $s = ($f | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
    Write-Output ('{0,8:N1} MB  ({1} files)  {2}' -f ($s/1MB), $f.Count, $_.FullName)
} | Sort-Object { [double]($_ -replace ' +.*','') } -Descending | Select-Object -First 10

Write-Output "`n=== E: Ordner ==="
Get-ChildItem 'E:\' -Directory -Force | ForEach-Object {
    $f = Get-ChildItem $_.FullName -File -Force -ErrorAction SilentlyContinue
    $s = ($f | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
    Write-Output ('{0,8:N1} MB  ({1} files)  {2}' -f ($s/1MB), $f.Count, $_.FullName)
} | Sort-Object { [double]($_ -replace ' +.*','') } -Descending | Select-Object -First 10

Write-Output "`n=== G: Ordner ==="
Get-ChildItem 'G:\' -Directory -Force | ForEach-Object {
    $f = Get-ChildItem $_.FullName -File -Force -ErrorAction SilentlyContinue
    $s = ($f | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
    Write-Output ('{0,8:N1} MB  ({1} files)  {2}' -f ($s/1MB), $f.Count, $_.FullName)
} | Sort-Object { [double]($_ -replace ' +.*','') } -Descending | Select-Object -First 10
