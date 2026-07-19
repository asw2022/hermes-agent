$ErrorActionPreference = "SilentlyContinue"
$base = "C:\Users\asw\AppData\Local"
Get-ChildItem -Path $base -Directory -Force -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object {
        $d = $_.FullName
        $files = Get-ChildItem -Path $d -Recurse -File -Force -ErrorAction SilentlyContinue
        $sum = ($files | Measure-Object -Property Length -Sum).Sum
        $count = ($files | Measure-Object).Write-Host ("$([math]::Round($sum/1MB,0)) MB ($count files)  $($_.Name)")
    }
