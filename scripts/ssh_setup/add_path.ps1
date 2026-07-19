$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$env:USERPROFILE\.local\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$env:USERPROFILE\.local\bin", "User")
    Write-Host "Added to user PATH"
} else {
    Write-Host "Already in user PATH"
}
# Also set for current session
$env:Path += ";$env:USERPROFILE\.local\bin"
Write-Host "Done."
