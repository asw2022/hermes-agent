#!/bin/bash
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

set -o pipefail

COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;34m"
COLOR_SUCCESS="\033[1;32m"
COLOR_WARN="\033[1;33m"
COLOR_ERROR="\033[1;31m"
COLOR_SECTION="\033[1;36m"

info() {
    printf "%b[--]%b %s\n" "$COLOR_INFO" "$COLOR_RESET" "$1"
}

success() {
    printf "%b[OK]%b %s\n" "$COLOR_SUCCESS" "$COLOR_RESET" "$1"
}

warn() {
    printf "%b[!!]%b %s\n" "$COLOR_WARN" "$COLOR_RESET" "$1"
}

error() {
    printf "%b[XX]%b %s\n" "$COLOR_ERROR" "$COLOR_RESET" "$1" >&2
}

die() {
    error "$1"
    exit "${2:-1}"
}

section() {
    printf "\n%b──── %s ────%b\n" "$COLOR_SECTION" "$1" "$COLOR_RESET"
}

section "Nginx Proxy Configuration"

NGINX_CONF="/etc/nginx/sites-available/iptv_proxy"
NGINX_LINK="/etc/nginx/sites-enabled/iptv_proxy"

section "Prerequisite Checks"
if ! command -v nginx >/dev/null 2>&1; then
    warn "nginx is not installed."
    read -rp "Install nginx now? [y/N]: " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        info "Installing nginx packages..."
        if sudo apt update && sudo apt install -y nginx; then
            success "nginx installed successfully."
        else
            die "Failed to install nginx."
        fi
    else
        die "Aborting nginx configuration because nginx is required."
    fi
else
    success "nginx is already installed."
fi

DEFAULT_SITE_AVAILABLE="/etc/nginx/sites-available/default"
DEFAULT_SITE_ENABLED="/etc/nginx/sites-enabled/default"
if [[ -f "$DEFAULT_SITE_AVAILABLE" || -L "$DEFAULT_SITE_ENABLED" ]]; then
    warn "Default nginx site detected."
    read -rp "Disable nginx default site config ($DEFAULT_SITE_AVAILABLE)? [y/N]: " remove_default
    if [[ "$remove_default" =~ ^[Yy]$ ]]; then
        if [[ -f "$DEFAULT_SITE_AVAILABLE" ]]; then
            BACKUP_PATH="${DEFAULT_SITE_AVAILABLE}.bak.$(date +%s)"
            info "Backing up default site config to $BACKUP_PATH..."
            if sudo mv "$DEFAULT_SITE_AVAILABLE" "$BACKUP_PATH"; then
                success "Default site config backed up to $BACKUP_PATH."
            else
                die "Failed to back up default site config."
            fi
        fi
        if [[ -e "$DEFAULT_SITE_ENABLED" || -L "$DEFAULT_SITE_ENABLED" ]]; then
            info "Removing default site symlink $DEFAULT_SITE_ENABLED..."
            if sudo rm -f "$DEFAULT_SITE_ENABLED"; then
                success "Default site symlink removed."
            else
                die "Failed to remove default site symlink."
            fi
        fi
    else
        die "Cannot proceed while the default site is enabled."
    fi
fi

if ! systemctl is-active --quiet fcgiwrap; then
    warn "fcgiwrap is not running."
    read -rp "Install and start fcgiwrap now? [y/N]: " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        info "Installing fcgiwrap..."
        if sudo apt update && sudo apt install -y fcgiwrap; then
            success "fcgiwrap package installed."
        else
            die "Failed to install fcgiwrap."
        fi
        info "Enabling and starting fcgiwrap service..."
        if sudo systemctl enable --now fcgiwrap; then
            success "fcgiwrap is running."
        else
            die "Failed to enable or start fcgiwrap."
        fi
    else
        die "Aborting nginx configuration because fcgiwrap is required."
    fi
else
    success "fcgiwrap service is active."
fi

section "Portal Storage"
if [[ ! -d "/var/www/stalker" ]]; then
    info "Creating /var/www/stalker..."
        sudo mkdir -p /var/www/stalker || die "Failed to create /var/www/stalker."
fi
sudo chown "$USER":www-data /var/www/stalker || die "Failed to set ownership on /var/www/stalker."
sudo chmod 2775 /var/www/stalker || die "Failed to set permissions on /var/www/stalker."
success "Portal data directory prepared."

