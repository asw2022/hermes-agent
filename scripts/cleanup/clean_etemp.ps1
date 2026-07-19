$temp = "E:\temp"
$items = Get-ChildItem -Path $temp -Force -ErrorAction SilentlyContinue
$total = 0
$deleted = 0
foreach ($i in $items) {
    try {
        if ($i.PSIsContainer) {
            Remove-Item $i.FullName -Force -Recurse -ErrorAction Stop
        } else {
            $total += $i.Length
            Remove-Item $i.FullName -Force -ErrorAction Stop
        }
        $deleted++
    } catch {
        # skip locked files
    }
}
$remaining = (Get-ChildItem -Path $temp -Force -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Output "Deleted: $deleted items"
Write-Output "Freed: $([math]::Round($total/1GB,2)) GB"
Write-Output "Remaining: $remaining"
