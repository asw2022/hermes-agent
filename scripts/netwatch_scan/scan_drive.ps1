$root = $args[0]
$folders = Get-ChildItem -Path $root -Directory -Force -ErrorAction SilentlyContinue
foreach ($f in $folders) {
    $files = Get-ChildItem -Path $f.FullName -File -Force -ErrorAction SilentlyContinue
    $size = ($files | Measure-Object -Property Length -Sum).Sum
    $count = $files.Count
    Write-Output "$($f.Name): $count files, $([math]::Round($size/1MB,1)) MB"
    $top = $files | Sort-Object Length -Descending | Select-Object -First 3
    foreach ($t in $top) {
        if ($t.Length -gt 1MB) {
            Write-Output "  $($t.Name): $([math]::Round($t.Length/1MB,1)) MB"
        }
    }
}
$filesRoot = Get-ChildItem -Path $root -File -Force -ErrorAction SilentlyContinue
foreach ($f in $filesRoot) {
    if ($f.Length -gt 1MB) {
        Write-Output "ROOT\$($f.Name): $([math]::Round($f.Length/1MB,1)) MB"
    }
}