STATS_SOURCE_DIR="./html"
STATS_TARGET_DIR="/var/www/stalker/html"
STATS_TARGET_FILE="$STATS_TARGET_DIR/index.html"
PORTAL_REGISTRY_SOURCE="./portals.list"
PORTAL_REGISTRY_TARGET="/var/www/stalker/portals.list"

section "Stats Assets & Registry"
sudo mkdir -p "$STATS_TARGET_DIR" || die "Failed to create $STATS_TARGET_DIR."
if [[ -d "$STATS_SOURCE_DIR" ]]; then
    info "Syncing stats assets to $STATS_TARGET_DIR..."
    if sudo rsync -a --delete "$STATS_SOURCE_DIR/" "$STATS_TARGET_DIR/"; then
        success "Stats assets synchronized."
    else
        die "Failed to sync stats assets."
    fi
else
    if [[ ! -f "$STATS_TARGET_FILE" ]]; then
        info "Creating placeholder stats page at $STATS_TARGET_FILE..."
        if ! sudo tee "$STATS_TARGET_FILE" >/dev/null <<'PLACEHOLDER'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>Portal Statistics</title>
    <style>body{font-family:sans-serif;background:#111;color:#eee;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}main{text-align:center}a{color:#9fd4ff}</style>
</head>
<body>
    <main>
        <h1>Portal Statistics</h1>
        <p>No statistics have been generated yet.</p>
        <p>Deploy the stats UI assets to publish the latest snapshot.</p>
    </main>
</body>
</html>
PLACEHOLDER
        then
            die "Failed to create placeholder stats page."
        fi
        success "Placeholder stats page created at $STATS_TARGET_FILE."
        fi
fi
sudo chown -R www-data:www-data "$STATS_TARGET_DIR" || die "Failed to set ownership on $STATS_TARGET_DIR."
sudo chmod -R 775 "$STATS_TARGET_DIR" || die "Failed to set permissions on $STATS_TARGET_DIR."
success "Stats directory permissions updated."

if [[ -f "$PORTAL_REGISTRY_SOURCE" && "$PORTAL_REGISTRY_SOURCE" != "$PORTAL_REGISTRY_TARGET" ]]; then
    info "Copying portal registry to $PORTAL_REGISTRY_TARGET..."
    sudo cp "$PORTAL_REGISTRY_SOURCE" "$PORTAL_REGISTRY_TARGET" || die "Failed to copy portal registry."
elif [[ ! -f "$PORTAL_REGISTRY_TARGET" ]]; then
    info "Creating empty portal registry at $PORTAL_REGISTRY_TARGET..."
    sudo touch "$PORTAL_REGISTRY_TARGET" || die "Failed to create portal registry file."
fi
sudo chown "$USER":www-data "$PORTAL_REGISTRY_TARGET" || die "Failed to set ownership on portal registry."
sudo chmod 664 "$PORTAL_REGISTRY_TARGET" || die "Failed to set permissions on portal registry."
success "Portal registry ready."

NGINX_SCRIPTS_DIR="./nginx"

section "Helper Scripts"
if [[ -f "$NGINX_SCRIPTS_DIR/iptv_proxy.sh" ]]; then
    info "Deploying iptv_proxy.sh..."
    sudo cp "$NGINX_SCRIPTS_DIR/iptv_proxy.sh" /var/www/stalker/iptv_proxy.sh || die "Failed to copy iptv_proxy.sh."
    sudo chown www-data:www-data /var/www/stalker/iptv_proxy.sh || die "Failed to set ownership on iptv_proxy.sh."
    sudo chmod 755 /var/www/stalker/iptv_proxy.sh || die "Failed to set permissions on iptv_proxy.sh."
    success "iptv_proxy.sh deployed."
else
    warn "iptv_proxy.sh not found in $NGINX_SCRIPTS_DIR; skipping deployment."
fi

if [[ -f "$NGINX_SCRIPTS_DIR/mac_order.py" ]]; then
    info "Deploying mac_order.py..."
    sudo cp "$NGINX_SCRIPTS_DIR/mac_order.py" /var/www/stalker/mac_order.py || die "Failed to copy mac_order.py."
    sudo chown www-data:www-data /var/www/stalker/mac_order.py || die "Failed to set ownership on mac_order.py."
    sudo chmod 755 /var/www/stalker/mac_order.py || die "Failed to set permissions on mac_order.py."
    success "mac_order.py deployed."
else
    warn "mac_order.py not found in $NGINX_SCRIPTS_DIR; skipping deployment."
fi

if [[ -f "$NGINX_SCRIPTS_DIR/stats_api.sh" ]]; then
    info "Deploying stats_api.sh..."
    sudo cp "$NGINX_SCRIPTS_DIR/stats_api.sh" /var/www/stalker/stats_api.sh || die "Failed to copy stats_api.sh."
    sudo chown www-data:www-data /var/www/stalker/stats_api.sh || die "Failed to set ownership on stats_api.sh."
    sudo chmod 755 /var/www/stalker/stats_api.sh || die "Failed to set permissions on stats_api.sh."
    success "stats_api.sh deployed."
else
    warn "stats_api.sh not found in $NGINX_SCRIPTS_DIR; skipping deployment."
fi

if [[ -f "$NGINX_SCRIPTS_DIR/stats_log_api.sh" ]]; then
    info "Deploying stats_log_api.sh..."
    sudo cp "$NGINX_SCRIPTS_DIR/stats_log_api.sh" /var/www/stalker/stats_log_api.sh || die "Failed to copy stats_log_api.sh."
    sudo chown www-data:www-data /var/www/stalker/stats_log_api.sh || die "Failed to set ownership on stats_log_api.sh."
    sudo chmod 755 /var/www/stalker/stats_log_api.sh || die "Failed to set permissions on stats_log_api.sh."
    success "stats_log_api.sh deployed."
else
    warn "stats_log_api.sh not found in $NGINX_SCRIPTS_DIR; skipping deployment."
fi

section "Nginx Configuration"
info "Writing nginx configuration to $NGINX_CONF..."
if ! sudo bash -c "cat > $NGINX_CONF" <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location = /stats {
        return 302 /stats/;
    }

    location /stats/ {
        alias /var/www/stalker/html/;
        autoindex off;
        default_type text/html;
        try_files $uri $uri/ /stats/index.html;
    }

    location = /stats/data.json {
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        include       fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/stalker/stats_api.sh;
        fastcgi_param PATH_INFO $uri;
        fastcgi_param REQUEST_URI $request_uri;
    }

    location = /stats/logs.json {
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        include       fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/stalker/stats_log_api.sh;
        fastcgi_param PATH_INFO $uri;
        fastcgi_param REQUEST_URI $request_uri;
    }

    # VOD playlist block FIRST, more specific regex
    location ~ ^/([a-zA-Z0-9_-]+)/proxy_\1_vod\.m3u$ {
        set $portal $1;
        set $playlist_path /$portal/proxy_${portal}_vod.m3u;
        root /var/www/stalker;
        try_files $playlist_path =404;
        default_type application/x-mpegURL;
    }
    # TV playlist block SECOND
    location ~ ^/([a-zA-Z0-9_-]+)/proxy_\1\.m3u$ {
        set $portal $1;
        set $playlist_path /$portal/proxy_${portal}.m3u;
        root /var/www/stalker;
        try_files $playlist_path =404;
        default_type application/x-mpegURL;
    }
    # VOD proxy block for file extensions
    location ~ ^/([a-zA-Z0-9_-]+)/([0-9]+\.(mkv|mp4|avi|mov))$ {
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        include       fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/stalker/iptv_proxy.sh;
        fastcgi_param PATH_INFO $uri;
        fastcgi_param REQUEST_URI $request_uri;
    }
    # TV proxy block for numeric channel IDs
    location ~ ^/([a-zA-Z0-9_-]+)/([0-9]+)$ {
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        include       fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/stalker/iptv_proxy.sh;
        fastcgi_param PATH_INFO $uri;
        fastcgi_param REQUEST_URI $request_uri;
    }
}
EOF
then
    die "Failed to write nginx configuration."
fi
success "Nginx IPTV proxy config written to $NGINX_CONF."

if [[ -e "$NGINX_LINK" || -L "$NGINX_LINK" ]]; then
    info "Removing existing nginx symlink $NGINX_LINK..."
    sudo rm -f "$NGINX_LINK" || die "Failed to remove existing nginx symlink."
fi
info "Linking $NGINX_CONF into sites-enabled..."
sudo ln -s "$NGINX_CONF" "$NGINX_LINK" || die "Failed to create nginx sites-enabled symlink."
success "Symlink created at $NGINX_LINK."

section "Service Reload"
info "Testing nginx configuration..."
if sudo nginx -t; then
    success "nginx configuration test passed."
else
    die "nginx configuration test failed."
fi

info "Reloading nginx..."
if sudo systemctl reload nginx; then
    success "nginx reloaded successfully."
else
    die "Failed to reload nginx."
fi

success "Nginx proxy configuration completed."
printf "\n%b==> Press Enter to return to the menu...%b" "$COLOR_SECTION" "$COLOR_RESET"
read -r _