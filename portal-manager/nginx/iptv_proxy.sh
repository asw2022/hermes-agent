#!/bin/bash
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

LOG_FILE="/var/www/stalker/iptv_proxy.log"
MAC_LOCK_DIR="/var/www/stalker/mac_locks"
MAC_COOLDOWN_BASE_DIR="/var/www/stalker/mac_cooldowns"
MAC_RUNTIME_FALLBACK="${MAC_RUNTIME_FALLBACK:-${TMPDIR:-/tmp}/iptv_proxy_runtime}"
MAC_COOLDOWN_SECONDS_DEFAULT=900
MAC_COOLDOWN_SECONDS="${MAC_COOLDOWN_SECONDS:-$MAC_COOLDOWN_SECONDS_DEFAULT}"
ENABLE_MAC_LOCKS_DEFAULT=1
ENABLE_MAC_LOCKS="${ENABLE_MAC_LOCKS:-$ENABLE_MAC_LOCKS_DEFAULT}"
MIN_STATS_ATTEMPTS_DEFAULT=150
MIN_STATS_ATTEMPTS="${MIN_STATS_ATTEMPTS:-$MIN_STATS_ATTEMPTS_DEFAULT}"
MIN_SUCCESS_RATE_DEFAULT=0.8
MIN_SUCCESS_RATE="${MIN_SUCCESS_RATE:-$MIN_SUCCESS_RATE_DEFAULT}"
MIN_QUALIFIED_MACS_DEFAULT=6
MIN_QUALIFIED_MACS="${MIN_QUALIFIED_MACS:-$MIN_QUALIFIED_MACS_DEFAULT}"
MAX_ATTEMPTS_DEFAULT=5
MAX_ATTEMPTS="${MAX_ATTEMPTS:-$MAX_ATTEMPTS_DEFAULT}"
ATTEMPT_COUNT_DEFAULT=0
ATTEMPT_COUNT_INITIAL="${INITIAL_ATTEMPT_COUNT:-${ATTEMPT_COUNT:-$ATTEMPT_COUNT_DEFAULT}}"
CURRENT_MAC_LOCK_FD=""
CURRENT_MAC_LOCK_FILE=""
PORTAL_REGISTRY_DEFAULT="/var/www/stalker/portals.list"
PORTAL_REGISTRY="${PORTAL_REGISTRY:-$PORTAL_REGISTRY_DEFAULT}"
declare -A PORTAL_ALLOWLIST
PORTAL_ALLOWLIST_LOADED=0

if ! [[ "$MAX_ATTEMPTS" =~ ^[0-9]+$ && "$MAX_ATTEMPTS" -gt 0 ]]; then
  MAX_ATTEMPTS="$MAX_ATTEMPTS_DEFAULT"
fi

if ! [[ "$ATTEMPT_COUNT_INITIAL" =~ ^[0-9]+$ ]]; then
  ATTEMPT_COUNT_INITIAL="$ATTEMPT_COUNT_DEFAULT"
fi

if (( ATTEMPT_COUNT_INITIAL >= MAX_ATTEMPTS )); then
  ATTEMPT_COUNT_INITIAL=$(( MAX_ATTEMPTS - 1 ))
  if (( ATTEMPT_COUNT_INITIAL < 0 )); then
    ATTEMPT_COUNT_INITIAL=0
  fi
fi

