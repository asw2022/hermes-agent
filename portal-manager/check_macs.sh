#!/bin/bash
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

DIALOG_BACKTITLE="IPTV Stalker Portal Manager v2.22 © tem_invictus 2025"

PORTAL_NAME="${PORTAL_NAME:-}"
DEFAULT_PORTALS_LIST="/var/www/stalker/portals.list"
LEGACY_PORTALS_LIST="$(dirname "$0")/portals.list"
PORTALS_LIST="${PORTALS_LIST:-$DEFAULT_PORTALS_LIST}"
if [[ ! -f "$PORTALS_LIST" && -f "$LEGACY_PORTALS_LIST" ]]; then
  PORTALS_LIST="$LEGACY_PORTALS_LIST"
fi
PORTAL_DATA_BASE="/var/www/stalker"
PORTAL_DIR="$PORTAL_DATA_BASE/$PORTAL_NAME"
MACS_FILE="$PORTAL_DIR/macs.txt"
CATEGORIES_FILE="$PORTAL_DIR/chosentv"
CONFIG_FILE="$PORTAL_DIR/config"
MACS_INFO_FILE="$PORTAL_DIR/macs_info.txt"
USER_AGENT="Mozilla/5.0 (QtEmbedded; U; Linux; C)"
COOKIE_BASE="stb_lang=en; timezone=Europe/Amsterdam;"
SANITIZED_PORTAL_NAME=${PORTAL_NAME//[^A-Za-z0-9_-]/_}
LOGFILE=$(mktemp "/tmp/check_macs_progress_${SANITIZED_PORTAL_NAME}_XXXXXX.log")
REQUEST_DELAY="${REQUEST_DELAY:-0.3}"
REQUEST_RETRIES="${REQUEST_RETRIES:-3}"
FAILURE_ACTION="${FAILURE_ACTION:-mark}"

clear

exit_env_error() {
  local message="$1"
  if command -v dialog >/dev/null 2>&1; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "$message" 8 80
  else
    echo "$message" >&2
  fi
  rm -f "$LOGFILE"
  exit 1
}

validate_mac_format() {
  local mac="$1"
  [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]
}

FAILURE_ACTION=$(echo "$FAILURE_ACTION" | tr 'A-Z' 'a-z')
case "$FAILURE_ACTION" in
  mark|delete|skip)
    ;;
  *)
    FAILURE_ACTION="skip"
    ;;
esac

if [[ -z "$REQUEST_RETRIES" || ! "$REQUEST_RETRIES" =~ ^[0-9]+$ || "$REQUEST_RETRIES" -lt 1 ]]; then
  REQUEST_RETRIES=3
fi

MAC_CHECK_DELAY=5
RETRY_BACKOFF_BASE="${RETRY_BACKOFF_BASE:-2}"

if [[ -f "$PORTALS_LIST" ]]; then
  DELAY=$(grep "^$PORTAL_NAME|" "$PORTALS_LIST" | cut -d'|' -f4)
  [[ -n "$DELAY" && "$DELAY" =~ ^[0-9]+$ ]] && MAC_CHECK_DELAY="$DELAY"
fi

log_step() {
  echo -e "$1" | tee -a "$LOGFILE"
}

throttle_request() {
  local delay="${REQUEST_DELAY:-0}"
  awk -v d="$delay" 'BEGIN {exit !(d+0>0)}' >/dev/null 2>&1 && sleep "$delay"
}

retry_backoff_delay() {
  local attempt="$1"
  local multiplier=$(( attempt - 1 ))
  if (( multiplier < 0 )); then
    multiplier=0
  fi
  awk -v base="$RETRY_BACKOFF_BASE" -v mult="$multiplier" 'BEGIN { printf "%.2f", base * (1 + 0.5*mult) }'
}

portal_request() {
  local dest_var="$1"; shift
  local description="$1"; shift
  local curl_args=("$@")

  local raw body status
  raw=$(curl -sS --max-time 15 -w '\n%{http_code}' -G "$PORTAL_URL/portal.php" "${curl_args[@]}") || raw=$'\n000'
  body=$(echo "$raw" | head -n -1)
  status=$(echo "$raw" | tail -n1)

  if [[ "$status" != "200" ]]; then
    log_step "[!] $description failed (HTTP $status). Skipping for now."
    return 1
  fi

  if ! echo "$body" | jq empty >/dev/null 2>&1; then
    log_step "[!] $description returned invalid JSON. Skipping."
    return 1
  fi

  printf -v "$dest_var" '%s' "$body"
  throttle_request
  return 0
}

