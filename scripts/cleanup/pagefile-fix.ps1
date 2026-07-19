
# Pagefile-Umstellung - als Administrator ausfuehren
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

# C: ganz entfernen (0 0 = systemmanaged = de facto aus bei AutomaticManaged=$false), D: 6GB fest
Set-ItemProperty -Path $regPath -Name "PagingFiles" -Value @("C:\pagefile.sys 0 0", "D:\pagefile.sys 6144 6144", "A:\pagefile.sys 1900 1900") -Type MultiString

# Automatische Verwaltung deaktivieren
$cs = Get-CimInstance Win32_ComputerSystem
$cs | Set-CimInstance -Property @{AutomaticManagedPagefile = $false}

$verify = (Get-ItemProperty -Path $regPath -Name "PagingFiles").PagingFiles
Write-Output "Neue Konfiguration: $verify"
Write-Output ""
Write-Output "C: 0 0 = kein Pagefile (nach Neustart)"
Write-Output "D: 6144 6144 = 6 GB fest auf D:"  
Write-Output "A: 1900 1900 = 1.9 GB (unveraendert)"
Write-Output ""
Write-Output "! Neustart erforderlich !"