if ! [[ "$MAC_COOLDOWN_SECONDS" =~ ^[0-9]+$ ]]; then
  [[ -n "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') Warning: Invalid MAC_COOLDOWN_SECONDS='$MAC_COOLDOWN_SECONDS'; using default $MAC_COOLDOWN_SECONDS_DEFAULT." >> "$LOG_FILE"
  MAC_COOLDOWN_SECONDS="$MAC_COOLDOWN_SECONDS_DEFAULT"
fi

if (( MAC_COOLDOWN_SECONDS < 0 )); then
  [[ -n "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') Warning: Negative MAC_COOLDOWN_SECONDS adjusted to 0." >> "$LOG_FILE"
  MAC_COOLDOWN_SECONDS=0
fi

ensure_writable_dir() {
  local target_dir="$1"
  if [[ -z "$target_dir" ]]; then
    return 1
  fi
  if [[ -d "$target_dir" ]] || mkdir -p "$target_dir" 2>/dev/null; then
    printf '%s' "$target_dir"
    return 0
  fi
  local subdir
  subdir=$(basename "$target_dir")
  local fallback_dir="${MAC_RUNTIME_FALLBACK%/}/${subdir}"
  if [[ -d "$fallback_dir" ]] || mkdir -p "$fallback_dir" 2>/dev/null; then
    if [[ -n "$LOG_FILE" ]]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') Warning: Unable to create $target_dir (insufficient permissions). Falling back to $fallback_dir." >> "$LOG_FILE"
    fi
    printf '%s' "$fallback_dir"
    return 0
  fi
  if [[ -n "$LOG_FILE" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Unable to create fallback runtime directory $fallback_dir for $target_dir." >> "$LOG_FILE"
  fi
  return 1
}

ensure_portal_scoped_dir() {
  local base_dir="$1"
  local portal_segment="${PORTAL:-default}"
  local writable_base
  writable_base=$(ensure_writable_dir "$base_dir") || return 1
  local scoped_dir="${writable_base}/${portal_segment}"
  if [[ -d "$scoped_dir" ]] || mkdir -p "$scoped_dir" 2>/dev/null; then
    printf '%s' "$scoped_dir"
    return 0
  fi
  if [[ -n "$LOG_FILE" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Unable to prepare scoped directory $scoped_dir for portal $portal_segment." >> "$LOG_FILE"
  fi
  return 1
}

load_portal_allowlist() {
  if (( PORTAL_ALLOWLIST_LOADED )); then
    return 0
  fi
  if [[ ! -r "$PORTAL_REGISTRY" ]]; then
    return 1
  fi
  while IFS='|' read -r portal_name _; do
    [[ -z "$portal_name" ]] && continue
    if [[ "$portal_name" =~ ^[A-Za-z0-9_-]+$ ]]; then
      PORTAL_ALLOWLIST["$portal_name"]=1
    fi
  done < "$PORTAL_REGISTRY"
  PORTAL_ALLOWLIST_LOADED=1
  return 0
}

portal_is_allowed() {
  local portal_candidate="$1"
  [[ -z "$portal_candidate" ]] && return 1
  load_portal_allowlist || return 1
  [[ -n "${PORTAL_ALLOWLIST[$portal_candidate]}" ]]
}

acquire_mac_lock() {
  if [[ "$ENABLE_MAC_LOCKS" != "1" ]]; then
    return 0
  fi
  local mac_address="$1"
  local lock_dir
  lock_dir=$(ensure_portal_scoped_dir "$MAC_LOCK_DIR") || return 1
  local lock_file="${lock_dir}/${mac_address}.lock"

  if [[ -n "$CURRENT_MAC_LOCK_FD" ]]; then
    release_mac_lock
  fi

  if [[ ! -d "$lock_dir" ]]; then
    mkdir -p "$lock_dir" || return 1
  fi

  exec {fd}>"$lock_file" || return 1
  if flock -xn "$fd"; then
    CURRENT_MAC_LOCK_FD="$fd"
    CURRENT_MAC_LOCK_FILE="$lock_file"
    return 0
  fi

  eval "exec ${fd}>&-"
  return 1
}

release_mac_lock() {
  if [[ "$ENABLE_MAC_LOCKS" != "1" ]]; then
    return 0
  fi
  if [[ -n "$CURRENT_MAC_LOCK_FD" ]]; then
    flock -u "$CURRENT_MAC_LOCK_FD"
    eval "exec ${CURRENT_MAC_LOCK_FD}>&-"
    CURRENT_MAC_LOCK_FD=""
  fi

  if [[ -n "$CURRENT_MAC_LOCK_FILE" ]]; then
    rm -f "$CURRENT_MAC_LOCK_FILE"
    CURRENT_MAC_LOCK_FILE=""
  fi
}

mac_is_on_cooldown() {
  if (( MAC_COOLDOWN_SECONDS <= 0 )); then
    return 1
  fi
  local mac_address="$1"
  local cooldown_dir
  cooldown_dir=$(ensure_portal_scoped_dir "$MAC_COOLDOWN_BASE_DIR") || return 1
  local cooldown_file="${cooldown_dir}/${mac_address}"

  if [[ -f "$cooldown_file" ]]; then
    local last_ts now_ts
    now_ts=$(date +%s)
    last_ts=$(stat -c %Y "$cooldown_file" 2>/dev/null || echo 0)
    if (( last_ts > 0 && (now_ts - last_ts) < MAC_COOLDOWN_SECONDS )); then
      return 0
    fi
    rm -f "$cooldown_file"
  fi
  return 1
}

mark_mac_cooldown() {
  if (( MAC_COOLDOWN_SECONDS <= 0 )); then
    return 0
  fi
  local mac_address="$1"
  local cooldown_dir
  cooldown_dir=$(ensure_portal_scoped_dir "$MAC_COOLDOWN_BASE_DIR") || return 1
  local cooldown_file="${cooldown_dir}/${mac_address}"
  touch "$cooldown_file"
}

cleanup_expired_cooldowns() {
  if (( MAC_COOLDOWN_SECONDS <= 0 )); then
    return 0
  fi
  local cooldown_dir
  cooldown_dir=$(ensure_portal_scoped_dir "$MAC_COOLDOWN_BASE_DIR") || return 0
  local cutoff_ts
  cutoff_ts=$(date +%s)
  cutoff_ts=$(( cutoff_ts - MAC_COOLDOWN_SECONDS ))
  find "$cooldown_dir" -type f -not -newermt "@$cutoff_ts" -delete 2>/dev/null || true
}

failure_backoff_seconds() {
  local reason="$1"
  case "$reason" in
    rate_limit)
      printf '2'
      ;;
    network)
      printf '1'
      ;;
    portal_temp)
      printf '0.8'
      ;;
    *)
      printf '0.3'
      ;;
  esac
}

handle_mac_failure() {
  local mac_address="$1"
  local reason="${2:-unknown}"
  local penalize="true"

  case "$reason" in
    rate_limit|network|portal_temp)
      penalize="false"
      ;;
  esac

  if [[ "$penalize" == "true" ]]; then
    update_mac_stats "$mac_address" "false" "$STATS_FILE_PATH"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Skipping stats penalty for MAC $mac_address due to reason '$reason'." >> "$LOG_FILE"
  fi

  local backoff
  backoff=$(failure_backoff_seconds "$reason")
  echo "$(date '+%Y-%m-%d %H:%M:%S') Applying ${backoff}s backoff for MAC $mac_address (reason: $reason)." >> "$LOG_FILE"
  sleep "$backoff"
}

update_mac_stats() {
  local mac_address="$1"
  local was_successful_str="$2"
  local stats_file="$3"
  local lock_file="${stats_file}.lock"

  local stats_dir
  stats_dir=$(dirname "$stats_file")
  if [[ ! -d "$stats_dir" ]]; then
    mkdir -p "$stats_dir" || {
      echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Failed to create directory $stats_dir for stats file. MAC $mac_address stats not updated." >> "$LOG_FILE"
      return 1
    }
  fi

  touch "$stats_file"

  (
    flock -x 200 || { echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Failed to acquire lock for $stats_file. MAC $mac_address stats not updated." >> "$LOG_FILE"; exit 1; }

    local temp_stats_file
    temp_stats_file=$(mktemp)
    if [[ -z "$temp_stats_file" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Failed to create temp file for updating stats. MAC $mac_address stats not updated." >> "$LOG_FILE"
        return 1
    fi

    awk -F'|' -v mac="$mac_address" -v successful_str="$was_successful_str" '
      BEGIN { OFS=FS; mac_found=0 }
      {
        if ($1 == mac) {
          mac_found=1;
          current_success_count = ($2 == "" || $2 !~ /^[0-9]+$/) ? 0 : $2;
          current_attempt_count = ($3 == "" || $3 !~ /^[0-9]+$/) ? 0 : $3;

          updated_success_count = current_success_count;
          if (successful_str == "true") {
            updated_success_count = current_success_count + 1;
          }
          updated_attempt_count = current_attempt_count + 1;
          print $1, updated_success_count, updated_attempt_count;
        } else {
          print $0;
        }
      }
      END {
        if (mac_found == 0) {
          initial_success_count = (successful_str == "true") ? 1 : 0;
          print mac, initial_success_count, 1;
        }
      }' "$stats_file" > "$temp_stats_file"

    if mv "$temp_stats_file" "$stats_file"; then
      chmod 664 "$stats_file"
      echo "$(date '+%Y-%m-%d %H:%M:%S') Updated stats for MAC $mac_address (Success: $was_successful_str) in $stats_file." >> "$LOG_FILE"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Failed to move temp stats file to $stats_file for MAC $mac_address. Stats might be in $temp_stats_file." >> "$LOG_FILE"
      rm -f "$temp_stats_file"
    fi
  ) 200>"$lock_file"
  rm -f "$lock_file"
}

resolve_proxy_playlist() {
  local portal="$1"
  local portal_dir="$2"
  local script_dir
  script_dir=$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)
  local candidates=(
    "$portal_dir/proxy_${portal}.m3u"
    "/var/www/stalker/proxy_${portal}.m3u"
    "$script_dir/proxy_${portal}.m3u"
    "$script_dir/../proxy_${portal}.m3u"
  )
  local playlist
  for playlist in "${candidates[@]}"; do
    if [[ -f "$playlist" ]]; then
      printf '%s' "$playlist"
      return 0
    fi
  done
  return 1
}

lookup_channel_name() {
  local channel_id="$1"
  local portal="$2"
  local portal_dir="$3"
  local playlist
  playlist=$(resolve_proxy_playlist "$portal" "$portal_dir") || return 1
    python3 - "$channel_id" "$playlist" <<'PY'
import sys
from pathlib import Path
from urllib.parse import urlparse, parse_qs

channel_id = sys.argv[1]
playlist_path = Path(sys.argv[2])
try:
    with playlist_path.open(errors='ignore') as fh:
        extinf = None
        for line in fh:
            stripped = line.strip()
            if not stripped:
                continue
            if stripped.startswith('#EXTINF'):
                extinf = stripped
                continue
            if not extinf:
                continue
            parsed = urlparse(stripped)
            params = parse_qs(parsed.query)
            stream_matches = any(channel_id == value for values in params.values() for value in values if value)
            path_matches = parsed.path.rstrip('/').endswith(f'/{channel_id}')
            if stream_matches or path_matches:
                name = extinf.split(',')[-1].strip()
                if name:
                    print(name)
                    sys.exit(0)
            extinf = None
except FileNotFoundError:
    sys.exit(1)
sys.exit(1)
PY
}

PATH_OR_URI="${PATH_INFO:-$REQUEST_URI}"
IFS='/' read -r _ PORTAL CHANNEL_ID _ <<< "$PATH_OR_URI"

PORTAL_NAME="${PORTAL_NAME:-}"

SEPARATOR_LINE="$(printf '============== %s NEW REQUEST - %s ==============' "$(date '+%Y-%m-%d %H:%M:%S')" "$PORTAL")"
echo "" >> "$LOG_FILE"
echo "$SEPARATOR_LINE" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

if [[ -z "$PORTAL" || -z "$CHANNEL_ID" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Missing portal or channel ID" >> "$LOG_FILE"
    echo "Status: 400 Bad Request"
    echo "Content-type: text/plain"
    echo
    echo "Missing portal or channel ID"
    exit 1
fi

if [[ ! "$PORTAL" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Invalid portal name '$PORTAL' (disallowed characters)." >> "$LOG_FILE"
  echo "Status: 400 Bad Request"
  echo "Content-type: text/plain"
  echo
  echo "Invalid portal identifier"
  exit 1
fi

if ! load_portal_allowlist; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Unable to read portal registry at $PORTAL_REGISTRY." >> "$LOG_FILE"
  echo "Status: 500 Internal Server Error"
  echo "Content-type: text/plain"
  echo
  echo "Portal registry unavailable"
  exit 1
fi

if [[ -z "${PORTAL_ALLOWLIST[$PORTAL]}" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Portal '$PORTAL' not registered in $PORTAL_REGISTRY." >> "$LOG_FILE"
  echo "Status: 404 Not Found"
  echo "Content-type: text/plain"
  echo
  echo "Unknown portal"
  exit 1
fi

PORTAL_DATA_BASE="/var/www/stalker"
PORTAL_DIR="$PORTAL_DATA_BASE/$PORTAL"
MACS_FILE="$PORTAL_DIR/macs.txt"
MACS_INFO_FILE="$PORTAL_DIR/macs_info.txt"
CONFIG_FILE="$PORTAL_DIR/config"
STATS_FILE_PATH="$PORTAL_DIR/mac_stats.txt"

CHANNEL_NAME=""
if CHANNEL_NAME_TMP=$(lookup_channel_name "$CHANNEL_ID" "$PORTAL" "$PORTAL_DIR"); then
  CHANNEL_NAME="$CHANNEL_NAME_TMP"
fi
CHANNEL_LOG_DESC="$CHANNEL_ID"
if [[ -n "$CHANNEL_NAME" ]]; then
  CHANNEL_LOG_DESC="$CHANNEL_ID [$CHANNEL_NAME]"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Received request: PATH_OR_URI=$PATH_OR_URI, PORTAL=$PORTAL, CHANNEL_ID=$CHANNEL_LOG_DESC" >> "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') Using portal $PORTAL files under $PORTAL_DIR (macs.txt, macs_info.txt, config, mac_stats.txt)" >> "$LOG_FILE"

if [[ "$ENABLE_MAC_LOCKS" != "1" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') MAC locking disabled for this request." >> "$LOG_FILE"
fi

if [[ ! -f "$MACS_FILE" || ! -f "$CONFIG_FILE" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: MACS_FILE or CONFIG_FILE not found for portal $PORTAL" >> "$LOG_FILE"
    echo "Status: 500 Internal Server Error"
    echo "Content-type: text/plain"
    echo
    echo "No MACs or config file found for portal $PORTAL"
    exit 1
fi

PORTAL_URL=$(head -n1 "$CONFIG_FILE")
USER_AGENT="Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG250 stbapp ver: 4 rev: 2721 Mobile Safari/533.3"
echo "$(date '+%Y-%m-%d %H:%M:%S') Read PORTAL_URL=$PORTAL_URL from $CONFIG_FILE" >> "$LOG_FILE"

TODAY=$(date +%Y-%m-%d)
echo "$(date '+%Y-%m-%d %H:%M:%S') Checking for valid MACs in $MACS_INFO_FILE and stats in $STATS_FILE_PATH for date $TODAY" >> "$LOG_FILE"
cleanup_expired_cooldowns

VALID_MACS_FROM_INFO=()
if [[ -f "$MACS_INFO_FILE" ]]; then
    mapfile -t VALID_MACS_FROM_INFO < <(awk -F'|' -v today="$TODAY" 'tolower($3) ~ /^yes$/ && ($2 == "" || $2 >= today) {print $1}' "$MACS_INFO_FILE")
fi

SHUF_MACS=()
list_is_primarily_ordered=false

if [[ ${#VALID_MACS_FROM_INFO[@]} -eq 0 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') No MACs found in $MACS_INFO_FILE matching criteria (valid and not expired)." >> "$LOG_FILE"
  FALLBACK_MACS=()
  if [[ -f "$MACS_FILE" ]]; then
    mapfile -t FALLBACK_MACS < <(awk 'NF {gsub(/^\s+|\s+$/, ""); if ($0!="") print $0}' "$MACS_FILE" | awk '!seen[$0]++')
  fi
  if [[ ${#FALLBACK_MACS[@]} -eq 0 && -f "$MACS_INFO_FILE" ]]; then
    mapfile -t FALLBACK_MACS < <(tail -n +2 "$MACS_INFO_FILE" | cut -d'|' -f1 | awk 'NF {gsub(/^\s+|\s+$/, ""); if ($0!="") print $0}' | awk '!seen[$0]++')
  fi
  if [[ ${#FALLBACK_MACS[@]} -gt 0 ]]; then
    mapfile -t SHUF_MACS < <(printf "%s\n" "${FALLBACK_MACS[@]}" | shuf)
    echo "$(date '+%Y-%m-%d %H:%M:%S') Falling back to ${#SHUF_MACS[@]} MAC(s) from macs.txt/macs_info.txt in random order." >> "$LOG_FILE"
  fi
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') Found ${#VALID_MACS_FROM_INFO[@]} MACs from $MACS_INFO_FILE to consider for ordering." >> "$LOG_FILE"
  PYTHON_SORT_SCRIPT="$(dirname "$0")/mac_order.py"
  ORDERED_LINES=()
  if [[ -x "$PYTHON_SORT_SCRIPT" ]]; then
    ORDERED_LINES_RAW=$(printf "%s\n" "${VALID_MACS_FROM_INFO[@]}" | python3 "$PYTHON_SORT_SCRIPT" "$STATS_FILE_PATH" "$MIN_STATS_ATTEMPTS" "$MIN_SUCCESS_RATE")
    if [[ $? -ne 0 ]]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Python MAC ordering failed. Falling back to random order." >> "$LOG_FILE"
    else
      mapfile -t ORDERED_LINES <<< "$ORDERED_LINES_RAW"
    fi
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: MAC ordering helper not found at $PYTHON_SORT_SCRIPT. Using random order." >> "$LOG_FILE"
  fi

  MACS_FOR_RANDOM_FALLBACK=()
  VALID_MACS_ORDERED_BY_STATS=()
  BEST_EFFORT_ORDERED_BY_STATS=()

  if [[ ${#ORDERED_LINES[@]} -gt 0 ]]; then
    for line in "${ORDERED_LINES[@]}"; do
      [[ -z "$line" ]] && continue
      IFS='|' read -r tag _mac_rate mac_addr <<< "$line"
      case "$tag" in
        Q)
          VALID_MACS_ORDERED_BY_STATS+=("$mac_addr")
          ;;
        R)
          MACS_FOR_RANDOM_FALLBACK+=("$mac_addr")
          ;;
        B)
          BEST_EFFORT_ORDERED_BY_STATS+=("$mac_addr")
          ;;
      esac
    done
  fi

  QUALIFIED_COUNT=${#VALID_MACS_ORDERED_BY_STATS[@]}
  if (( QUALIFIED_COUNT > 0 && QUALIFIED_COUNT < MIN_QUALIFIED_MACS )); then
    MACS_FOR_RANDOM_FALLBACK+=( "${VALID_MACS_ORDERED_BY_STATS[@]}" )
    VALID_MACS_ORDERED_BY_STATS=()
    echo "$(date '+%Y-%m-%d %H:%M:%S') Only $QUALIFIED_COUNT MAC(s) met quality thresholds (< MIN_QUALIFIED_MACS=$MIN_QUALIFIED_MACS); treating them as random fallback." >> "$LOG_FILE"
  fi

  if [[ ${#VALID_MACS_ORDERED_BY_STATS[@]} -gt 0 ]]; then
    list_is_primarily_ordered=true
    mapfile -t SHUFFLED_QUALIFIED_ORDER < <(printf "%s\n" "${VALID_MACS_ORDERED_BY_STATS[@]}" | shuf)
    SHUF_MACS=( "${SHUFFLED_QUALIFIED_ORDER[@]}" )
    echo "$(date '+%Y-%m-%d %H:%M:%S') Prioritizing ${#VALID_MACS_ORDERED_BY_STATS[@]} MACs by success rate (>= $MIN_STATS_ATTEMPTS attempts and >= $MIN_SUCCESS_RATE success rate) and randomizing their order per request." >> "$LOG_FILE"

    if [[ ${#MACS_FOR_RANDOM_FALLBACK[@]} -gt 0 ]]; then
      mapfile -t SHUFFLED_FALLBACK_MACS < <(printf "%s\n" "${MACS_FOR_RANDOM_FALLBACK[@]}" | shuf)
      SHUF_MACS+=( "${SHUFFLED_FALLBACK_MACS[@]}" )
      echo "$(date '+%Y-%m-%d %H:%M:%S') Appending ${#SHUFFLED_FALLBACK_MACS[@]} MACs (below attempt/success thresholds or without stats) in random order." >> "$LOG_FILE"
    fi
  elif [[ ${#BEST_EFFORT_ORDERED_BY_STATS[@]} -gt 0 ]]; then
    list_is_primarily_ordered=true
    SHUF_MACS=( "${BEST_EFFORT_ORDERED_BY_STATS[@]}" )
    echo "$(date '+%Y-%m-%d %H:%M:%S') Thresholds not met; prioritizing all ${#SHUF_MACS[@]} MACs by best available success rate." >> "$LOG_FILE"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') No MACs met the thresholds (>= $MIN_STATS_ATTEMPTS attempts and >= $MIN_SUCCESS_RATE success rate) or no stats available. Using all ${#VALID_MACS_FROM_INFO[@]} valid MACs in random order." >> "$LOG_FILE"
    mapfile -t SHUF_MACS < <(printf "%s\n" "${VALID_MACS_FROM_INFO[@]}" | shuf)
  fi
fi

if [[ ${#SHUF_MACS[@]} -eq 0 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Error: No valid MAC addresses available to attempt (after filtering and ordering)." >> "$LOG_FILE"
  echo "Status: 503 Service Unavailable"
  echo "Content-type: text/plain"
  echo
  echo "No valid MAC address available"
  exit 1
fi

MAC_FOUND=""
LINK=""

ATTEMPT_COUNT="$ATTEMPT_COUNT_INITIAL"
echo "$(date '+%Y-%m-%d %H:%M:%S') Attempt budget configured as $ATTEMPT_COUNT/$MAX_ATTEMPTS starting value." >> "$LOG_FILE"

for MAC in "${SHUF_MACS[@]}"; do
  if [[ "$ATTEMPT_COUNT" -ge "$MAX_ATTEMPTS" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Reached max MAC attempts ($MAX_ATTEMPTS), aborting." >> "$LOG_FILE"
    break
  fi

  attempt_log_source_description="from random list"
  if [[ "$list_is_primarily_ordered" = true ]]; then
    attempt_log_source_description="from ordered list (stats-prioritized)"
  fi
  if mac_is_on_cooldown "$MAC"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Skipping MAC=$MAC (cooldown up to ${MAC_COOLDOWN_SECONDS}s, attempt counter still $ATTEMPT_COUNT/$MAX_ATTEMPTS)." >> "$LOG_FILE"
    continue
  fi
  if ! acquire_mac_lock "$MAC"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Skipping MAC=$MAC because it is already locked by another request (attempt counter still $ATTEMPT_COUNT/$MAX_ATTEMPTS)." >> "$LOG_FILE"
    continue
  fi
  ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
  echo "$(date '+%Y-%m-%d %H:%M:%S') Trying MAC: $MAC (Attempt $ATTEMPT_COUNT/$MAX_ATTEMPTS $attempt_log_source_description)" >> "$LOG_FILE"
  COOKIE="mac=$MAC; stb_lang=en; timezone=Europe/Amsterdam;"
  NOW=$(date '+%Y-%m-%d %H:%M:%S')

  current_mac_succeeded="false"

  echo "$NOW Attempting handshake for MAC=$MAC" >> "$LOG_FILE"
  HANDSHAKE_RESP=""
  CURL_STATUS=0
  if ! HANDSHAKE_RESP=$(curl -s -w "\n%{http_code}" --connect-timeout 5 --max-time 10 -G "$PORTAL_URL/portal.php" \
    --data-urlencode "type=stb" \
    --data-urlencode "action=handshake" \
    --data-urlencode "JsHttpRequest=1-xml" \
    -H "User-Agent: $USER_AGENT" \
    --cookie "$COOKIE"); then
    CURL_STATUS=$?
  fi
  if (( CURL_STATUS != 0 )); then
    echo "$NOW MAC=$MAC handshake curl error (exit $CURL_STATUS)." >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "network"
    continue
  fi
  HANDSHAKE_BODY=$(echo "$HANDSHAKE_RESP" | head -n -1)
  HANDSHAKE_CODE=$(echo "$HANDSHAKE_RESP" | tail -n1)
  echo "$NOW Handshake response code for MAC=$MAC: $HANDSHAKE_CODE" >> "$LOG_FILE"
  echo "$NOW Handshake response body for MAC=$MAC: $HANDSHAKE_BODY" >> "$LOG_FILE"
  if [[ "$HANDSHAKE_CODE" == "456" ]]; then
    echo "$NOW MAC=$MAC HANDSHAKE HTTP=$HANDSHAKE_CODE FAIL (Rate limit)" >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "rate_limit"
    continue
  fi
  if [[ "$HANDSHAKE_CODE" =~ ^(401|403|405)$ ]]; then
    echo "$NOW MAC=$MAC HANDSHAKE HTTP=$HANDSHAKE_CODE FAIL (Auth error)" >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "auth"
    continue
  fi
  TOKEN=$(echo "$HANDSHAKE_BODY" | jq -r '.js.token')
  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "$NOW MAC=$MAC HANDSHAKE HTTP=$HANDSHAKE_CODE FAIL (No token)" >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "token_missing"
    continue
  fi
  echo "$NOW MAC=$MAC HANDSHAKE HTTP=$HANDSHAKE_CODE SUCCESS TOKEN=$TOKEN" >> "$LOG_FILE"

  if [[ "$CHANNEL_ID" =~ \.mkv$|\.mp4$|\.avi$|\.mov$ ]]; then
    TYPE="vod"
    ACTION="create_link"
    VOD_ID="${CHANNEL_ID%%.*}"
    CMD="http://localhost/ch/${VOD_ID}_"
    echo "$NOW Detected VOD request: CMD=$CMD, TYPE=$TYPE, ACTION=$ACTION" >> "$LOG_FILE"

  STREAM_RESP=""
  CURL_STATUS=0
  if ! STREAM_RESP=$(curl -s -w "\n%{http_code}" --connect-timeout 5 --max-time 10 -G "$PORTAL_URL/portal.php" \
      --data-urlencode "type=itv" \
      --data-urlencode "action=create_link" \
      --data-urlencode "cmd=$CMD" \
      --data-urlencode "series=" \
      --data-urlencode "forced_storage=undefined" \
      --data-urlencode "disable_ad=0" \
      --data-urlencode "download=0" \
      --data-urlencode "JsHttpRequest=1-xml" \
      -H "User-Agent: $USER_AGENT" \
      -H "Authorization: Bearer $TOKEN" \
      --cookie "$COOKIE"); then
    CURL_STATUS=$?
  fi
  if (( CURL_STATUS != 0 )); then
    echo "$NOW MAC=$MAC stream curl error during VOD link creation (exit $CURL_STATUS)." >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "network"
    continue
  fi
  else
    CMD="http://localhost/ch/${CHANNEL_ID}_"
    TYPE="itv"
    ACTION="create_link"
    echo "$NOW Detected Live TV request: CMD=$CMD, TYPE=$TYPE, ACTION=$ACTION" >> "$LOG_FILE"

  STREAM_RESP=""
  CURL_STATUS=0
  if ! STREAM_RESP=$(curl -s -w "\n%{http_code}" --connect-timeout 5 --max-time 10 -G "$PORTAL_URL/portal.php" \
      --data-urlencode "type=itv" \
      --data-urlencode "action=$ACTION" \
      --data-urlencode "cmd=$CMD" \
      --data-urlencode "series=" \
      --data-urlencode "forced_storage=undefined" \
      --data-urlencode "disable_ad=0" \
      --data-urlencode "download=0" \
      --data-urlencode "JsHttpRequest=1-xml" \
      -H "User-Agent: $USER_AGENT" \
      -H "Authorization: Bearer $TOKEN" \
      --cookie "$COOKIE"); then
    CURL_STATUS=$?
  fi
  if (( CURL_STATUS != 0 )); then
    echo "$NOW MAC=$MAC stream curl error during live link creation (exit $CURL_STATUS)." >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "network"
    continue
  fi
  fi
  STREAM_BODY=$(echo "$STREAM_RESP" | head -n -1)
  STREAM_CODE=$(echo "$STREAM_RESP" | tail -n1)
  echo "$NOW Stream response code for MAC=$MAC: $STREAM_CODE" >> "$LOG_FILE"
  echo "$NOW Stream response body for MAC=$MAC: $STREAM_BODY" >> "$LOG_FILE"
  if [[ "$STREAM_CODE" == "456" ]]; then
    echo "$NOW MAC=$MAC stream HTTP=$STREAM_CODE FAIL (Rate limit)" >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "rate_limit"
    continue
  fi
  if [[ "$STREAM_CODE" =~ ^(401|403|405)$ ]]; then
    echo "$NOW MAC=$MAC stream HTTP=$STREAM_CODE FAIL (Auth/channel block)" >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "auth"
    continue
  fi
  LINK=$(echo "$STREAM_BODY" | jq -r '.js.cmd')
  LINK="${LINK#'ffmpeg' }"
  LINK="${LINK#ffmpeg }"
  LINK="${LINK# }"

  if [[ "$TYPE" == "vod" && -n "$LINK" && "$LINK" != "null" ]]; then
    LINK="${LINK/live.php/movie.php}"
    EXT="${CHANNEL_ID##*.}"
    LINK=$(echo "$LINK" | sed -E "s/(stream=)${VOD_ID}(\&|$)/\1${VOD_ID}.${EXT}\2/")
    if [[ "$LINK" != *"&type=movie"* ]]; then
      LINK="$LINK&type=movie"
    fi
  fi

  if [[ -z "$LINK" || "$LINK" == "null" ]]; then
    echo "$NOW MAC=$MAC STREAM HTTP=$STREAM_CODE FAIL (No link returned)." >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "link_generation"
    continue
  fi

  echo "$NOW MAC=$MAC STREAM HTTP=$STREAM_CODE SUCCESS (Got potential LINK=$LINK)" >> "$LOG_FILE"
  LINK_CHECK_CODE=""
  CURL_STATUS=0
  if ! LINK_CHECK_CODE=$(curl -s -o /dev/null -w '%{http_code}' -A "$USER_AGENT" --cookie "$COOKIE" --connect-timeout 5 --max-time 10 "$LINK"); then
    CURL_STATUS=$?
  fi
  if (( CURL_STATUS != 0 )); then
    echo "$NOW MAC=$MAC link validation curl error (exit $CURL_STATUS)." >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "network"
    continue
  fi
  echo "$NOW Link check (GET) for MAC=$MAC ($LINK) returned HTTP code: $LINK_CHECK_CODE" >> "$LOG_FILE"

  if [[ "$LINK_CHECK_CODE" == "302" ]]; then
    current_mac_succeeded="true"
    MAC_FOUND="$MAC"
  else
    echo "$NOW MAC=$MAC link validation returned HTTP $LINK_CHECK_CODE." >> "$LOG_FILE"
    release_mac_lock
    handle_mac_failure "$MAC" "link_validation"
    continue
  fi

  if [[ "$current_mac_succeeded" == "true" ]]; then
    update_mac_stats "$MAC" "true" "$STATS_FILE_PATH"
    echo "$NOW MAC=$MAC link successfully validated (HTTP $LINK_CHECK_CODE)." >> "$LOG_FILE"
    if mark_mac_cooldown "$MAC"; then
      echo "$NOW MAC=$MAC marked as active for ${MAC_COOLDOWN_SECONDS}s cooldown." >> "$LOG_FILE"
    else
      echo "$NOW Warning: Failed to mark cooldown for MAC=$MAC." >> "$LOG_FILE"
    fi
    release_mac_lock
    break
  fi
done

release_mac_lock

echo "$(date '+%Y-%m-%d %H:%M:%S') Finished MAC loop. MAC_FOUND=$MAC_FOUND, LINK=$LINK" >> "$LOG_FILE"

if [[ -z "$MAC_FOUND" || -z "$LINK" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Error: No valid MAC address available after trying all options and validating links." >> "$LOG_FILE"
  echo "Status: 503 Service Unavailable"
  echo "Content-type: text/plain"
  echo
  echo "No valid MAC address available"
  exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Redirecting to validated link: $LINK with MAC $MAC_FOUND" >> "$LOG_FILE"
echo "Status: 302 Found"
echo "Location: $LINK"
echo