request_with_retries() {
  local dest_var="$1"; shift
  local description="$1"; shift
  local attempt=1
  while (( attempt <= REQUEST_RETRIES )); do
    if portal_request "$dest_var" "$description (attempt $attempt/$REQUEST_RETRIES)" "$@"; then
      return 0
    fi
    (( attempt++ ))
    if (( attempt <= REQUEST_RETRIES )); then
      local backoff
      backoff=$(retry_backoff_delay "$attempt")
      log_step "    [!] $description retrying in ${backoff}s"
      sleep "$backoff"
    fi
  done
  return 1
}

handle_mac_failure() {
  local mac="$1"
  local reason="$2"
  [[ -z "$mac" ]] && return
  case "$FAILURE_ACTION" in
    delete)
      log_step "    [-] Failure action (delete) for $mac: $reason"
      sed -i "/^$mac|/d" "$MACS_INFO_FILE"
      sed -i "/^$mac[[:space:]]*$/d" "$MACS_FILE"
      ;;
    mark)
      log_step "    [-] Failure action (mark) for $mac: $reason"
      sed -i "/^$mac|/d" "$MACS_INFO_FILE"
      echo "$mac||no|0" >> "$MACS_INFO_FILE"
      ;;
    *)
      log_step "    [-] Failure action skipped for $mac (policy: $FAILURE_ACTION). Reason: $reason"
      ;;
  esac
}

normalize_stream() {
  sed \
    -e 's/\xC2\xA0/ /g' \
    -e 's/[[:space:]]\+/ /g' \
    -e 's/^[[:space:]]\+//; s/[[:space:]]\+$//' \
  -e 's/[[:space:]]*|[[:space:]]*/ | /g'
}

if [[ ! -f "$MACS_FILE" || ! -f "$CATEGORIES_FILE" || ! -f "$CONFIG_FILE" ]]; then
  log_step "[!] Missing required files (macs.txt, chosentv, or config) for portal $PORTAL_NAME."
  dialog --backtitle "$DIALOG_BACKTITLE" --textbox "$LOGFILE" 40 120
  rm -f "$LOGFILE"
  exit 1
fi

