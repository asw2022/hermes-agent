#!/bin/bash
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;34m"
COLOR_SUCCESS="\033[1;32m"
COLOR_WARN="\033[1;33m"
COLOR_ERROR="\033[1;31m"

log_info() {
  printf "%b[--]%b %s\n" "$COLOR_INFO" "$COLOR_RESET" "$1"
}

log_success() {
  printf "%b[OK]%b %s\n" "$COLOR_SUCCESS" "$COLOR_RESET" "$1"
}

log_warn() {
  printf "%b[!!]%b %s\n" "$COLOR_WARN" "$COLOR_RESET" "$1"
}

log_error() {
  printf "%b[XX]%b %s\n" "$COLOR_ERROR" "$COLOR_RESET" "$1" >&2
}

DEPENDENCY_LOG="${TMPDIR:-/tmp}/portal_manager_dep_install.log"

run_dependency_step() {
  local description="$1"
  shift
  log_info "$description"
  if "$@" >>"$DEPENDENCY_LOG" 2>&1; then
    log_success "$description complete."
    return 0
  fi
  log_error "$description failed. See $DEPENDENCY_LOG for details."
  return 1
}

install_missing_dependencies() {
  : > "$DEPENDENCY_LOG"
  run_dependency_step "Updating apt package index" sudo apt-get update || return 1
  run_dependency_step "Installing packages (${MISSING_CMDS[*]})" sudo apt-get install -y "${MISSING_CMDS[@]}" || return 1

  local verify_missing=()
  for cmd in "${MISSING_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      verify_missing+=("$cmd")
    fi
  done

  if [[ ${#verify_missing[@]} -gt 0 ]]; then
    log_error "Installation finished but still missing: ${verify_missing[*]}. See $DEPENDENCY_LOG."
    return 1
  fi

  log_success "Dependencies installed successfully. Please re-run this script. Log saved to $DEPENDENCY_LOG."
  return 0
}

DIALOG_BACKTITLE="IPTV Stalker Portal Manager v2.22 © tem_invictus 2025"

REQUIRED_CMDS=(dialog awk sed grep bash fzf curl jq python3 rsync)
MISSING_CMDS=()
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    MISSING_CMDS+=("$cmd")
  fi
done

if [[ ${#MISSING_CMDS[@]} -gt 0 ]]; then
  MSG="Required command(s) missing: ${MISSING_CMDS[*]}\n\nInstall them automatically now? (Requires sudo)\nLogs: $DEPENDENCY_LOG"

  if command -v dialog >/dev/null 2>&1 && [[ ! " ${MISSING_CMDS[*]} " =~ " dialog " ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --yesno "$MSG" 10 75
    if [[ $? -eq 0 ]]; then
      if install_missing_dependencies; then
        dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Dependencies installed successfully. Log saved to $DEPENDENCY_LOG.\n\nPlease re-run the script." 9 70
        exit 0
      else
        dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Installation failed. Check $DEPENDENCY_LOG for details and install manually: ${MISSING_CMDS[*]}" 9 75
        exit 1
      fi
    else
      dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Cannot continue without required commands. Install manually: ${MISSING_CMDS[*]}" 8 70
      exit 1
    fi
  else
    log_warn "Required command(s) missing: ${MISSING_CMDS[*]}"
    read -rp "Install missing dependencies now? (y/N): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      if install_missing_dependencies; then
        exit 0
      fi
      log_error "Dependency installation failed. Review $DEPENDENCY_LOG for troubleshooting."
      exit 1
    else
      log_error "Cannot continue without: ${MISSING_CMDS[*]}"
      exit 1
    fi
  fi
fi

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
NGINX_SCRIPT_DIR="$SCRIPT_ROOT/nginx"
export DIALOGRC="$SCRIPT_ROOT/dialogrc_custom"

PORTAL_DATA_BASE="/var/www/stalker"
PORTAL_REGISTRY_DEFAULT="$PORTAL_DATA_BASE/portals.list"
PORTAL_REGISTRY="${PORTAL_REGISTRY:-$PORTAL_REGISTRY_DEFAULT}"
LEGACY_PORTAL_REGISTRY="$SCRIPT_ROOT/portals.list"

ensure_portal_registry_location() {
  local registry_dir
  registry_dir=$(dirname "$PORTAL_REGISTRY")

  if [[ ! -d "$registry_dir" ]]; then
    sudo mkdir -p "$registry_dir"
    sudo chown "$USER":www-data "$registry_dir"
    sudo chmod 2775 "$registry_dir"
  fi

  if [[ -f "$LEGACY_PORTAL_REGISTRY" && ! -f "$PORTAL_REGISTRY" ]]; then
    sudo cp "$LEGACY_PORTAL_REGISTRY" "$PORTAL_REGISTRY"
  elif [[ ! -f "$PORTAL_REGISTRY" ]]; then
    sudo touch "$PORTAL_REGISTRY"
  fi

  sudo chown "$USER":www-data "$PORTAL_REGISTRY"
  sudo chmod 664 "$PORTAL_REGISTRY"
}

migrate_portal_registry() {
  local tmp_file changed=0
  tmp_file=$(mktemp)
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    IFS='|' read -r name url mac delay req_delay <<< "$line"
    if [[ -z "$req_delay" ]]; then
      req_delay="0.3"
      changed=1
    fi
    printf '%s|%s|%s|%s|%s\n' "$name" "$url" "$mac" "$delay" "$req_delay" >> "$tmp_file"
  done < "$PORTAL_REGISTRY"

  if [[ $changed -eq 1 ]]; then
    mv "$tmp_file" "$PORTAL_REGISTRY"
  else
    rm -f "$tmp_file"
  fi
}

ensure_path_permissions() {
  local path="$1"
  local kind="$2"
  local owner="$3"
  local group="$4"
  local mode="$5"
  local create_if_missing="${6:-true}"

  if [[ "$kind" == "dir" ]]; then
    if [[ ! -d "$path" ]]; then
      [[ "$create_if_missing" == "true" ]] || return 0
      sudo mkdir -p "$path" || return 1
    fi
  elif [[ "$kind" == "file" ]]; then
    if [[ ! -f "$path" ]]; then
      [[ "$create_if_missing" == "true" ]] || return 0
      sudo touch "$path" || return 1
    fi
  else
    return 1
  fi

  [[ ! -e "$path" ]] && return 0

  if [[ -n "$owner" || -n "$group" ]]; then
    local current_owner current_group desired_owner desired_group
    current_owner=$(stat -c '%U' "$path" 2>/dev/null)
    current_group=$(stat -c '%G' "$path" 2>/dev/null)
    desired_owner="${owner:-$current_owner}"
    desired_group="${group:-$current_group}"
    if [[ -n "$current_owner" && -n "$current_group" ]]; then
      if [[ "$current_owner" != "$desired_owner" || "$current_group" != "$desired_group" ]]; then
        sudo chown "$desired_owner":"$desired_group" "$path"
      fi
    fi
  fi

  if [[ -n "$mode" ]]; then
    local current_mode
    current_mode=$(stat -c '%a' "$path" 2>/dev/null)
    if [[ -n "$current_mode" && "$current_mode" != "$mode" ]]; then
      sudo chmod "$mode" "$path"
    fi
  fi
}

repair_runtime_permissions() {
  ensure_path_permissions "$PORTAL_DATA_BASE" "dir" "$USER" "www-data" "2775" "true"
  ensure_path_permissions "$PORTAL_DATA_BASE/mac_locks" "dir" "www-data" "www-data" "2775" "true"
  ensure_path_permissions "$PORTAL_DATA_BASE/mac_cooldowns" "dir" "www-data" "www-data" "2775" "true"
  ensure_path_permissions "$PORTAL_DATA_BASE/html" "dir" "$USER" "www-data" "2775" "false"
  ensure_path_permissions "$PORTAL_REGISTRY" "file" "$USER" "www-data" "664" "true"
  ensure_path_permissions "$PORTAL_DATA_BASE/iptv_proxy.log" "file" "www-data" "www-data" "664" "true"
}

repair_portal_directory_permissions() {
  [[ ! -f "$PORTAL_REGISTRY" ]] && return
  local portal_name portal_dir filename pattern candidate
  local -a managed_files=("config" "macs.txt" "macs_info.txt" "mac_stats.txt" "chosentv")
  shopt -s nullglob
  while IFS='|' read -r portal_name _ || [[ -n "$portal_name" ]]; do
    [[ -z "$portal_name" ]] && continue
    portal_dir="$PORTAL_DATA_BASE/$portal_name"
    [[ -d "$portal_dir" ]] || continue
    ensure_path_permissions "$portal_dir" "dir" "" "www-data" "2775" "true"
    for filename in "${managed_files[@]}"; do
      ensure_path_permissions "$portal_dir/$filename" "file" "" "www-data" "664" "false"
    done
    for pattern in "proxy_${portal_name}.m3u" "proxy_${portal_name}_vod.m3u" "source_${portal_name}.m3u"; do
      for candidate in "$portal_dir"/$pattern; do
        [[ -e "$candidate" ]] || continue
        ensure_path_permissions "$candidate" "file" "" "www-data" "664" "false"
      done
    done
  done < "$PORTAL_REGISTRY"
  shopt -u nullglob
}

if [[ ! -d "$PORTAL_DATA_BASE" ]]; then
  sudo mkdir -p "$PORTAL_DATA_BASE"
  sudo chown "$USER":www-data "$PORTAL_DATA_BASE"
  sudo chmod 2775 "$PORTAL_DATA_BASE"
fi

ensure_portal_registry_location

if [[ -f "$PORTAL_REGISTRY" ]]; then
  migrate_portal_registry
fi

repair_runtime_permissions
repair_portal_directory_permissions

if [[ "$(id -u)" -ne 0 ]]; then
  if ! id -Gn "$USER" | grep -qw "www-data"; then
    dialog --backtitle "$DIALOG_BACKTITLE" --yesno "You are not in the 'www-data' group. Add yourself to this group and re-login for proper permissions?" 8 60
    if [[ $? -eq 0 ]]; then
      sudo usermod -aG www-data "$USER"
      dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "You have been added to 'www-data'. Please log out and log back in, then re-run this script." 8 60
      exit 0
    else
      dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Script cannot continue without 'www-data' group membership." 8 60
      exit 1
    fi
  fi
fi

REQUIRED_SCRIPTS=("check_macs.sh" "configure_nginx.sh" "generate_m3u.sh" "get_categories.sh")
for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [[ -f "$script" && ! -x "$script" ]]; then
    chmod +x "$script"
  fi
done

NGINX_REQUIRED_SCRIPTS=("iptv_proxy.sh" "stats_api.sh" "stats_log_api.sh")
for script in "${NGINX_REQUIRED_SCRIPTS[@]}"; do
  if [[ -f "$NGINX_SCRIPT_DIR/$script" && ! -x "$NGINX_SCRIPT_DIR/$script" ]]; then
    chmod +x "$NGINX_SCRIPT_DIR/$script"
  fi
done

validate_mac_address() {
  local mac_to_check="$1"
  local -n prefixes_array=$2
  local mac_upper
  mac_upper=$(echo "$mac_to_check" | tr 'a-z' 'A-Z')
  if ! [[ "$mac_upper" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
    return 1
  fi
  if [[ ${#prefixes_array[@]} -gt 0 ]]; then
    local matched=0
    for prefix in "${prefixes_array[@]}"; do
      if [[ "$mac_upper" == $prefix* ]]; then
        matched=1
        break
      fi
    done
    if [[ $matched -eq 0 ]]; then
      return 2
    fi
  fi
  return 0
}

proxy_script_setup() {
  local proxy_script_path="$NGINX_SCRIPT_DIR/iptv_proxy.sh"
  if [[ ! -f "$proxy_script_path" ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Proxy script (iptv_proxy.sh) not found." 8 60
    return 1
  fi

  local current_max_attempts
  local current_attempt_start
  local current_min_stats_attempts
  local current_min_success_rate
  local current_mac_cooldown
  local current_mac_locking
  local current_min_qualified_macs

  current_max_attempts=$(grep -m1 "^MAX_ATTEMPTS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  current_attempt_start=$(grep -m1 "^ATTEMPT_COUNT_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  current_min_stats_attempts=$(grep -m1 "^MIN_STATS_ATTEMPTS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  current_min_success_rate=$(grep -m1 "^MIN_SUCCESS_RATE_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  current_min_qualified_macs=$(grep -m1 "^MIN_QUALIFIED_MACS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  current_mac_cooldown=$(grep -m1 "^MAC_COOLDOWN_SECONDS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  current_mac_locking=$(grep -m1 "^ENABLE_MAC_LOCKS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)

  if [[ -z "$current_max_attempts" || -z "$current_min_stats_attempts" ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Could not read current settings from iptv_proxy.sh." 8 70
    return 1
  fi

  current_max_attempts=${current_max_attempts:-5}
  current_attempt_start=${current_attempt_start:-0}
  current_min_success_rate=${current_min_success_rate:-0.8}
  current_min_qualified_macs=${current_min_qualified_macs:-6}
  current_mac_cooldown=${current_mac_cooldown:-900}
  current_mac_locking=${current_mac_locking:-1}

  local form_output
  form_output=$(dialog --clear --stdout --backtitle "$DIALOG_BACKTITLE" \
    --title "Proxy Script Setup" \
    --form "Configure settings for iptv_proxy.sh:" 23 95 7 \
    "Max MAC Attempts per request (overall retries before failing):" 1 1 "$current_max_attempts" 1 75 5 0 \
    "Attempt Counter Start (advanced, 0 keeps full budget):" 2 1 "$current_attempt_start" 2 75 5 0 \
    "Min Stats Attempts Threshold (mins tries before stats count):" 3 1 "$current_min_stats_attempts" 3 75 5 0 \
    "Min Success Rate (0-1, e.g. 0.8 for 80%):" 4 1 "$current_min_success_rate" 4 75 5 0 \
    "Min Qualified MACs (required count before fallback mix):" 5 1 "$current_min_qualified_macs" 5 75 5 0 \
    "MAC Cooldown seconds (delay before reuse):" 6 1 "$current_mac_cooldown" 6 75 5 0 \
    "MAC Locking (1 keeps MACs exclusive, 0 allows reuse):" 7 1 "$current_mac_locking" 7 75 5 0)

  if [[ $? -ne 0 ]]; then
    return
  fi

  local new_max_attempts
  local new_attempt_start
  local new_min_stats_attempts
  local new_min_success_rate
  local new_mac_cooldown
  local new_mac_locking
  local new_min_qualified_macs

  read -r new_max_attempts <<< "$(echo "$form_output" | sed -n 1p)"
  read -r new_attempt_start <<< "$(echo "$form_output" | sed -n 2p)"
  read -r new_min_stats_attempts <<< "$(echo "$form_output" | sed -n 3p)"
  read -r new_min_success_rate <<< "$(echo "$form_output" | sed -n 4p)"
  read -r new_min_qualified_macs <<< "$(echo "$form_output" | sed -n 5p)"
  read -r new_mac_cooldown <<< "$(echo "$form_output" | sed -n 6p)"
  read -r new_mac_locking <<< "$(echo "$form_output" | sed -n 7p)"

  if ! [[ "$new_max_attempts" =~ ^[0-9]+$ ]] || ! [[ "$new_min_stats_attempts" =~ ^[0-9]+$ ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Attempts/hash values must be valid whole numbers." 8 60
    return 1
  fi

  if ! [[ "$new_attempt_start" =~ ^[0-9]+$ ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Attempt counter start must be a whole number (0 or greater)." 8 70
    return 1
  fi

  if [[ "$new_attempt_start" -ge "$new_max_attempts" ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Attempt counter start must be less than the Max MAC Attempts value." 8 75
    return 1
  fi

  if ! [[ "$new_min_success_rate" =~ ^(0|0\.[0-9]+|1(\.0+)?)$ ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Min success rate must be a decimal between 0 and 1." 8 60
    return 1
  fi

  if ! [[ "$new_min_qualified_macs" =~ ^[0-9]+$ ]] || [[ "$new_min_qualified_macs" -lt 1 ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Min qualified MACs must be a positive whole number." 8 70
    return 1
  fi

  if ! [[ "$new_mac_cooldown" =~ ^[0-9]+$ ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: MAC cooldown must be a whole number of seconds (0 disables cooldown)." 8 70
    return 1
  fi

  if ! [[ "$new_mac_locking" =~ ^[01]$ ]]; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: MAC locking value must be 1 (enabled) or 0 (disabled)." 8 70
    return 1
  fi

  local locking_label
  if [[ "$new_mac_locking" == "1" ]]; then
    locking_label="Enabled"
  else
    locking_label="Disabled"
  fi

  cp "$proxy_script_path" "${proxy_script_path}.bak"

  sed -i "s/^MAX_ATTEMPTS_DEFAULT=.*/MAX_ATTEMPTS_DEFAULT=$new_max_attempts/" "$proxy_script_path"
  sed -i "s/^ATTEMPT_COUNT_DEFAULT=.*/ATTEMPT_COUNT_DEFAULT=$new_attempt_start/" "$proxy_script_path"
  sed -i "s/^MIN_STATS_ATTEMPTS_DEFAULT=.*/MIN_STATS_ATTEMPTS_DEFAULT=$new_min_stats_attempts/" "$proxy_script_path"
  sed -i "s/^MIN_SUCCESS_RATE_DEFAULT=.*/MIN_SUCCESS_RATE_DEFAULT=$new_min_success_rate/" "$proxy_script_path"
  sed -i "s/^MIN_QUALIFIED_MACS_DEFAULT=.*/MIN_QUALIFIED_MACS_DEFAULT=$new_min_qualified_macs/" "$proxy_script_path"
  sed -i "s/^MAC_COOLDOWN_SECONDS_DEFAULT=.*/MAC_COOLDOWN_SECONDS_DEFAULT=$new_mac_cooldown/" "$proxy_script_path"
  sed -i "s/^ENABLE_MAC_LOCKS_DEFAULT=.*/ENABLE_MAC_LOCKS_DEFAULT=$new_mac_locking/" "$proxy_script_path"

  local updated_max_attempts
  local updated_attempt_start
  local updated_min_stats_attempts
  local updated_min_success_rate
  local updated_mac_cooldown
  local updated_mac_locking
  local updated_min_qualified_macs
  updated_max_attempts=$(grep -m1 "^MAX_ATTEMPTS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  updated_attempt_start=$(grep -m1 "^ATTEMPT_COUNT_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  updated_min_stats_attempts=$(grep -m1 "^MIN_STATS_ATTEMPTS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  updated_min_success_rate=$(grep -m1 "^MIN_SUCCESS_RATE_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  updated_min_qualified_macs=$(grep -m1 "^MIN_QUALIFIED_MACS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  updated_mac_cooldown=$(grep -m1 "^MAC_COOLDOWN_SECONDS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)
  updated_mac_locking=$(grep -m1 "^ENABLE_MAC_LOCKS_DEFAULT=" "$proxy_script_path" | cut -d'=' -f2)

  if [[ "$updated_max_attempts" == "$new_max_attempts" &&
        "$updated_attempt_start" == "$new_attempt_start" &&
        "$updated_min_stats_attempts" == "$new_min_stats_attempts" &&
        "$updated_min_success_rate" == "$new_min_success_rate" &&
        "$updated_min_qualified_macs" == "$new_min_qualified_macs" &&
        "$updated_mac_cooldown" == "$new_mac_cooldown" &&
        "$updated_mac_locking" == "$new_mac_locking" ]]; then
    if sudo cp "$proxy_script_path" "/var/www/stalker/iptv_proxy.sh" && \
       sudo chown www-data:www-data "/var/www/stalker/iptv_proxy.sh" && \
       sudo chmod 755 "/var/www/stalker/iptv_proxy.sh"; then
      dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Proxy script settings updated successfully and copied to /var/www/stalker.\nMax Attempts: $new_max_attempts\nAttempt Counter Start: $new_attempt_start\nMin Stats Threshold: $new_min_stats_attempts\nMin Success Rate: $new_min_success_rate\nMin Qualified MACs: $new_min_qualified_macs\nMAC Cooldown: $new_mac_cooldown\nMAC Locking: $locking_label" 16 70
    else
      dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Proxy script settings updated locally, but FAILED to copy to /var/www/stalker/iptv_proxy.sh. Please check permissions." 10 70
    fi
  else
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Error: Failed to update settings in iptv_proxy.sh. Original script restored from .bak" 8 70
    mv "${proxy_script_path}.bak" "$proxy_script_path"
  fi
  rm -f "${proxy_script_path}.bak"
}

validate_portal_name() {
  local name_to_check="$1"
  if [[ "$name_to_check" =~ ^[A-Za-z0-9_-]+$ ]]; then
    return 0
  else
    return 1
  fi
}

PREFIX_FILE="$(dirname "$0")/mac_prefixes.txt"
PREFIXES=()
if [[ -f "$PREFIX_FILE" ]]; then
  while IFS= read -r prefix; do
    [[ -z "$prefix" ]] && continue
    PREFIXES+=("${prefix^^}")
  done < "$PREFIX_FILE"
fi

get_portal_info() {
  local line_num="$1"
  sed -n "${line_num}p" "$PORTAL_REGISTRY"
}

get_dependency_version() {
  local dep="$1"
  case "$dep" in
    dialog)
      dialog --version 2>&1 | head -1 | awk '{print $NF}'
      ;;
    curl)
      curl --version 2>/dev/null | head -1 | awk '{print $2}'
      ;;
    jq)
      jq --version 2>/dev/null | sed 's/jq-//'
      ;;
    python3)
      python3 --version 2>&1 | awk '{print $2}'
      ;;
    bash)
      bash --version 2>&1 | head -1 | awk '{print $4}'
      ;;
    awk)
      awk --version 2>&1 | head -1 | awk '{print $3}' | tr -d ','
      ;;
    sed)
      sed --version 2>&1 | head -1 | awk '{print $NF}'
      ;;
    grep)
      grep --version 2>&1 | head -1 | awk '{print $NF}'
      ;;
    fzf)
      fzf --version 2>/dev/null | head -1
      ;;
    rsync)
      rsync --version 2>&1 | head -1 | awk '{print $3}'
      ;;
    *)
      "$dep" --version 2>&1 | head -1
      ;;
  esac
}

show_system_info() {
    local temp_file=$(mktemp)
    {
        echo "╔════════════════════════════════════════════════════════════════════════════════╗"
        echo "║                               SYSTEM INFORMATION                               ║"
        echo "╠════════════════════════════════════════════════════════════════════════════════╣"
        echo "║                                                                                ║"
        printf "║  OS: %-70s    ║\n" "$(uname -s) $(uname -r)"
        printf "║  Architecture: %-60s    ║\n" "$(uname -m)"
        printf "║  User: %-69s   ║\n" "$USER"
        printf "║  Working Directory: %-53s      ║\n" "$(pwd)"
        printf "║  System Time: %-59s      ║\n" "$(date)"
        echo "║                                                                                ║"
        echo "║  Required Dependencies:                                                        ║"
        local dep dep_version
        for dep in "${REQUIRED_CMDS[@]}"; do
          if command -v "$dep" >/dev/null 2>&1; then
            dep_version=$(get_dependency_version "$dep")
            printf "║    ✅ %-10s %-56s      ║\n" "$dep" "(${dep_version:-Unknown})"
          else
            printf "║    ❌ %-66s ║\n" "$dep (Not installed)"
          fi
        done
        echo "║                                                                                ║"
        echo "║  Additional Components:                                                        ║"
        if command -v nginx >/dev/null 2>&1; then
          local nginx_version=$(nginx -v 2>&1 | grep -o 'nginx/[0-9.]*' | cut -d'/' -f2 || echo "Unknown")
          printf "║    ✅ %-10s %-56s      ║\n" "nginx" "($nginx_version)"
        else
          printf "║    ❌ %-66s ║\n" "nginx (Not installed)"
        fi
        echo "║                                                                                ║"
        echo "╚════════════════════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Press ENTER to return to main menu"
    } > "$temp_file"
    dialog --backtitle "$DIALOG_BACKTITLE" \
      --title "System Information" --textbox "$temp_file" 35 86
    rm -f "$temp_file"
}

show_portal_statistics() {
  temp_file=$(mktemp)
  total_portals=0
  total_macs=0
  active_macs=0
  declare -A portal_macs_map
  declare -A portal_active_map

  if [[ -f "$PORTAL_REGISTRY" ]]; then
    total_portals=$(wc -l < "$PORTAL_REGISTRY" | xargs)
    while IFS='|' read -r portal_name portal_url mac portal_delay portal_request_delay || [[ -n "$portal_name$portal_url$mac$portal_delay$portal_request_delay" ]]; do
      [[ -z "$portal_name" ]] && continue
      macs_info_file="$PORTAL_DATA_BASE/$portal_name/macs_info.txt"
      portal_macs=0
      portal_active=0
      if [[ -f "$macs_info_file" ]]; then
        portal_macs=$(awk -F'|' 'NR>1 && NF {count++} END {print count+0}' "$macs_info_file")
        portal_active=$(awk -F'|' 'NR>1 && tolower($3)=="yes" {count++} END {print count+0}' "$macs_info_file")
      fi
      portal_macs_map["$portal_name"]=$portal_macs
      portal_active_map["$portal_name"]=$portal_active
      total_macs=$((total_macs + portal_macs))
      active_macs=$((active_macs + portal_active))
    done < "$PORTAL_REGISTRY" 2>/dev/null
  fi

  {
        echo "╔════════════════════════════════════════════════════════════════════════════════╗"
        echo "║                              PORTAL STATISTICS                                 ║"
        echo "╠════════════════════════════════════════════════════════════════════════════════╣"
        echo "║                                                                                ║"
        printf "║  Total Portals:          %-50s    ║\n" "$total_portals"
        printf "║  Total MAC Addresses:    %-50s    ║\n" "$total_macs"
        printf "║  Active MAC Addresses:   %-50s    ║\n" "$active_macs"
        echo "║                                                                                ║"
        echo "╠════════════════════════════════════════════════════════════════════════════════╣"
        echo "║                                PORTAL DETAILS                                  ║"
        echo "╠════════════════════════════════════════════════════════════════════════════════╣"
        if [[ -f "$PORTAL_REGISTRY" ]]; then
          while IFS='|' read -r portal_name _ || [[ -n "$portal_name" ]]; do
            [[ -z "$portal_name" ]] && continue
            portal_macs=${portal_macs_map["$portal_name"]:-0}
            portal_active=${portal_active_map["$portal_name"]:-0}
            printf "║  %-20s MACs: %-3s Active: %-3s                                    ║\n" \
              "$portal_name" "$portal_macs" "$portal_active"
          done < "$PORTAL_REGISTRY"
        fi
        echo "║                                                                                ║"
        echo "╚════════════════════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Press ENTER to return to main menu"
    } > "$temp_file"
    dialog --backtitle "$DIALOG_BACKTITLE" \
           --title "Portal Statistics" \
           --textbox "$temp_file" 25 86
    rm -f "$temp_file"
}

show_proxy_log() {
    local log_file="/var/www/stalker/iptv_proxy.log"
    if [[ ! -f "$log_file" ]]; then
        dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Proxy log file not found at $log_file" 8 60
        return
    fi
    dialog --backtitle "$DIALOG_BACKTITLE" \
           --title "Proxy Log (Live)" \
           --tailbox "$log_file" 40 180
}

while true; do
  CHOICE=$(dialog --clear --stdout --backtitle "$DIALOG_BACKTITLE" \
    --title "Main Menu" \
    --ok-label "OK" --cancel-label "Cancel" \
    --menu "Choose an action:" 20 55 8 \
    1 "Add new portal" \
    2 "Edit portal" \
    3 "Proxy Settings" \
    4 "Portal Statistics" \
    5 "System Information" \
    6 "View Proxy Log" \
    7 "Exit")
  case $CHOICE in
    1)
      while true; do
        PORTAL_NAME=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter portal name (alphanumeric, underscore, hyphen only):" 8 40)
        [[ -z "$PORTAL_NAME" ]] && continue 2
        validate_portal_name "$PORTAL_NAME"
        if [[ $? -eq 0 ]]; then
          break
        else
          dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid portal name. Only letters, numbers, underscore, and hyphen are allowed." 8 60
        fi
      done
      while true; do
        PORTAL_URL=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter portal URL:" 8 40)
        [[ -z "$PORTAL_URL" ]] && continue 2
        if [[ ! "$PORTAL_URL" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
          dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid URL. Please enter a valid URL starting with http:// or https://" 8 60
          continue
        fi
        break
      done
      MAC=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter MAC address:" 8 40)
      [[ -z "$MAC" ]] && continue
      while true; do
        validate_mac_address "$MAC" PREFIXES
        validation_status=$?
        if [[ $validation_status -eq 0 ]]; then
          break
        elif [[ $validation_status -eq 1 ]]; then
          dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid MAC address format. Please use XX:XX:XX:XX:XX:XX format." 8 60
        elif [[ $validation_status -eq 2 ]]; then
          dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid MAC address prefix. Please check allowed prefixes." 8 60
        fi
        MAC=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter MAC address:" 8 40 "$MAC")
        [[ -z "$MAC" ]] && continue 2
      done
      DELAY=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter MAC check delay in seconds (default 30):" 8 50 "30")
      [[ -z "$DELAY" ]] && DELAY=30
      if ! [[ "$DELAY" =~ ^[0-9]+$ ]]; then
        dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid delay. Must be a number." 8 40
        continue
      fi
      REQUEST_DELAY_VALUE=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter per-request delay in seconds (default 0.3):" 8 60 "0.3")
      [[ -z "$REQUEST_DELAY_VALUE" ]] && REQUEST_DELAY_VALUE="0.3"
      if ! [[ "$REQUEST_DELAY_VALUE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid per-request delay. Must be numeric (e.g. 0.3)." 8 70
        continue
      fi
      if grep -q "^$PORTAL_NAME|" "$PORTAL_REGISTRY" 2>/dev/null; then
        dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Portal name already exists." 6 40
        continue
      fi
      echo "$PORTAL_NAME|$PORTAL_URL|$MAC|$DELAY|$REQUEST_DELAY_VALUE" >> "$PORTAL_REGISTRY"
      SELECTED_PORTAL="$PORTAL_NAME|$PORTAL_URL|$MAC|$DELAY|$REQUEST_DELAY_VALUE"
      mkdir -p "$PORTAL_DATA_BASE/$PORTAL_NAME"
      echo "$PORTAL_URL" > "$PORTAL_DATA_BASE/$PORTAL_NAME/config"
      echo "$MAC" > "$PORTAL_DATA_BASE/$PORTAL_NAME/macs.txt"
      sudo chown -R "$USER":www-data "$PORTAL_DATA_BASE/$PORTAL_NAME"
      sudo chmod 2775 "$PORTAL_DATA_BASE/$PORTAL_NAME"
      sudo chmod 664 "$PORTAL_DATA_BASE/$PORTAL_NAME/config" "$PORTAL_DATA_BASE/$PORTAL_NAME/macs.txt"
      ;;
    2)
      if [[ ! -s "$PORTAL_REGISTRY" ]]; then
        dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "No portals found. Add a new portal first." 6 40
        continue
      fi
      MENU_LIST=()
      i=1
      while IFS= read -r line; do
        pname="${line%%|*}"
        MENU_LIST+=("$i" "$pname")
        ((i++))
      done < "$PORTAL_REGISTRY"
      MENU_LIST+=("0" "Back")
      SEL=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --menu "Select portal to edit:" 15 50 10 "${MENU_LIST[@]}")
      [[ -z "$SEL" || "$SEL" == "0" ]] && continue
      SELECTED_PORTAL=$(get_portal_info "$SEL")
      ;;
    3)
      while true; do
        PROXY_CHOICE=$(dialog --clear --stdout --backtitle "$DIALOG_BACKTITLE" \
          --title "Proxy Settings" \
          --menu "Proxy Settings:" 15 55 4 \
          1 "Set Proxy Hostname" \
          2 "Proxy Script Setup" \
          3 "Configure Nginx for Proxy" \
          4 "Back")
        case $PROXY_CHOICE in
          1)
            CURRENT_HOSTNAME=""
            if [[ -f proxy_server.conf ]]; then
              CURRENT_HOSTNAME=$(cat proxy_server.conf)
            fi
            NEW_HOSTNAME=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter Proxy Hostname (e.g. http://192.168.0.1):" 8 60 "$CURRENT_HOSTNAME")
            if [[ -n "$NEW_HOSTNAME" ]]; then
              echo "$NEW_HOSTNAME" > proxy_server.conf
              dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Proxy hostname set to: $NEW_HOSTNAME" 6 60
            fi
            ;;
          2)
            proxy_script_setup
            ;;
          3)
            clear
            bash ./configure_nginx.sh
            clear
            ;;
          4)
            break
            ;;
          *)
            continue
            ;;
        esac
      done
      ;;
    4)
      show_portal_statistics
      ;;
    5)
      show_system_info
      ;;
    6)
      show_proxy_log
      ;;
    7)
      clear
      exit 0
      ;;
    *)
      continue
      ;;
  esac

  if [[ -n "$SELECTED_PORTAL" ]]; then
    IFS='|' read -r PORTAL_NAME PORTAL_URL MAC DELAY REQUEST_DELAY_VALUE <<< "$SELECTED_PORTAL"
    [[ -z "$REQUEST_DELAY_VALUE" ]] && REQUEST_DELAY_VALUE="0.3"
    [[ -z "$DELAY" ]] && DELAY=30

    MACS_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/macs.txt"
    MACS_INFO_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/macs_info.txt"
    MACS_CHECKED=0
    if [[ -f "$MACS_INFO_FILE" ]]; then
      MACS_CHECKED=$(tail -n +2 "$MACS_INFO_FILE" | grep -cve '^[[:space:]]*$')
    fi
    MAC_COUNT=$MACS_CHECKED

    while true; do
      PORTAL_ACTION=$(dialog --clear --stdout --backtitle "$DIALOG_BACKTITLE" \
        --title "Portal Menu: $PORTAL_NAME" \
        --menu "Choose an action:\n\nActive MAC addresses: $MAC_COUNT\nSelect your operation below:" 26 70 15 \
        01 "Show Portal Data" \
        02 "Edit Portal data" \
        03 "Select Categories TV" \
        04 "Select Categories VOD" \
        05 "View Selected Categories" \
        06 "Generate M3U TV" \
        07 "Generate M3U VOD" \
        08 "Add MAC Address" \
        09 "Check MACs" \
        10 "View active MACs" \
        11 "MAC Usage Stats" \
        12 "Delete Portal" \
        13 "Back")
      case $PORTAL_ACTION in
        01)
          PORTAL_DIR="$PORTAL_DATA_BASE/$PORTAL_NAME"
          CATEGORIES_FILE="$PORTAL_DIR/chosentv"
          MACS_INFO_FILE="$PORTAL_DIR/macs_info.txt"
          M3U_SOURCE_FILE="$PORTAL_DIR/source_${PORTAL_NAME}.m3u"
          M3U_PROXY_FILE="$PORTAL_DIR/proxy_${PORTAL_NAME}.m3u"

          WEBSERVER_HOST="N/A"
          if [[ -f "proxy_server.conf" ]]; then
            WEBSERVER_HOST=$(cat proxy_server.conf | xargs)
          fi

          CATEGORIES_COUNT=0
          if [[ -f "$CATEGORIES_FILE" ]]; then
            CATEGORIES_COUNT=$(wc -l < "$CATEGORIES_FILE" | xargs)
          fi

          TOTAL_MACS=0
          ACTIVE_MACS=0
          if [[ -f "$MACS_INFO_FILE" ]]; then
            TOTAL_MACS=$(tail -n +2 "$MACS_INFO_FILE" | grep -cve '^[[:space:]]*$')
            ACTIVE_MACS=$(tail -n +2 "$MACS_INFO_FILE" | grep -c '|yes|')
          fi

          SOURCE_M3U_STATUS="❌ Not Generated"
          PROXY_M3U_STATUS="❌ Not Generated"
          PROXY_VOD_M3U_STATUS="❌ Not Generated"
          SOURCE_M3U_SIZE="N/A"
          PROXY_M3U_SIZE="N/A"
          PROXY_VOD_M3U_SIZE="N/A"
          SOURCE_M3U_URL="N/A"
          PROXY_M3U_URL="N/A"
          PROXY_VOD_M3U_URL="N/A"

          M3U_PROXY_VOD_FILE="$PORTAL_DIR/proxy_${PORTAL_NAME}_vod.m3u"

          if [[ -f "$M3U_PROXY_VOD_FILE" ]]; then
            PROXY_VOD_M3U_STATUS="✅ Available"
            PROXY_VOD_M3U_SIZE=$(du -h "$M3U_PROXY_VOD_FILE" 2>/dev/null | cut -f1 || echo "N/A")
            if [[ "$WEBSERVER_HOST" != "N/A" ]]; then
              PROXY_VOD_M3U_URL="${WEBSERVER_HOST}/${PORTAL_NAME}/proxy_${PORTAL_NAME}_vod.m3u"
            fi
          fi

          if [[ -f "$M3U_SOURCE_FILE" ]]; then
            SOURCE_M3U_STATUS="✅ Available"
            SOURCE_M3U_SIZE=$(du -h "$M3U_SOURCE_FILE" 2>/dev/null | cut -f1 || echo "N/A")
            if [[ "$WEBSERVER_HOST" != "N/A" ]]; then
              SOURCE_M3U_URL="${WEBSERVER_HOST}/${PORTAL_NAME}/source_${PORTAL_NAME}.m3u"
            fi
          fi

          if [[ -f "$M3U_PROXY_FILE" ]]; then
            PROXY_M3U_STATUS="✅ Available"
            PROXY_M3U_SIZE=$(du -h "$M3U_PROXY_FILE" 2>/dev/null | cut -f1 || echo "N/A")
            if [[ "$WEBSERVER_HOST" != "N/A" ]]; then
              PROXY_M3U_URL="${WEBSERVER_HOST}/${PORTAL_NAME}/proxy_${PORTAL_NAME}.m3u"
            fi
          fi

          TMP_PORTAL_DATA=$(mktemp /tmp/portal_data_XXXXXX.txt)
          {
            echo "╔════════════════════════════════════════════════════════════════════════════════╗"
            echo "║                              PORTAL INFORMATION                                ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            printf "║  Portal Name: %-59s      ║\n" "$PORTAL_NAME"
            printf "║  Portal URL: %-60s      ║\n" "$PORTAL_URL"
            printf "║  Main MAC: %-62s      ║\n" "$MAC"
            printf "║  MAC Check Delay: %-55s      ║\n" "$DELAY seconds"
            printf "║  Per-request Delay: %-50s         ║\n" "$REQUEST_DELAY_VALUE seconds"
            echo "║                                                                                ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            echo "║                               MAC ADDRESSES                                    ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            printf "║  Total MAC Addresses: %-51s      ║\n" "$TOTAL_MACS"
            printf "║  Active MAC Addresses: %-50s      ║\n" "$ACTIVE_MACS"
            echo "║                                                                                ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            echo "║                                CATEGORIES                                      ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            printf "║  Selected Categories: %-51s      ║\n" "$CATEGORIES_COUNT"
            echo "║                                                                                ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            echo "║                               M3U PLAYLISTS                                    ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            printf "║  Proxy VOD M3U: %-55s         ║\n" "$PROXY_VOD_M3U_STATUS"
            if [[ "$PROXY_VOD_M3U_STATUS" == "✅ Available" ]]; then
              printf "║    └─ File Size: %-54s        ║\n" "$PROXY_VOD_M3U_SIZE"
              if [[ "$PROXY_VOD_M3U_URL" != "N/A" ]]; then
                URL_LENGTH=${#PROXY_VOD_M3U_URL}
                if [[ $URL_LENGTH -le 56 ]]; then
                  printf "║    └─ Web URL: %-56s        ║\n" "$PROXY_VOD_M3U_URL"
                else
                  PART1="${PROXY_VOD_M3U_URL:0:56}"
                  PART2="${PROXY_VOD_M3U_URL:56}"
                  printf "║    └─ Web URL: %-56s        ║\n" "$PART1"
                  printf "║       %s%-56s        ║\n" "" "$PART2"
                fi
              fi
            fi
            printf "║  Proxy TV M3U:  %-56s        ║\n" "$PROXY_M3U_STATUS"
            if [[ "$PROXY_M3U_STATUS" == "✅ Available" ]]; then
              printf "║    └─ File Size: %-54s        ║\n" "$PROXY_M3U_SIZE"
              if [[ "$PROXY_M3U_URL" != "N/A" ]]; then
                URL_LENGTH=${#PROXY_M3U_URL}
                if [[ $URL_LENGTH -le 56 ]]; then
                  printf "║    └─ Web URL: %-56s        ║\n" "$PROXY_M3U_URL"
                else
                  PART1="${PROXY_M3U_URL:0:56}"
                  PART2="${PROXY_M3U_URL:56}"
                  printf "║    └─ Web URL: %-56s        ║\n" "$PART1"
                  printf "║       %s%-56s        ║\n" "" "$PART2"
                fi
              fi
            fi
            echo "║                                                                                ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            echo "║                              FILE LOCATIONS                                    ║"
            echo "╠════════════════════════════════════════════════════════════════════════════════╣"
            printf "║  Portal Directory: %-54s      ║\n" "$PORTAL_DIR"
            if [[ -f "$M3U_SOURCE_FILE" ]]; then
              printf "║  Source Playlist: %-53s        ║\n" "source_${PORTAL_NAME}.m3u"
            fi
            if [[ -f "$M3U_PROXY_FILE" ]]; then
              printf "║  Proxy Playlist: %-54s        ║\n" "proxy_${PORTAL_NAME}.m3u"
            fi
            echo "║                                                                                ║"
            echo "╚════════════════════════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Use arrow keys to scroll • Press ENTER to return to menu"
          } > "$TMP_PORTAL_DATA"

          dialog --backtitle "$DIALOG_BACKTITLE" \
                 --title "Portal Information: $PORTAL_NAME" \
                 --textbox "$TMP_PORTAL_DATA" 44 87
          rm -f "$TMP_PORTAL_DATA"
          ;;
        02)
          while true; do
            NEW_NAME=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter new portal name (alphanumeric, underscore, hyphen only):" 8 50 "$PORTAL_NAME")
            [[ -z "$NEW_NAME" ]] && NEW_NAME="$PORTAL_NAME"
            validate_portal_name "$NEW_NAME"
            if [[ $? -eq 0 ]]; then
              break
            else
              dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid portal name. Only letters, numbers, underscore, and hyphen are allowed." 8 60
            fi
          done
          NEW_URL=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter new portal URL:" 8 50 "$PORTAL_URL")
          [[ -z "$NEW_URL" ]] && NEW_URL="$PORTAL_URL"
          NEW_MAC=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter new MAC address:" 8 50 "$MAC")
          [[ -z "$NEW_MAC" ]] && NEW_MAC="$MAC"
          while true; do
            validate_mac_address "$NEW_MAC" PREFIXES
            validation_status=$?
            if [[ $validation_status -eq 0 ]]; then
              break
            elif [[ $validation_status -eq 1 ]]; then
              dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid MAC address format. Please use XX:XX:XX:XX:XX:XX format." 8 60
            elif [[ $validation_status -eq 2 ]]; then
              dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid MAC address prefix. Please check allowed prefixes." 8 60
            fi
            NEW_MAC=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter new MAC address:" 8 50 "$NEW_MAC")
            [[ -z "$NEW_MAC" ]] && NEW_MAC="$MAC" && break
          done
          NEW_DELAY=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter new MAC check delay in seconds:" 8 50 "$DELAY")
          [[ -z "$NEW_DELAY" ]] && NEW_DELAY="$DELAY"
          if ! [[ "$NEW_DELAY" =~ ^[0-9]+$ ]]; then
            dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid delay. Must be a number." 8 40
            continue
          fi
          NEW_REQUEST_DELAY=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Enter new per-request delay in seconds:" 8 55 "$REQUEST_DELAY_VALUE")
          [[ -z "$NEW_REQUEST_DELAY" ]] && NEW_REQUEST_DELAY="$REQUEST_DELAY_VALUE"
          if ! [[ "$NEW_REQUEST_DELAY" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Invalid per-request delay. Must be numeric (e.g. 0.3)." 8 70
            continue
          fi
          if [[ "$NEW_NAME" != "$PORTAL_NAME" ]] && grep -q "^$NEW_NAME|" "$PORTAL_REGISTRY"; then
            dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Portal name already exists." 6 40
          else
            old_line="$SELECTED_PORTAL"
            new_line="$NEW_NAME|$NEW_URL|$NEW_MAC|$NEW_DELAY|$NEW_REQUEST_DELAY"
            awk -v old="$old_line" -v new="$new_line" '{if($0==old){print new}else{print $0}}' "$PORTAL_REGISTRY" > "$PORTAL_REGISTRY.tmp" && mv "$PORTAL_REGISTRY.tmp" "$PORTAL_REGISTRY"
            if [[ "$NEW_NAME" != "$PORTAL_NAME" && -d "$PORTAL_DATA_BASE/$PORTAL_NAME" ]]; then
              mv "$PORTAL_DATA_BASE/$PORTAL_NAME" "$PORTAL_DATA_BASE/$NEW_NAME"
            fi
            PORTAL_NAME="$NEW_NAME"
            PORTAL_URL="$NEW_URL"
            MAC="$NEW_MAC"
            DELAY="$NEW_DELAY"
            REQUEST_DELAY_VALUE="$NEW_REQUEST_DELAY"
            SELECTED_PORTAL="$new_line"
            dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Portal data updated." 6 40
          fi
          ;;
        03)
          PORTAL_NAME="$PORTAL_NAME" PORTAL_URL="$PORTAL_URL" MAC="$MAC" REQUEST_DELAY="$REQUEST_DELAY_VALUE" bash -i ./get_categories.sh
          STATUS=$?
          if [[ $STATUS -eq 0 ]]; then
            dialog --backtitle "$DIALOG_BACKTITLE" --backtitle "Portal: $PORTAL_NAME" --title "Select Categories TV Result" --msgbox "TV categories selection completed." 8 60
          fi
          ;;
        04)
          PORTAL_NAME="$PORTAL_NAME" PORTAL_URL="$PORTAL_URL" MAC="$MAC" REQUEST_DELAY="$REQUEST_DELAY_VALUE" VOD_ONLY=1 bash -i ./get_categories.sh
          STATUS=$?
          if [[ $STATUS -eq 0 ]]; then
            dialog --backtitle "$DIALOG_BACKTITLE" --backtitle "Portal: $PORTAL_NAME" --title "Select Categories VOD Result" --msgbox "VOD categories selection completed." 8 60
          fi
          ;;
        05)
          CHOOSEN_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/chosentv"
          if [[ -f "$CHOOSEN_FILE" ]]; then
            CATEGORIES_COUNT=$(wc -l < "$CHOOSEN_FILE" | xargs)
            TMP_CONTENT_FILE=$(mktemp /tmp/selected_categories_XXXXXX.txt)
            {
              echo "╔════════════════════════════════════════════════════════════════════════════════╗"
              echo "║                             SELECTED CATEGORIES                                ║"
              echo "╠════════════════════════════════════════════════════════════════════════════════╣"
              printf "║ Portal: %-63s        ║\n" "$PORTAL_NAME"
              printf "║ Total Categories: %-55s      ║\n" "$CATEGORIES_COUNT"
              echo "╚════════════════════════════════════════════════════════════════════════════════╝"
              echo ""
              printf " %-3s %-12s %-60s \n" "NO." "CATEGORY ID" "CATEGORY NAME"
              echo " ─── ──────────── ──────────────────────────────────────────────────────────── "

              i=1
              while IFS= read -r category; do
                [[ -z "$category" ]] && continue

                if [[ "$category" =~ ^([^:]+):(.+)$ ]]; then
                  category_id="${BASH_REMATCH[1]}"
                  category_name="${BASH_REMATCH[2]}"
                else
                  category_id="N/A"
                  category_name="$category"
                fi

                if [[ ${#category_name} -gt 60 ]]; then
                  category_name="${category_name:0:57}..."
                fi

                printf " %-3d %-12s %-60s \n" "$i" "$category_id" "$category_name"
                ((i++))
              done < "$CHOOSEN_FILE"
              echo ""
              echo "╔════════════════════════════════════════════════════════════════════════════════╗"
              echo "║ Use these categories to generate M3U playlists with your selected channels     ║"
              echo "╚════════════════════════════════════════════════════════════════════════════════╝"
              echo ""
              echo "Use arrow keys to scroll • Press ENTER to return to menu"
            } > "$TMP_CONTENT_FILE"

            dialog --backtitle "$DIALOG_BACKTITLE" \
                   --title "Selected Categories: $PORTAL_NAME" \
                   --textbox "$TMP_CONTENT_FILE" 44 87
            rm -f "$TMP_CONTENT_FILE"
          else
            dialog --backtitle "$DIALOG_BACKTITLE" \
                   --title "No Categories Selected" \
                   --msgbox "\nNo categories have been selected for this portal.\n\nPlease use 'Select Categories' option first to choose\nchannels for your IPTV portal.\n\nThis will allow you to generate M3U playlists." 12 70
          fi
          ;;
        06)
          PORTAL_NAME="$PORTAL_NAME" PORTAL_URL="$PORTAL_URL" MAC="$MAC" REQUEST_DELAY="$REQUEST_DELAY_VALUE" bash -i ./generate_m3u.sh
          STATUS=$?
          if [[ $STATUS -ne 0 && $STATUS -ne 2 ]]; then
            SUMMARY_MSG="There was an error during TV playlist generation."
            dialog --backtitle "$DIALOG_BACKTITLE" --backtitle "Portal: $PORTAL_NAME" --title "Generate M3U TV Result" --msgbox "$SUMMARY_MSG" 8 60
          fi
          ;;
        07)
          PORTAL_NAME="$PORTAL_NAME" PORTAL_URL="$PORTAL_URL" MAC="$MAC" REQUEST_DELAY="$REQUEST_DELAY_VALUE" VOD_MODE=1 bash -i ./generate_m3u.sh
          STATUS=$?
          if [[ $STATUS -ne 0 && $STATUS -ne 2 ]]; then
            SUMMARY_MSG="There was an error during VOD playlist generation."
            dialog --backtitle "$DIALOG_BACKTITLE" --backtitle "Portal: $PORTAL_NAME" --title "Generate M3U VOD Result" --msgbox "$SUMMARY_MSG" 8 60
          fi
          ;;
        08)
          MACS_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/macs.txt"
          PREFIX_FILE="$(dirname "$0")/mac_prefixes.txt"
          TMP_MACS_FILE=$(mktemp /tmp/add_macs_XXXXXX.txt)
          : > "$TMP_MACS_FILE"
          dialog --backtitle "$DIALOG_BACKTITLE" --editbox "$TMP_MACS_FILE" 12 60 2> "$TMP_MACS_FILE"
          if [[ -s "$TMP_MACS_FILE" ]]; then
            ADDED=0
            DUPLICATES=0
            INVALID=0
            BAD_FORMAT=0
            PREFIXES=()
            while IFS= read -r prefix; do
              [[ -z "$prefix" ]] && continue
              PREFIXES+=("${prefix^^}")
            done < "$PREFIX_FILE"
            while IFS= read -r MAC_ENTRY; do
              MAC_ENTRY=$(echo "$MAC_ENTRY" | xargs)
              [[ -z "$MAC_ENTRY" ]] && continue
              validate_mac_address "$MAC_ENTRY" PREFIXES
              validation_status=$?
              if [[ $validation_status -eq 1 ]]; then
                BAD_FORMAT=$((BAD_FORMAT+1))
                continue
              elif [[ $validation_status -eq 2 ]]; then
                INVALID=$((INVALID+1))
                continue
              fi
              if grep -Fxq "$MAC_ENTRY" "$MACS_FILE" 2>/dev/null || grep -q "^$MAC_ENTRY|" "$MACS_INFO_FILE" 2>/dev/null; then
                DUPLICATES=$((DUPLICATES+1))
              else
                echo "$MAC_ENTRY" >> "$MACS_FILE"
                sudo chown "$USER":www-data "$MACS_FILE"
                sudo chmod 664 "$MACS_FILE"
                ADDED=$((ADDED+1))
              fi
            done < "$TMP_MACS_FILE"
            MSG="Added $ADDED new MAC address(es)."
            if [[ $DUPLICATES -gt 0 ]]; then
              MSG+=" $DUPLICATES duplicate(s) were skipped."
            fi
            if [[ $INVALID -gt 0 ]]; then
              MSG+=" $INVALID invalid MAC(s) (wrong prefix) were skipped."
            fi
            if [[ $BAD_FORMAT -gt 0 ]]; then
              MSG+=" $BAD_FORMAT MAC(s) with bad format were skipped."
            fi
            dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "$MSG" 8 60
          fi
          rm -f "$TMP_MACS_FILE"
          ;;
        09)
          CHECK_MODE=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --menu "Check which MACs?" 10 50 2 1 "All MACs" 2 "Only new MACs (not checked before)")
          if [[ -z "$CHECK_MODE" ]]; then
            continue
          fi
          PORTAL_NAME="$PORTAL_NAME" CHECK_MODE="$CHECK_MODE" REQUEST_DELAY="$REQUEST_DELAY_VALUE" bash -i ./check_macs.sh
          ;;
        10)
          MACS_INFO_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/macs_info.txt"
          if [[ -f "$MACS_INFO_FILE" ]]; then

            active_macs_count=$(tail -n +2 "$MACS_INFO_FILE" | grep -cve '^[[:space:]]*$')
            valid_macs=$(tail -n +2 "$MACS_INFO_FILE" | grep -c '|yes|')
            expired_macs=$(tail -n +2 "$MACS_INFO_FILE" | grep -c '|no|')
            TMP_MACS_INFO=$(mktemp /tmp/active_macs_info_XXXXXX.txt)
            {
                echo "╔════════════════════════════════════════════════════════════════════════════════╗"
                echo "║                             ACTIVE MAC ADDRESSES                               ║"
                echo "╠════════════════════════════════════════════════════════════════════════════════╣"
                printf "║ Portal: %-63s        ║\n" "$PORTAL_NAME"
                printf "║ Total MACs: %-59s        ║\n" "$active_macs_count"
                printf "║ Valid MACs: %-59s        ║\n" "$valid_macs"
                printf "║ Invalid/Expired: %-54s        ║\n" "$expired_macs"
                echo "╠════════════════════════════════════════════════════════════════════════════════╣"
                echo "║                                                                                ║"
                printf "║ %-18s %-12s %-16s %-15s %-13s ║\n" "MAC ADDRESS" "EXPIRATION" "CATEGORIES" "CHANNEL COUNT" "STATUS"
                echo "║ ────────────────── ──────────── ──────────────── ─────────────── ───────────── ║"
                tail -n +2 "$MACS_INFO_FILE" | sort -t'|' -k3,3r -k2,2 | while IFS= read -r line; do
                    mac=$(echo "$line" | cut -d'|' -f1 | xargs)
                    expiration=$(echo "$line" | cut -d'|' -f2 | xargs)
                    categories_valid=$(echo "$line" | cut -d'|' -f3 | xargs)
                    category_count=$(echo "$line" | cut -d'|' -f4 | xargs)
                    [[ -z "$mac" ]] && continue
                    status_emoji="❓"
                    if [[ "$categories_valid" == "yes" ]]; then
                        today=$(date +%Y-%m-%d)
                        if [[ -n "$expiration" && "$expiration" > "$today" ]]; then
                            status_emoji="✅"
                        elif [[ -n "$expiration" ]] && ([[ "$expiration" < "$today" ]] || [[ "$expiration" == "$today" ]]); then
                            status_emoji="⏰"
                        else
                            status_emoji="✅"
                        fi
                    else
                        status_emoji="❌"
                    fi
                    exp_display="$expiration"
                    [[ -z "$expiration" ]] && exp_display="No Limit"
                    printf "║ %-18s %-12s %-16s %-15s %-13s  ║\n" "$mac" "$exp_display" "$categories_valid" "$category_count" "$status_emoji"
                done
                echo "║                                                                                ║"
                echo "╠════════════════════════════════════════════════════════════════════════════════╣"
                echo "║ Legend: ✅ Active  ❌ Invalid  ⏰ Expired  ❓ Unknown                          ║"
                echo "╚════════════════════════════════════════════════════════════════════════════════╝"
                echo ""
                echo "Use arrow keys to scroll • Press ENTER to return to menu"
            } > "$TMP_MACS_INFO"
            dialog --backtitle "$DIALOG_BACKTITLE" \
                   --title "Active MAC Addresses: $PORTAL_NAME" \
                   --textbox "$TMP_MACS_INFO" 44 87
            rm -f "$TMP_MACS_INFO"
          else
            dialog --backtitle "$DIALOG_BACKTITLE" \
                   --title "No Active MACs Found" \
                   --msgbox "\nNo active MAC addresses found for this portal.\n\nPlease use 'Check MACs' option first to verify\nMAC addresses and generate the active list.\n\nThis will scan and validate your MAC addresses." 12 70
          fi
          ;;
        11)
          MACS_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/macs.txt"
          MACS_INFO_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/macs_info.txt"
          MAC_STATS_FILE="$PORTAL_DATA_BASE/$PORTAL_NAME/mac_stats.txt"
          while true; do
            STATS_ACTION=$(dialog --clear --stdout --backtitle "$DIALOG_BACKTITLE" \
              --title "MAC Usage Stats: $PORTAL_NAME" \
              --menu "Choose an action:" 13 65 4 \
              1 "View MAC Usage Stats" \
              2 "Reset MAC Usage Stats" \
              3 "Remove Low Success MACs" \
              4 "Back")
            case $STATS_ACTION in
              1)
                TMP_MAC_STATS=$(mktemp /tmp/mac_usage_stats_XXXXXX.txt)
                {
                  echo "╔════════════════════════════════════════════════════════════════════════════════╗"
                  echo "║                               MAC USAGE STATISTICS                             ║"
                  echo "╚════════════════════════════════════════════════════════════════════════════════╝"
                  printf " %-18s %-14s %-14s %-14s \n" "MAC ADDRESS" "SUCCESS" "ATTEMPTS" "SUCCESS RATE"
                  echo " ────────────────── ────────────── ────────────── ────────────── "
                  if [[ -f "$MAC_STATS_FILE" ]]; then
                    while IFS='|' read -r mac success attempts; do
                      [[ -z "$mac" || -z "$success" || -z "$attempts" ]] && continue
                      if [[ "$attempts" -eq 0 ]]; then
                        rate=0
                      else
                        rate=$(awk -v s="$success" -v a="$attempts" 'BEGIN{printf "%.0f", (a==0?0:(s/a)*100)}')
                      fi
                      if [[ "$rate" -ge 80 ]]; then
                        icon="🟢"
                      elif [[ "$rate" -le 20 ]]; then
                        icon="🔴"
                      else
                        icon="🟡"
                      fi
                      printf " %-18s %-14s %-14s %-10s %2s \n" "$mac" "$success" "$attempts" "$rate%" "$icon"
                    done < "$MAC_STATS_FILE"
                  else
                    echo " No MAC usage stats found for this portal. "
                  fi
                  echo "╔════════════════════════════════════════════════════════════════════════════════╗"
                  echo "║ Legend: 🟢 High (>=80%)  🟡 Medium  🔴 Low (<=20%) Success Rate                ║"
                  echo "╚════════════════════════════════════════════════════════════════════════════════╝"
                  echo ""
                  echo "Use arrow keys to scroll • Press ENTER to return to menu"
                } > "$TMP_MAC_STATS"
                dialog --backtitle "$DIALOG_BACKTITLE" \
                       --title "MAC Usage Stats: $PORTAL_NAME" \
                       --textbox "$TMP_MAC_STATS" 44 87
                rm -f "$TMP_MAC_STATS"
                ;;
              2)
                dialog --backtitle "$DIALOG_BACKTITLE" --yesno "Reset MAC Usage Stats for '$PORTAL_NAME'?\n\nThis will delete all recorded success/attempt counts." 9 70
                if [[ $? -eq 0 ]]; then
                  rm -f "$MAC_STATS_FILE" "$MAC_STATS_FILE.lock"
                  : > "$MAC_STATS_FILE"
                  sudo chown "$USER":www-data "$MAC_STATS_FILE" 2>/dev/null || true
                  sudo chmod 664 "$MAC_STATS_FILE" 2>/dev/null || true
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "MAC Usage Stats have been reset for '$PORTAL_NAME'." 7 60
                fi
                ;;
              3)
                if [[ ! -s "$MAC_STATS_FILE" ]]; then
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "No MAC usage stats available for '$PORTAL_NAME'." 8 60
                  continue
                fi
                DEFAULT_THRESHOLD=20
                REMOVAL_THRESHOLD=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Remove MACs with success rate LESS THAN or EQUAL to (0-100%):" 9 70 "$DEFAULT_THRESHOLD")
                [[ $? -ne 0 ]] && continue
                [[ -z "$REMOVAL_THRESHOLD" ]] && REMOVAL_THRESHOLD="$DEFAULT_THRESHOLD"
                if ! [[ "$REMOVAL_THRESHOLD" =~ ^[0-9]+$ ]]; then
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Threshold must be a whole number between 0 and 100." 8 60
                  continue
                fi
                if (( REMOVAL_THRESHOLD < 0 || REMOVAL_THRESHOLD > 100 )); then
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Threshold must be between 0 and 100." 8 60
                  continue
                fi

                DEFAULT_ATTEMPT_THRESHOLD=10
                ATTEMPT_THRESHOLD=$(dialog --stdout --backtitle "$DIALOG_BACKTITLE" --inputbox "Only consider MACs with AT LEAST this many attempts:" 9 70 "$DEFAULT_ATTEMPT_THRESHOLD")
                [[ $? -ne 0 ]] && continue
                [[ -z "$ATTEMPT_THRESHOLD" ]] && ATTEMPT_THRESHOLD="$DEFAULT_ATTEMPT_THRESHOLD"
                if ! [[ "$ATTEMPT_THRESHOLD" =~ ^[0-9]+$ ]]; then
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Attempt threshold must be a whole number (0 or greater)." 8 70
                  continue
                fi

                ATTEMPT_THRESHOLD=$(( ATTEMPT_THRESHOLD < 0 ? 0 : ATTEMPT_THRESHOLD ))

                mapfile -t MACS_TO_PRUNE < <(awk -F'|' -v th="$REMOVAL_THRESHOLD" -v min_attempts="$ATTEMPT_THRESHOLD" '
                  NR==1 && NF<2 {next}
                  {
                    mac=$1
                    gsub(/^[ \t]+|[ \t]+$/, "", mac)
                    success=($2==""?0:$2)
                    attempts=($3==""?0:$3)
                    if (mac=="" || attempts==0) next
                    if (attempts < min_attempts) next
                    rate=(success/attempts)*100
                    if (rate <= th) print toupper(mac)
                  }' "$MAC_STATS_FILE" | sort -u | sed '/^$/d')

                if [[ ${#MACS_TO_PRUNE[@]} -eq 0 ]]; then
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "No MACs fall at or below ${REMOVAL_THRESHOLD}% success with >=${ATTEMPT_THRESHOLD} attempts for '$PORTAL_NAME'." 8 75
                  continue
                fi

                REMOVED_COUNT=0
                for LOW_MAC in "${MACS_TO_PRUNE[@]}"; do
                  mac_removed=0
                  upper_mac="${LOW_MAC^^}"

                  if [[ -f "$MACS_FILE" ]]; then
                    TMP_FILE=$(mktemp)
                    awk -v target="$upper_mac" '
                      function trim(str){ sub(/^[ \t]+/, "", str); sub(/[ \t]+$/, "", str); return str }
                      {
                        orig=$0
                        mac_line=trim($0)
                        if (mac_line=="") { print orig; next }
                        if (toupper(mac_line)==target) next
                        print orig
                      }
                    ' "$MACS_FILE" > "$TMP_FILE"
                    if ! cmp -s "$TMP_FILE" "$MACS_FILE"; then
                      mv "$TMP_FILE" "$MACS_FILE"
                      sudo chown "$USER":www-data "$MACS_FILE" 2>/dev/null || true
                      sudo chmod 664 "$MACS_FILE" 2>/dev/null || true
                      mac_removed=1
                    else
                      rm -f "$TMP_FILE"
                    fi
                  fi

                  if [[ -f "$MACS_INFO_FILE" ]]; then
                    TMP_INFO=$(mktemp)
                    awk -F'|' -v target="$upper_mac" '
                      function trim(str){ sub(/^[ \t]+/, "", str); sub(/[ \t]+$/, "", str); return str }
                      NR==1 { print $0; next }
                      {
                        mac_field=trim($1)
                        if (mac_field=="") next
                        if (toupper(mac_field)==target) next
                        print $0
                      }
                    ' "$MACS_INFO_FILE" > "$TMP_INFO"
                    if ! cmp -s "$TMP_INFO" "$MACS_INFO_FILE"; then
                      mv "$TMP_INFO" "$MACS_INFO_FILE"
                      sudo chown "$USER":www-data "$MACS_INFO_FILE" 2>/dev/null || true
                      sudo chmod 664 "$MACS_INFO_FILE" 2>/dev/null || true
                      mac_removed=1
                    else
                      rm -f "$TMP_INFO"
                    fi
                  fi

                  if [[ -f "$MAC_STATS_FILE" ]]; then
                    TMP_STATS=$(mktemp)
                    awk -F'|' -v target="$upper_mac" '
                      function trim(str){ sub(/^[ \t]+/, "", str); sub(/[ \t]+$/, "", str); return str }
                      {
                        mac_field=trim($1)
                        if (mac_field=="" && NF==0) next
                        if (toupper(mac_field)==target) next
                        print $0
                      }
                    ' "$MAC_STATS_FILE" > "$TMP_STATS"
                    mv "$TMP_STATS" "$MAC_STATS_FILE"
                    sudo chown "$USER":www-data "$MAC_STATS_FILE" 2>/dev/null || true
                    sudo chmod 664 "$MAC_STATS_FILE" 2>/dev/null || true
                  fi

                  if [[ $mac_removed -eq 1 ]]; then
                    REMOVED_COUNT=$((REMOVED_COUNT + 1))
                  fi
                done

                if [[ $REMOVED_COUNT -gt 0 ]]; then
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Removed $REMOVED_COUNT MAC(s) at or below ${REMOVAL_THRESHOLD}% success with >=${ATTEMPT_THRESHOLD} attempts for '$PORTAL_NAME'." 10 75
                else
                  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Low-success MACs were identified but not present in macs.txt/macs_info.txt." 8 70
                fi
                ;;
              *)
                break
                ;;
            esac
          done
          ;;
        12)
          dialog --backtitle "$DIALOG_BACKTITLE" --yesno "Are you sure you want to delete portal '$PORTAL_NAME'? This will remove its entry and delete its folder." 8 60
          if [[ $? -eq 0 ]]; then
            full_entry="${PORTAL_NAME}|${PORTAL_URL}|${MAC}|${DELAY}|${REQUEST_DELAY_VALUE}"
            legacy_entry="${PORTAL_NAME}|${PORTAL_URL}|${MAC}|${DELAY}"
            awk -v full="$full_entry" -v legacy="$legacy_entry" '{ if ($0!=full && $0!=legacy) print $0 }' "$PORTAL_REGISTRY" > "$PORTAL_REGISTRY.tmp" && mv "$PORTAL_REGISTRY.tmp" "$PORTAL_REGISTRY"
            if [[ -d "$PORTAL_DATA_BASE/$PORTAL_NAME" ]]; then
              rm -rf "$PORTAL_DATA_BASE/$PORTAL_NAME"
            fi
            dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Portal '$PORTAL_NAME' deleted." 6 40
            break
          fi
          ;;
        13)
          break
          ;;
        *)
          continue
          ;;
      esac
    done
    unset SELECTED_PORTAL
  fi
done
