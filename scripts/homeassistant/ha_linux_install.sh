# HA fuer Linux installieren
# Auf dem Linux-PC per Teamviewer ausfuehren:

# 1. SSH installieren (falls nicht vorhanden)
sudo apt-get update && sudo apt-get install -y openssh-server python3 python3-pip python3-venv

# 2. HA venv erstellen
sudo python3 -m venv /opt/homeassistant
sudo /opt/homeassistant/bin/pip install --upgrade pip wheel
sudo /opt/homeassistant/bin/pip install homeassistant

# 3. HA Benutzer anlegen
sudo useradd -rm homeassistant --home /home/homeassistant
sudo mkdir -p /home/homeassistant
sudo chown homeassistant:homeassistant /home/homeassistant

# 4. HA starten
sudo -u homeassistant /opt/homeassistant/bin/hass --config /home/homeassistant/.homeassistant

# HA ist dann unter http://192.168.0.200:8123 erreichbar
