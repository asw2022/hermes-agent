# ASW Projekt - Netzwerk Dokumentation
# Erstellt: 2026-06-01

## Netzwerk-Infrastruktur

### Gateway/Router
- Kabelbox: 192.168.0.1 (kabelbox.local), MAC: D4-3F-CB-7E-89-E0

### Bekannte Geraete (6)

1. **ASW-PC** (dieser PC)
   - IP: 192.168.0.46, MAC: 00-E0-4C-19-50-D3
   - OS: Windows 10, Celeron J4105, 8GB RAM
   - Rolle: Admin-PC
   - Security: RDP/SSH/SSDP/UPnP/WMP deaktiviert
   - Tools: Codex CLI, Claude Code CLI, Hermes/OpenRouter

2. **Babel-PC** (Linux Desktop)
   - IP: 192.168.0.200, MAC: 00-21-85-5A-0C-E3
   - OS: Deepin Linux, AMD Athlon 64 X2, 7.5GB RAM
   - Rolle: Server
   - Zugang: TeamViewer
   - HA: Laueft als Podman-Container auf Port 8123

3. **Fire TV Stick 4K Max**
   - IP: 192.168.0.136, MAC: 68-13-F3-F2-B3-9B
   - OS: Fire OS (Android 11)
   - Rolle: Media-Streaming
   - Zugang: ADB (C:\\tools\\platform-tools\\adb.exe)

4. **GigaBlue UHD TRIO 4K**
   - IP: 192.168.0.3, MAC: D0-27-29-0F-69-AD
   - OS: Enigma2, OpenWebif API Port 80
   - Rolle: SAT-Receiver

5. **Redmi Note 13 Pro 5G**
   - IP: 192.168.0.13, MAC: D6-88-EE-35-65-87
   - OS: Android (Xiaomi)
   - Rolle: Smartphone

### Virtuelle Adapter (ungenutzt)
- VirtualBox Host-Only #3, #4, #6
- VMware VMnet1, VMnet8
- Hyper-V Emulator NAT Switch, WP Emulator Switch
- Docker Desktop WSL2 (broken)

### Software-Notizen
- Docker Desktop Linux Engine: nicht funktional (WSL2 broken)
- Podman: funktional auf Babel-PC
- HA (Home Assistant): laeuft auf Babel-PC als Podman-Container
- Hermes Agent: auf ASW-PC, OpenRouter-basiert
- Codex CLI v0.135.0: installiert, OAuth/gpt-5.5
- Claude Code CLI v2.1.158: installiert (225MB)

### Security-Hardening (2026-06-01)
- RDP (Port 3389) deaktiviert
- SSH-Server deaktiviert (temporaer fuer Reverse-Tunnel geoeffnet)
- SSDP Discovery deaktiviert
- UPnP Device Host deaktiviert
- Windows Media Player Network Sharing deaktiviert
- CrashDumps, WER, WebCache, Prefetch, FontCache, Logs geleert
- ~53 GB auf allen Drives freigemacht
