# Fix sshd_config to allow user-based authorized_keys
$configFile = 'C:\ProgramData\ssh\sshd_config'
$content = Get-Content $configFile

# Change AuthorizedKeysFile to allow both user and admin keys
$content = $content -replace 'AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys', 
    'AuthorizedKeysFile .ssh/authorized_keys __PROGRAMDATA__/ssh/administrators_authorized_keys'

Set-Content -Path $configFile -Value $content -Encoding UTF8 -Force
Write-Output "sshd_config updated"

# Restart SSH
Restart-Service sshd -Force
Write-Output "SSH restarted"
