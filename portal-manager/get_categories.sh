#!/bin/bash
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

DIALOG_BACKTITLE="IPTV Stalker Portal Manager v2.22 © tem_invictus 2025"

PORTAL_NAME="${PORTAL_NAME:-}"
PORTAL_URL="${PORTAL_URL:-}"
MAC="${MAC:-}"
PORTAL_DATA_BASE="/var/www/stalker"
PORTAL_DIR="$PORTAL_DATA_BASE/$PORTAL_NAME"
USER_AGENT="Mozilla/5.0 (QtEmbedded; U; Linux; C)"
COOKIE="mac=$MAC; stb_lang=en; timezone=Europe/Amsterdam;"
REQUEST_DELAY="${REQUEST_DELAY:-0.3}"
REQUEST_RETRIES="${REQUEST_RETRIES:-3}"

exit_with_message() {
  local message="$1"
  if command -v dialog >/dev/null 2>&1; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "$message" 8 80
  else
    echo "$message" >&2
  fi
  exit 1
}

validate_env_or_exit() {
  local reason="$1"
  exit_with_message "$reason"
}

validate_mac_format() {
  local mac="$1"
  [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]
}

should_retry_status() {
  local status="$1"
  case "$status" in
    000|429|456)
      return 0
      ;;
  esac
  if [[ "$status" =~ ^5[0-9][0-9]$ ]]; then
    return 0
  fi
  return 1
}

http_failure_backoff() {
  local status="$1"
  case "$status" in
    000)
      printf '2'
      ;;
    429|456)
      printf '3'
      ;;
    5??)
      printf '1'
      ;;
    *)
      printf '0.5'
      ;;
  esac
}

describe_http_failure() {
  local status="$1"
  local context="$2"
  case "$status" in
    000)
      printf '[!] Network error while %s. Check connectivity or portal availability.' "$context"
      ;;
    401|403)
      printf '[!] Portal rejected the MAC while %s (HTTP %s). Try a different MAC or verify credentials.' "$context" "$status"
      ;;
    456)
      printf '[!] Portal rate-limited requests while %s (HTTP 456). Wait a moment or switch MACs before retrying.' "$context"
      ;;
    429)
      printf '[!] Portal returned HTTP 429 (Too Many Requests) while %s. Reduce frequency and retry later.' "$context"
      ;;
    5??)
      printf '[!] Portal returned HTTP %s while %s. The server might be down; try again shortly.' "$status" "$context"
      ;;
    *)
      printf '[!] Portal returned HTTP %s while %s. Please verify the portal status and try again.' "$status" "$context"
      ;;
  esac
}

handle_http_failure() {
  local status="$1"
  local context="$2"
  local attempt="$3"
  local max_attempts="$4"
  if (( attempt < max_attempts )) && should_retry_status "$status"; then
    sleep "$(http_failure_backoff "$status")"
    return 0
  fi
  local message
  message=$(describe_http_failure "$status" "$context")
  exit_with_message "$message"
}

