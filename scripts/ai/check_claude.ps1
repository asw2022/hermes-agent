$claude = Get-Command claude.exe -ErrorAction SilentlyContinue
if ($claude) {
    Write-Host "FOUND: $($claude.Source)"
    & $claude.Source --version
} else {
    Write-Host "NOT in PATH"
}

# Check specific path too
$specific = "C:\Users\asw\.local\bin\claude.exe"
if (Test-Path $specific) {
    Write-Host "EXISTS at: $specific"
    & $specific --version
} else {
    Write-Host "Not at .local\bin either"
}
