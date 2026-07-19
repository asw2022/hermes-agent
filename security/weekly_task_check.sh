#!/usr/bin/env bash
# Woechentlicher Sicherheits-Check: verdaechtige geplante Aufgaben + Autostart-Eintraege.
# Erkennt getarnte Malware-Persistenz (Fake-Systemdienste in AppData/Temp, Remote-Tools).
# Gibt NUR bei Fund etwas aus (still = sauber) -> als leiser Watchdog nutzbar.
export LC_ALL=C
export MSYS_NO_PATHCONV=1

FINDINGS=""

# 1. Geplante Aufgaben mit Binary in User-AppData/Temp (klassisches Malware-Muster)
TASKS=$(powershell.exe -NoProfile -Command '
Get-ScheduledTask | ForEach-Object {
  $exec = $_.Actions.Execute -join " "
  if ($exec -match "AppData\\Local\\Temp|AppData\\Local\\Microsoft\\OneDriveSyncHost|\\SvRmt\\|svcremote|svc_service|UpdateDriver\\DisplayModule") {
    "TASK: {0}  ->  {1}" -f $_.TaskName, $exec
  }
}' 2>/dev/null | tr -d '\r')
[ -n "$TASKS" ] && FINDINGS="$FINDINGS\n[VERDAECHTIGE TASKS]\n$TASKS"

# 2. Root-Level Tasks die sich als Dienst tarnen aber in AppData liegen
FAKE=$(powershell.exe -NoProfile -Command '
Get-ScheduledTask | Where-Object {$_.TaskPath -eq "\"} | ForEach-Object {
  $exec = $_.Actions.Execute -join " "
  if ($exec -match "AppData" -and $_.TaskName -match "Sync|Update|Cloud|Host|Svc|Service|Helper|Diagnostic|Graphics|Display|Defender") {
    "FAKE-DIENST: {0}  ->  {1}" -f $_.TaskName, $exec
  }
}' 2>/dev/null | tr -d '\r')
[ -n "$FAKE" ] && FINDINGS="$FINDINGS\n[GETARNTE DIENST-TASKS]\n$FAKE"

# 3. Autostart Run-Keys mit Binary in AppData/Temp
for K in "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"; do
  R=$(reg query "$K" 2>/dev/null | iconv -f CP850 -t UTF-8 2>/dev/null | tr -d '\r' | grep -iE "AppData\\\\Local\\\\Temp|AppData\\\\Local\\\\Microsoft\\\\(OneDriveSyncHost|BingSvc)|SvRmt|svcremote")
  [ -n "$R" ] && FINDINGS="$FINDINGS\n[VERDAECHTIGER RUN-KEY: $K]\n$R"
done

if [ -n "$FINDINGS" ]; then
  echo "!!! SICHERHEITS-WARNUNG $(date) !!!"
  echo "Verdaechtige Persistenz-Eintraege gefunden auf ASW-PC:"
  echo -e "$FINDINGS"
  echo ""
  echo "-> Pruefen und ggf. entfernen (siehe Malware-REPORT.md)."
  echo ""
  echo "(c) ASW"
fi
