# SSH Installer fuer Babel-PC (Linux)
# Auf dem Linux-PC per TeamViewer ausfuehren:

# 1. System-Update + Dependencies
sudo apt-get update && sudo apt-get install -y openssh-server curl wget git

# 2. Python 3.12 + venv installieren
sudo apt-get install -y python3 python3-pip python3-venv python3-dev

# 3. HA venv erstellen
sudo python3 -m venv /opt/homeassistant
sudo /opt/homeassistant/bin/pip install --upgrade pip wheel

# 4. Home Assistant installieren
sudo /opt/homeassistant/bin/pip install homeassistant

# 5. HA Benutzer + Config
sudo useradd -rm homeassistant
sudo mkdir -p /home/homeassistant/.homeassistant
sudo chown -R homeassistant:homeassistant /home/homeassistant

# 6. SSH-Key fuer ASW-PC eintragen
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsiBqKZyxajLmPzG4a8GLJq9AowSvso7mXjYVBGRshh asw@ASW-PC" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 7. HA Service einrichten
sudo tee /etc/systemd/system/homeassistant.service > /dev/null <<EOF
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=homeassistant
ExecStart=/opt/homeassistant/bin/hass --config /home/homeassistant/.homeassistant
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable homeassistant
sudo systemctl start homeassistant

echo "HA laueft jetzt auf Port 8123"
