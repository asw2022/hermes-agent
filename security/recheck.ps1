$pat = 'AppData|Temp\\|ProgramData\\.*\.exe|SVC|OneDriveSyncHost|svcremote|pg-host'
Get-ScheduledTask | ForEach-Object {
  $e = ($_.Actions.Execute -join ' ')
  if ($e -match $pat) {
    '{0}{1}  ->  {2}' -f $_.TaskPath, $_.TaskName, $e
  }
}
