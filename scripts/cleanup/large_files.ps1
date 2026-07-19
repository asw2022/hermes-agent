$ErrorActionPreference = "SilentlyContinue"

# Find large files (>100MB) in Downloads and AppData\Local
$paths = @(
    "C:\Users\asw\Downloads",
    "C:\Users\asw\AppData\Local"
)

$minSize = 100MB
$results = @()

foreach ($p in $paths) {
    if (Test-Path $p) {
        $files = Get-ChildItem -Path $p -Recurse -File -Force -ErrorAction SilentlyContinue |
                 Where-Object { $_.Length -gt $minSize } |
                 Sort-Object Length -Descending |
                 Select-Object -First 20
        foreach ($f in $files) {
            $results += [PSCustomObject]@{
                Path = $f.FullName
                SizeMB = [math]::Round($f.Length / 1MB, 1)
                LastWrite = $f.LastWriteTime
            }
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No files >100MB found"
} else {
    $totalMB = [math]::Round(($results | Measure-Object -Property SizeMB -Sum).Sum, 1)
    Write-Host ("Found " + $results.Count + " files >100MB (total ~" + $totalMB + " MB):")
    Write-Host ""
    $results | ForEach-Object {
        Write-Host ($_.SizeMB.ToString().PadLeft(8) + " MB  " + $_.Path)
    }
}
