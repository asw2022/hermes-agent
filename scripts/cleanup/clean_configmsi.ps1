$path = "G:\Config.Msi"
if (Test-Path $path) {
    $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue
    $size = ($items | Measure-Object -Property Length -Sum).Sum
    Write-Output "Config.Msi: $($items.Count) items, $([math]::Round($size/1GB,2)) GB"
    $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    $remaining = (Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Output "Remaining: $remaining items"
    Write-Output "Freed: $([math]::Round($size/1GB,2)) GB"
} else {
    Write-Output "Config.Msi: NOT FOUND"
}
