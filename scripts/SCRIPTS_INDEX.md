# SCRIPTS_INDEX.md — Home-Script-Bestand

Letztes Update: **2026-07-16**. Struktur echt verifiziert nach Inhalt-Scan.

## Übersicht
- **156 Scripts** liegen jetzt in `C:\Users\asw\scripts\<kategorie>\` (sortiert am 2026-07-16).
- **3 task-kritische Scripts** bleiben im Home-Root (weil geplante Tasks darauf zeilen):
  - `dashboard.py`, `dashboard_server.py` (Task `SmartHomeDash`, WD=C:\Users\asw)
  - `Mount-Hermes-VHDX.ps1` (Task `Mount-Hermes-VHDX`)
- Neben-Dateien (.html/.json/.yaml/.log/.zip) im Root **bewusst nicht** verschoben.
- **Rollback:** `C:\Users\asw\scripts\MOVE_LOG.txt` listet jede Verschiebung
  (Original-Ziel). Zum Zurückholen einfach `shutil.move` rückwärts — oder sag Bescheid.

---

## `scripts/` Kategorien (Anzahl Dateien)

| Ordner | Inhalt | # |
|---|---|---|
| `oscam/` | OSCam-Status, Parser, GUI, Reader-Tests | 9 |
| `homeassistant/` | HA Install/Check/Start/Connect, ha_docker, test_ha | 23 |
| `netwatch_scan/` | netwatch-*, scan_* (D/E/G/Local/Network/Babel), security, probe_streamer | 31 |
| `cleanup/` | Adobe-Deinstall, Temp-Clean, große Dateien, Services, disk/final/list_etemp | 46 |
| `docker/` | docker_fix/restart/compose, podman_*, check_docker | 7 |
| `ai/` | check_ai*, check_lmstudio, check_claude, test_claude | 7 |
| `adb_firetv/` | adb_*, firetv_setup, probe_streamer | 4 |
| `dashboard/` | dashboard-*.bat/ps1, run/start/setup/fix/register, start_dbg, start_server | 10 |
| `compute_hw/` | compute-benchmark, compute-test, hw_info | 3 |
| `ssh_setup/` | gen_key, gen_ssh_key, start_ssh, fix_sshd, add_path, check_python, check_venv, fix_bom | 9 |
| `diverse/` | create_task, babel_*, docker_wsl_cleanup.log, before_bytes/test_write | 7 |

**Gesamt: 156**

---

## Wichtige Tasks (nicht anfassen)
- `SmartHomeDash` → `ha-venv\pythonw.exe dashboard_server.py` (Root)
- `Mount-Hermes-VHDX` → `Mount-Hermes-VHDX.ps1` (Root)
- `Hermes_Gateway` / `OpenClaw Gateway` → AppData (nicht Home-Root)

— ASW