extract_categories() {
  local json_body="$1"
  local parsed
  parsed=$(echo "$json_body" | jq -r '
    def pick_title($o):
      ($o.title // $o.name // $o.caption // $o.title_en // $o.title_ru // $o.value // $o.label // "") as $t
      | if ($t|type)=="string" then $t
        elif ($t|type)=="number" then ($t|tostring)
        elif ($t|type)=="array" then ($t[]? | select(type=="string") | .)
        elif ($t|type)=="object" then ($t[]? | select(type=="string") | .)
        else ""
        end;
    def pick_id($o):
      ($o.id // $o.genre_id // $o.category_id // $o.num // $o.number // $o.key // $o.ID // $o.slug // $o.code // $o.value // "") as $id
      | if ($id|type)=="string" then $id
        elif ($id|type)=="number" then ($id|tostring)
        else ""
        end;
    def normalize($data):
      if ($data|type)=="array" then $data
      elif ($data.data? | type)=="array" then $data.data
      elif ($data|type)=="object" then
        if ($data.data? | type)=="object" then ($data.data | to_entries | map(.value))
        else ($data | to_entries | map(.value))
        end
      else []
      end;
    (.js // .js.data // .data // .) as $root
    | normalize($root)
    | map({id: pick_id(.), title: pick_title(.)})
    | map(select((.id|length)>0 and (.title|length)>0))
    | unique_by(.id)
    | sort_by(.title | ascii_downcase)
    | .[]
    | "\(.id):\(.title)"
  ' 2>/dev/null | sed '/^[[:space:]]*$/d')
  if [[ -n "$parsed" ]]; then
    printf '%s\n' "$parsed"
    return 0
  fi
  return 1
}

if [[ -z "$PORTAL_NAME" ]]; then
  validate_env_or_exit "[!] PORTAL_NAME is required."
fi

if [[ -z "$PORTAL_URL" || ! "$PORTAL_URL" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
  validate_env_or_exit "[!] PORTAL_URL is missing or invalid (must start with http:// or https://)."
fi

if [[ -z "$MAC" ]] || ! validate_mac_format "$MAC"; then
  validate_env_or_exit "[!] MAC address is required and must be in XX:XX:XX:XX:XX:XX format."
fi

throttle_request() {
  local delay_value="${REQUEST_DELAY:-0}"
  awk -v d="$delay_value" 'BEGIN {exit !(d+0>0)}' >/dev/null 2>&1 && sleep "$delay_value"
}

HANDSHAKE_SUCCESS=false
TOKEN=""
for (( attempt=1; attempt<=REQUEST_RETRIES; attempt++ )); do
  HANDSHAKE_RAW=$(curl -sS --max-time 10 -w '\n%{http_code}' -G "$PORTAL_URL/portal.php" \
    --data-urlencode "type=stb" \
    --data-urlencode "action=handshake" \
    --data-urlencode "JsHttpRequest=1-xml" \
    -H "User-Agent: $USER_AGENT" \
    --cookie "$COOKIE") || HANDSHAKE_RAW=$'\n000'
  HANDSHAKE_BODY=$(echo "$HANDSHAKE_RAW" | head -n -1)
  HANDSHAKE_CODE=$(echo "$HANDSHAKE_RAW" | tail -n1)
  throttle_request
  if [[ "$HANDSHAKE_CODE" == "200" ]]; then
    TOKEN=$(echo "$HANDSHAKE_BODY" | jq -r '.js.token' 2>/dev/null)
    if [[ -n "$TOKEN" && "$TOKEN" != "null" ]]; then
      HANDSHAKE_SUCCESS=true
      break
    fi
    exit_with_message "[!] Handshake succeeded but no token was returned. Please verify the portal configuration."
  fi
  handle_http_failure "$HANDSHAKE_CODE" "performing the handshake" "$attempt" "$REQUEST_RETRIES"
done

if [[ "$HANDSHAKE_SUCCESS" != true ]]; then
  exit_with_message "[!] Failed to retrieve a token after $REQUEST_RETRIES attempt(s)."
fi

FETCH_STATUS="200"

ensure_portal_dir() {
  if [[ ! -d "$PORTAL_DIR" ]]; then
    mkdir -p "$PORTAL_DIR"
    set_www_owner "$PORTAL_DIR"
  fi
}

set_www_owner() {
  local target="$1"
  [[ -z "$target" ]] && return
  if [[ $EUID -eq 0 ]]; then
    chown www-data:www-data "$target" 2>/dev/null || true
  fi
}

sanitize_id() {
  local value="$1"
  value="${value//$'\r'/}"
  value="${value//$'\n'/}"
  value="${value//$'\t'/}"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf "%s" "$value"
}

fetch_categories() {
  local mode="$1" outfile="$2" curl_type action
  if [[ "$mode" == "live" ]]; then
    curl_type="itv"
    action="get_genres"
  else
    curl_type="vod"
    action="get_categories"
  fi

  local context_label
  if [[ "$mode" == "live" ]]; then
    context_label="fetching LiveTV categories"
  else
    context_label="fetching VOD categories"
  fi

  local raw body status categories
  for (( attempt=1; attempt<=REQUEST_RETRIES; attempt++ )); do
    raw=$(curl -sS --max-time 10 -w '\n%{http_code}' -G "$PORTAL_URL/portal.php" \
      --data-urlencode "type=$curl_type" \
      --data-urlencode "action=$action" \
      --data-urlencode "JsHttpRequest=1-xml" \
      -H "User-Agent: $USER_AGENT" \
      -H "Authorization: Bearer $TOKEN" \
      --cookie "$COOKIE") || raw=$'\n000'

    body=$(echo "$raw" | head -n -1)
    status=$(echo "$raw" | tail -n1)
    throttle_request
    FETCH_STATUS="$status"
    if [[ "$status" == "200" ]]; then
      if ! categories=$(extract_categories "$body"); then
        local snippet
        snippet=$(echo "$body" | head -c 400 | tr '\n' ' ')
        exit_with_message "[!] Portal returned unexpected data while $context_label. Sample: ${snippet}"
      fi
      echo "$categories" > "$outfile"
      set_www_owner "$outfile"
      printf "%s" "$categories"
      return 0
    fi
    handle_http_failure "$status" "$context_label" "$attempt" "$REQUEST_RETRIES"
  done

  exit_with_message "[!] Failed to load categories after $REQUEST_RETRIES attempt(s) while $context_label."
}

load_selected_ids() {
  local file="$1"
  local -n target_ref=$2
  target_ref=()
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    local sel_id
    IFS=':' read -r sel_id _ <<< "$line"
    sel_id=$(sanitize_id "$sel_id")
    [[ -n "$sel_id" ]] && target_ref+=("$sel_id")
  done < "$file"
}

build_checklist_items() {
  local categories="$1"
  local -n selected_ref=$2
  local -n output_ref=$3
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local genre_id="${entry%%:*}"
    genre_id=$(sanitize_id "$genre_id")
    local genre_title="${entry#*:}"
    local default="off"
    for sel in "${selected_ref[@]}"; do
      sel=$(sanitize_id "$sel")
      if [[ "$genre_id" == "$sel" ]]; then
        default="on"
        break
      fi
    done
    output_ref+=("$genre_id" "$genre_title" "$default")
  done <<< "$categories"
}

build_selection_payload() {
  local selected_ids="$1"
  local categories="$2"
  local payload=""
  while IFS= read -r sel_id || [[ -n "$sel_id" ]]; do
    sel_id=$(sanitize_id "$sel_id")
    [[ -z "$sel_id" ]] && continue
    local title
    title=$(echo "$categories" | grep "^$sel_id:" | cut -d: -f2-)
    [[ -n "$title" ]] && payload+="$sel_id:$title\n"
  done <<< "$selected_ids"
  printf "%b" "$payload"
}

save_selection() {
  local data="$1" outfile="$2"
  printf "%b" "$data" > "$outfile"
  set_www_owner "$outfile"
}

ensure_portal_dir

MODE_LABEL="LiveTV"
CATEGORY_FILE="$PORTAL_DIR/chosentv"
AVAILABLE_FILE="$PORTAL_DIR/availabletv"
MODE="live"

if [[ -n "$VOD_ONLY" ]]; then
  MODE_LABEL="VOD"
  CATEGORY_FILE="$PORTAL_DIR/chosenvod"
  AVAILABLE_FILE="$PORTAL_DIR/availablevod"
  MODE="vod"
fi

if ! ALL_CATEGORIES=$(fetch_categories "$MODE" "$AVAILABLE_FILE"); then
  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "[!] Failed to load $MODE_LABEL categories (HTTP $FETCH_STATUS)." 9 70
  exit 1
fi

SELECTED_IDS=()
load_selected_ids "$CATEGORY_FILE" SELECTED_IDS

CHECKLIST_ITEMS=()
build_checklist_items "$ALL_CATEGORIES" SELECTED_IDS CHECKLIST_ITEMS

if [[ ${#CHECKLIST_ITEMS[@]} -eq 0 ]]; then
  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "[!] No $MODE_LABEL categories found." 8 60
  exit 1
fi

DIALOG_OUTPUT=$(dialog --backtitle "$DIALOG_BACKTITLE" --separate-output --checklist "Select $MODE_LABEL categories (use space to select, enter to finish):" 50 60 40 \
  "${CHECKLIST_ITEMS[@]}" 3>&1 1>&2 2>&3)
DIALOG_STATUS=$?

if [[ $DIALOG_STATUS -ne 0 ]]; then
  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "No $MODE_LABEL categories selected. Nothing saved." 8 60
  exit 2
fi

mapfile -t SELECTED_LINES <<< "$DIALOG_OUTPUT"$'\n'

if [[ ${#SELECTED_LINES[@]} -eq 0 ]]; then
  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "No $MODE_LABEL categories selected. Nothing saved." 8 60
  exit 2
fi

SELECTED_STRING=$(printf '%s\n' "${SELECTED_LINES[@]}")
CHOOSEN_GENRES=$(build_selection_payload "$SELECTED_STRING" "$ALL_CATEGORIES")
save_selection "$CHOOSEN_GENRES" "$CATEGORY_FILE"

exit 0