PORTAL_URL=$(head -n1 "$CONFIG_FILE" 2>/dev/null)
if [[ -z "$PORTAL_URL" || ! "$PORTAL_URL" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
  exit_env_error "[!] Config file for $PORTAL_NAME does not contain a valid portal URL."
fi

if [[ ! -s "$MACS_INFO_FILE" ]]; then
  echo "MAC|expiration|categories_valid|category_count" > "$MACS_INFO_FILE"
fi

MACS_TO_CHECK=()
if [[ "$CHECK_MODE" == "2" && -f "$MACS_INFO_FILE" ]]; then
  while IFS= read -r mac; do
    mac=$(echo "$mac" | xargs)
    [[ -z "$mac" ]] && continue
    if ! grep -q "^$mac|" "$MACS_INFO_FILE"; then
      MACS_TO_CHECK+=("$mac")
    fi
  done < "$MACS_FILE"
  if [[ ${#MACS_TO_CHECK[@]} -eq 0 ]]; then
    log_step "[!] No new MACs to check."
    dialog --backtitle "$DIALOG_BACKTITLE" --textbox "$LOGFILE" 10 60
    rm -f "$LOGFILE"
    clear
    exit 0
  fi
else
  declare -A MAC_SET
  if [[ -f "$MACS_FILE" ]]; then
    while IFS= read -r mac; do
      mac=$(echo "$mac" | xargs)
      [[ -z "$mac" ]] && continue
      MAC_SET["$mac"]=1
    done < "$MACS_FILE"
  fi
  if [[ -f "$MACS_INFO_FILE" ]]; then
    while IFS='|' read -r mac _; do
      [[ "$mac" == "MAC" ]] && continue
      mac=$(echo "$mac" | xargs)
      [[ -z "$mac" ]] && continue
      MAC_SET["$mac"]=1
    done < "$MACS_INFO_FILE"
  fi
  for mac in "${!MAC_SET[@]}"; do
    MACS_TO_CHECK+=("$mac")
  done
fi

TOTAL_MACS_TO_CHECK=${#MACS_TO_CHECK[@]}
CURRENT_INDEX=0
PROCESSED_MACS=0
VALID_CATEGORY_MACS=0
INVALID_CATEGORY_MACS=0
SKIPPED_MACS=0
INVALID_FORMAT_MACS=0

log_step "[+] Checking MACs for portal '$PORTAL_NAME' ($TOTAL_MACS_TO_CHECK total)..."

for MAC in "${MACS_TO_CHECK[@]}"; do
  ((CURRENT_INDEX++))
  MAC=$(echo "$MAC" | xargs)
  [[ -z "$MAC" ]] && continue
  if ! validate_mac_format "$MAC"; then
    log_step "[!] Skipping invalid MAC format: $MAC"
    handle_mac_failure "$MAC" "invalid mac format"
    ((INVALID_FORMAT_MACS++))
    ((SKIPPED_MACS++))
    continue
  fi
  log_step "Checking [$CURRENT_INDEX/$TOTAL_MACS_TO_CHECK] $MAC..."

  COOKIE="mac=$MAC; stb_lang=en; timezone=Europe/Amsterdam;"
  HANDSHAKE_BODY=""
  if ! request_with_retries HANDSHAKE_BODY "Handshake for $MAC" \
    --data-urlencode "type=stb" \
    --data-urlencode "action=handshake" \
    --data-urlencode "JsHttpRequest=1-xml" \
    -H "User-Agent: $USER_AGENT" \
    --cookie "$COOKIE"; then
    log_step "[!] Skipping $MAC due to handshake failure."
    handle_mac_failure "$MAC" "handshake request failed"
    sleep "$MAC_CHECK_DELAY"
    ((SKIPPED_MACS++))
    continue
  fi
  TOKEN=$(echo "$HANDSHAKE_BODY" | jq -r '.js.token' 2>/dev/null)
  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    log_step "[!] Handshake for $MAC returned no token. Skipping."
    handle_mac_failure "$MAC" "handshake returned no token"
    sleep "$MAC_CHECK_DELAY"
    ((SKIPPED_MACS++))
    continue
  fi

  EXP_JSON=""
  if ! request_with_retries EXP_JSON "Account info for $MAC" \
    --data-urlencode "type=account_info" \
    --data-urlencode "action=get_main_info" \
    --data-urlencode "mac=$MAC" \
    -H "User-Agent: $USER_AGENT" \
    -H "Authorization: Bearer $TOKEN" \
    --cookie "$COOKIE"; then
    handle_mac_failure "$MAC" "account info request failed"
    sleep "$MAC_CHECK_DELAY"
    ((SKIPPED_MACS++))
    continue
  fi
  EXP_DATE=$(echo "$EXP_JSON" | jq -r '.js.phone' 2>/dev/null)
  if [[ -n "$EXP_DATE" && "$EXP_DATE" != "null" ]]; then
    PARSED_DATE=$(date -d "$EXP_DATE" +%Y-%m-%d 2>/dev/null)
    if [[ -z "$PARSED_DATE" ]]; then
      RAW_DATE=$(echo "$EXP_DATE" | grep -oE '[A-Za-z]+ [0-9]{1,2}, [0-9]{4}')
      if [[ -n "$RAW_DATE" ]]; then
        PARSED_DATE=$(date -d "$RAW_DATE" +%Y-%m-%d 2>/dev/null)
      fi
    fi
    EXP_DATE="$PARSED_DATE"
  else
    EXP_DATE=""
  fi

  genres_json=""
  if ! request_with_retries genres_json "Fetch genres for $MAC" \
    --data-urlencode "type=itv" \
    --data-urlencode "action=get_genres" \
    --data-urlencode "JsHttpRequest=1-xml" \
    -H "User-Agent: $USER_AGENT" \
    -H "Authorization: Bearer $TOKEN" \
    --cookie "$COOKIE"; then
    handle_mac_failure "$MAC" "genre list request failed"
    sleep "$MAC_CHECK_DELAY"
    ((SKIPPED_MACS++))
    continue
  fi
  livegroups_raw=$(echo "$genres_json" | jq -r '.js[].title' 2>/dev/null)
  live_ids=$(echo "$genres_json" | jq -r '.js[].id' 2>/dev/null | tr -d '\r')
  livegroups=()
  if [[ -n "$livegroups_raw" ]]; then
    while IFS= read -r live_line || [[ -n "$live_line" ]]; do
      cleaned_line=$(printf '%s\n' "$live_line" | normalize_stream)
      [[ -n "$cleaned_line" ]] && livegroups+=("$cleaned_line")
    done <<< "$livegroups_raw"
  fi
  if [[ ${#livegroups[@]} -gt 0 ]]; then
    livegroups_text=$(printf '%s\n' "${livegroups[@]}")
  else
    livegroups_text=""
  fi
  CATEGORY_COUNT=${#livegroups[@]}
  ALL_PRESENT=1
  MISSING_CATEGORIES=()
  while IFS= read -r REQ_CAT_LINE || [[ -n "$REQ_CAT_LINE" ]]; do
    REQ_CAT_LINE=$(echo "$REQ_CAT_LINE" | tr -d '\r')
    REQ_CAT_ID_RAW="${REQ_CAT_LINE%%:*}"
    REQ_CAT_ID=$(echo "$REQ_CAT_ID_RAW" | tr -d '[:space:]')
    REQ_CAT_TITLE="${REQ_CAT_LINE#*:}"
    REQ_CAT_TITLE=$(printf '%s\n' "$REQ_CAT_TITLE" | normalize_stream)
    if [[ -z "$REQ_CAT_ID" && -z "$REQ_CAT_TITLE" ]]; then
      continue
    fi

    MISSING=0
    if [[ "$REQ_CAT_ID" =~ ^[0-9]+$ ]]; then
      if ! printf '%s\n' "$live_ids" | grep -Fxq "$REQ_CAT_ID"; then
        MISSING=1
      fi
    else
      if ! printf '%s\n' "$livegroups_text" | grep -Fxqi "$REQ_CAT_TITLE"; then
        MISSING=1
      fi
    fi

    if [[ $MISSING -eq 1 ]]; then
      if [[ "$REQ_CAT_ID" =~ ^[0-9]+$ ]]; then
        MISSING_CATEGORIES+=("    [!] Missing required category (id=$REQ_CAT_ID, title=$REQ_CAT_TITLE)")
      else
        MISSING_CATEGORIES+=("    [!] Missing required category: $REQ_CAT_TITLE")
      fi
      ALL_PRESENT=0
      continue
    fi
  done < "$CATEGORIES_FILE"
  if [[ ${#MISSING_CATEGORIES[@]} -gt 0 ]]; then
    for missing_msg in "${MISSING_CATEGORIES[@]}"; do
      log_step "$missing_msg"
    done
  fi
  CATEGORIES_VALID_STR="no"
  [[ $ALL_PRESENT -eq 1 ]] && CATEGORIES_VALID_STR="yes"
  ((PROCESSED_MACS++))
  if [[ $ALL_PRESENT -eq 1 ]]; then
    ((VALID_CATEGORY_MACS++))
  else
    ((INVALID_CATEGORY_MACS++))
  fi
  log_step "  [+] $MAC expiration: $EXP_DATE, categories_valid: $CATEGORIES_VALID_STR, category_count: $CATEGORY_COUNT"
  sed -i "/^$MAC|/d" "$MACS_INFO_FILE"
  echo "$MAC|$EXP_DATE|$CATEGORIES_VALID_STR|$CATEGORY_COUNT" >> "$MACS_INFO_FILE"

  sed -i "/^$MAC[[:space:]]*$/d" "$MACS_FILE"

  sleep $MAC_CHECK_DELAY

done

log_step ""
log_step "[+] MAC check summary:"
log_step "    - Processed: $PROCESSED_MACS of $TOTAL_MACS_TO_CHECK"
log_step "    - Categories valid: $VALID_CATEGORY_MACS"
log_step "    - Categories missing: $INVALID_CATEGORY_MACS"
log_step "    - Skipped (errors): $SKIPPED_MACS"
log_step "    - Invalid format skipped: $INVALID_FORMAT_MACS"

if [[ -f "$MACS_INFO_FILE" ]]; then
  if [[ $EUID -eq 0 ]]; then
    chown www-data:www-data "$MACS_INFO_FILE"
  fi
  chmod 644 "$MACS_INFO_FILE"
fi

dialog --backtitle "$DIALOG_BACKTITLE" --textbox "$LOGFILE" 40 120
rm -f "$LOGFILE"

clear
