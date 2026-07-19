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
MACS_INFO_FILE="$PORTAL_DIR/macs_info.txt"
USER_AGENT="Mozilla/5.0 (QtEmbedded; U; Linux; C)"
COOKIE="mac=$MAC; stb_lang=en; timezone=Europe/Amsterdam;"
PROXY_SERVER=$(cat proxy_server.conf | xargs)
REQUEST_DELAY="${REQUEST_DELAY:-0.3}"
REQUEST_RETRIES="${REQUEST_RETRIES:-3}"

exit_env_error() {
  local message="$1"
  if command -v dialog >/dev/null 2>&1; then
    dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "$message" 8 80
  else
    echo "$message" >&2
  fi
  exit 1
}

validate_mac_format() {
  local mac="$1"
  [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]
}

if [[ -z "$PORTAL_NAME" ]]; then
  exit_env_error "[!] PORTAL_NAME is required."
fi

if [[ -z "$PORTAL_URL" || ! "$PORTAL_URL" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
  exit_env_error "[!] PORTAL_URL is missing or invalid (must start with http:// or https://)."
fi

if [[ -z "$MAC" ]] || ! validate_mac_format "$MAC"; then
  exit_env_error "[!] MAC address is required and must be in XX:XX:XX:XX:XX:XX format."
fi

SANITIZED_PORTAL_NAME=${PORTAL_NAME//[^A-Za-z0-9_-]/_}
LOGFILE=$(mktemp "/tmp/generate_m3u_progress_${SANITIZED_PORTAL_NAME}_XXXXXX.log")

clear

set_portal_permissions() {
  if [[ $EUID -eq 0 ]]; then
    chown "$USER":www-data "$PORTAL_DIR" 2>/dev/null || true
    chmod 2775 "$PORTAL_DIR" 2>/dev/null || true
  fi
}

ensure_portal_dir() {
  if [[ ! -d "$PORTAL_DIR" ]]; then
    mkdir -p "$PORTAL_DIR"
    set_portal_permissions
  fi
}

log_step() {
  echo -e "$1" | tee -a "$LOGFILE"
}

fail_with_dialog() {
  local msg="$1"
  log_step "[!] $msg"
  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "$msg" 10 70
  rm -f "$LOGFILE"
  exit 1
}

throttle_request() {
  local delay="${REQUEST_DELAY:-0}"
  awk -v d="$delay" 'BEGIN {exit !(d+0>0)}' >/dev/null 2>&1 && sleep "$delay"
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
      printf '[!] Portal rejected the MAC while %s (HTTP %s). Verify credentials or pick another MAC.' "$context" "$status"
      ;;
    429)
      printf '[!] Portal returned HTTP 429 while %s. Reduce request frequency and try again later.' "$context"
      ;;
    456)
      printf '[!] Portal rate-limited requests while %s (HTTP 456). Wait before retrying.' "$context"
      ;;
    5??)
      printf '[!] Portal returned HTTP %s while %s. The server might be down; try again shortly.' "$status" "$context"
      ;;
    *)
      printf '[!] Portal returned HTTP %s while %s. Please verify the portal status and try again.' "$status" "$context"
      ;;
  esac
}

portal_request() {
  local dest_var="$1"; shift
  local description="$1"; shift
  local auth_mode="$1"; shift

  local raw body status
  local attempt
  for (( attempt=1; attempt<=REQUEST_RETRIES; attempt++ )); do
    local curl_cmd=(curl -sS --max-time 15 -w '\n%{http_code}' -G "$PORTAL_URL/portal.php"
      "$@"
      -H "User-Agent: $USER_AGENT"
      --cookie "$COOKIE")

    if [[ "$auth_mode" == "auth" ]]; then
      curl_cmd+=(-H "Authorization: Bearer $TOKEN")
    fi

    raw=$("${curl_cmd[@]}") || raw=$'\n000'
    body=$(echo "$raw" | head -n -1)
    status=$(echo "$raw" | tail -n1)

    if [[ "$status" == "200" ]]; then
      if ! echo "$body" | jq empty >/dev/null 2>&1; then
        fail_with_dialog "$description returned invalid JSON."
      fi
      printf -v "$dest_var" '%s' "$body"
      throttle_request
      return 0
    fi

    if (( attempt < REQUEST_RETRIES )) && should_retry_status "$status"; then
      local backoff
      backoff=$(http_failure_backoff "$status")
      log_step "[!] $description failed (HTTP $status). Retrying in ${backoff}s..."
      sleep "$backoff"
      continue
    fi

    fail_with_dialog "$(describe_http_failure "$status" "$description")"
  done
}

if [[ ! -f "proxy_server.conf" ]] || [[ -z $(cat proxy_server.conf | xargs) ]]; then
  dialog --backtitle "$DIALOG_BACKTITLE" --msgbox "Proxy hostname is not set. Please set it from the main menu before generating the playlist." 8 60
  exit 1
fi

if [[ -n "$VOD_MODE" ]]; then
  CATEGORY_FILE="$PORTAL_DIR/chosenvod"
  SOURCE_M3U="$PORTAL_DIR/source_${PORTAL_NAME}_vod.m3u"
  PROXY_M3U="$PORTAL_DIR/proxy_${PORTAL_NAME}_vod.m3u"
  TYPE_ARG="vod"
else
  CATEGORY_FILE="$PORTAL_DIR/chosentv"
  SOURCE_M3U="$PORTAL_DIR/source_${PORTAL_NAME}.m3u"
  PROXY_M3U="$PORTAL_DIR/proxy_${PORTAL_NAME}.m3u"
  TYPE_ARG="itv"
fi

if [[ ! -f "$CATEGORY_FILE" ]]; then
  log_step "[!] $( [[ -n "$VOD_MODE" ]] && echo 'chosenvod' || echo 'chosentv' ) not found for portal '$PORTAL_NAME'. Run Get Categories first."
  dialog --backtitle "$DIALOG_BACKTITLE" --tailbox "$LOGFILE" 20 80
  rm -f "$LOGFILE"
  exit 2
fi

declare -A GENRE_MAP
while IFS= read -r entry || [[ -n "$entry" ]]; do
  GENRE_ID="${entry%%:*}"
  GENRE_NAME="${entry#*:}"
  GENRE_MAP["$GENRE_ID"]="$GENRE_NAME"
done < "$CATEGORY_FILE"

ensure_portal_dir

echo "#EXTM3U" > "$SOURCE_M3U"

HANDSHAKE_BODY=""
portal_request HANDSHAKE_BODY "Portal handshake" "noauth" \
  --data-urlencode "type=stb" \
  --data-urlencode "action=handshake" \
  --data-urlencode "JsHttpRequest=1-xml"

TOKEN=$(echo "$HANDSHAKE_BODY" | jq -r '.js.token' 2>/dev/null)
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  fail_with_dialog "Portal handshake succeeded but no token was returned."
fi

log_step "[+] Getting channels for selected genres..."

TEMP_DIR=$(mktemp -d /tmp/m3u_generation_XXXXXX)
META_DIR="$TEMP_DIR/meta"
RESULTS_DIR="$TEMP_DIR/results"
FAILED_DIR="$TEMP_DIR/failed"
mkdir -p "$META_DIR" "$RESULTS_DIR" "$FAILED_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

TOTAL_CHANNELS=0
SUCCESSFUL_CHANNELS=0
FAILED_CHANNELS=0

process_channel() {
  local GENRE_ID="$1"
  local CHANNEL_INDEX="$2"
  local CHANNEL="$3"

  local CH_ID NAME LOGO XMLTV CH_NUMBER CMD

  CH_ID=$(echo "$CHANNEL" | jq -r '.id')
  NAME=$(echo "$CHANNEL" | jq -r '.name')
  LOGO=$(echo "$CHANNEL" | jq -r '.logo')
  CMD=$(echo "$CHANNEL" | jq -r '.cmd')

  if [[ -z "$VOD_MODE" ]]; then
    XMLTV=$(echo "$CHANNEL" | jq -r '.xmltv_id // empty')
    CH_NUMBER=$(echo "$CHANNEL" | jq -r '.number // empty')
  else
    XMLTV=""
    CH_NUMBER=""
  fi

  if [[ -z "$LOGO" || "$LOGO" == "null" ]]; then
    if [[ -n "$VOD_MODE" ]]; then
      LOGO=$(echo "$CHANNEL" | jq -r '.screenshot_uri // .cover_uri // empty')
    else
      LOGO=$(echo "$CHANNEL" | jq -r '.screenshot_uri // empty')
    fi
  fi

  if [[ -z "$CMD" || "$CMD" == "null" ]]; then
    return
  fi

  {
    echo "$CH_ID"
    echo "$NAME"
    echo "$LOGO"
    echo "$XMLTV"
    echo "$CH_NUMBER"
    echo "$CMD"
    echo "$CHANNEL_INDEX"
  } > "$META_DIR/${GENRE_ID}_$(printf "%05d" "$CHANNEL_INDEX")_${CH_ID}.meta"
}

for GENRE_ID in "${!GENRE_MAP[@]}"; do
  log_step "  - Fetching channels for '${GENRE_MAP[$GENRE_ID]}' (ID $GENRE_ID)..."

  ALL_CHANNELS="[]"
  PAGE=1
  while :; do
    if [[ -n "$VOD_MODE" ]]; then
      portal_request CHANNELS "Fetching VOD channels for ${GENRE_MAP[$GENRE_ID]} (page $PAGE)" "auth" \
        --data-urlencode "type=$TYPE_ARG" \
        --data-urlencode "action=get_ordered_list" \
        --data-urlencode "category=$GENRE_ID" \
        --data-urlencode "movie_id=0" \
        --data-urlencode "season_id=0" \
        --data-urlencode "episode_id=0" \
        --data-urlencode "force_ch_link_check=0" \
        --data-urlencode "from_ch_id=0" \
        --data-urlencode "fav=0" \
        --data-urlencode "sortby=added" \
        --data-urlencode "hd=0" \
        --data-urlencode "not_ended=0" \
        --data-urlencode "p=$PAGE" \
        --data-urlencode "JsHttpRequest=1-xml"
    else
      portal_request CHANNELS "Fetching LiveTV channels for ${GENRE_MAP[$GENRE_ID]} (page $PAGE)" "auth" \
        --data-urlencode "type=$TYPE_ARG" \
        --data-urlencode "action=get_ordered_list" \
        --data-urlencode "genre=$GENRE_ID" \
        --data-urlencode "fav=0" \
        --data-urlencode "sortby=number" \
        --data-urlencode "hd=1" \
        --data-urlencode "force_ch_link_check=0" \
        --data-urlencode "from_ch_id=0" \
        --data-urlencode "p=$PAGE" \
        --data-urlencode "JsHttpRequest=1-xml"
    fi
    COUNT=$(echo "$CHANNELS" | jq '.js.data | length')
    if [[ "$COUNT" -eq 0 ]]; then
      break
    fi

    ALL_CHANNELS=$(jq -s '.[0] + .[1]' <(echo "$ALL_CHANNELS") <(echo "$CHANNELS" | jq '.js.data'))
    ((PAGE++))
  done

  TOTAL_FOUND=$(echo "$ALL_CHANNELS" | jq 'length')
  if [[ $TOTAL_FOUND -eq 0 ]]; then
    log_step "    [!] No channels found in genre/category ID $GENRE_ID (${GENRE_MAP[$GENRE_ID]})"
    continue
  fi

  CHANNEL_INDEX=0
  mapfile -t CHANNEL_IDS < <(echo "$ALL_CHANNELS" | jq -r '.[].id' | awk '!seen[$0]++')

  log_step "    [+] Processing ${#CHANNEL_IDS[@]} channels..."

  for CHANNEL_ID in "${CHANNEL_IDS[@]}"; do
    CHANNEL=$(echo "$ALL_CHANNELS" | jq -r --arg ID "$CHANNEL_ID" '.[] | select(.id == $ID)')
    if ! echo "$CHANNEL" | jq -e type 2>/dev/null | grep -q 'object'; then
      continue
    fi

    process_channel "$GENRE_ID" "$CHANNEL_INDEX" "$CHANNEL"
    ((CHANNEL_INDEX++))
  done

  META_FILES=()
  while IFS= read -r -d $'\0' file; do
    META_FILES+=("$file")
  done < <(find "$META_DIR" -name "${GENRE_ID}_*.meta" -print0 | sort -z)

  log_step "    [+] Fetching links for ${#META_FILES[@]} channels..."

  for META_FILE in "${META_FILES[@]}"; do
    [[ -f "$META_FILE" ]] || continue

    CH_ID=""
    NAME=""
    LOGO=""
    XMLTV=""
    CH_NUMBER=""
    CMD=""
    SORT_INDEX=""
    { read -r CH_ID; read -r NAME; read -r LOGO; read -r XMLTV; read -r CH_NUMBER; read -r CMD; read -r SORT_INDEX; } < "$META_FILE"

    if [[ "$CMD" =~ ^ffmpeg[[:space:]]+http[s]?://[^/]+/play/live\.php.*stream=[0-9]+.*extension=ts ]]; then
      LINK="$CMD"
      log_step "    [+] Using direct CMD for $NAME (detected final URL format)" >&2
    else
      LINK_RESPONSE=""
      portal_request LINK_RESPONSE "create_link for $NAME" "auth" \
        --data-urlencode "type=$TYPE_ARG" \
        --data-urlencode "action=create_link" \
        --data-urlencode "cmd=$CMD" \
        --data-urlencode "JsHttpRequest=1-xml"
      LINK=$(echo "$LINK_RESPONSE" | jq -r '.js.cmd' 2>/dev/null)
      log_step "    [+] Used create_link API for $NAME (localhost/conversion needed)" >&2
    fi

    if [[ -n "$LINK" && "$LINK" != "null" ]]; then
      RESULT_FILE="$RESULTS_DIR/${GENRE_ID}_$(printf "%05d" "$SORT_INDEX")_${CH_ID}.m3u"
      {
        EXTINF_LINE="#EXTINF:-1"

        if [[ -n "$LOGO" && "$LOGO" != "null" ]]; then
          EXTINF_LINE="$EXTINF_LINE tvg-logo=\"$LOGO\""
        fi

        if [[ -n "$XMLTV" && "$XMLTV" != "null" ]]; then
          EXTINF_LINE="$EXTINF_LINE tvg-id=\"$XMLTV\""
        fi

        if [[ -n "$CH_NUMBER" && "$CH_NUMBER" != "null" ]]; then
          EXTINF_LINE="$EXTINF_LINE tvg-chno=\"$CH_NUMBER\""
        fi

        EXTINF_LINE="$EXTINF_LINE group-title=\"${GENRE_MAP[$GENRE_ID]}\",$NAME"

        echo "$EXTINF_LINE"
        echo "$LINK"
      } > "$RESULT_FILE"
    else
      FAIL_FILE="$FAILED_DIR/${GENRE_ID}_$(printf "%05d" "$SORT_INDEX")_${CH_ID}.fail"
      echo "$NAME" > "$FAIL_FILE"
      log_step "    [!] Failed to retrieve link for channel: $NAME" >&2
    fi
  done

done

RESULT_FILES=$(find "$RESULTS_DIR" -name "*.m3u" -type f | sort)
if [[ -n "$RESULT_FILES" ]]; then
  echo "$RESULT_FILES" | xargs cat >> "$SOURCE_M3U"
fi

TOTAL_CHANNELS=$(find "$META_DIR" -type f -name "*.meta" | wc -l)
SUCCESSFUL_CHANNELS=$(find "$RESULTS_DIR" -type f -name "*.m3u" | wc -l)
FAILED_CHANNELS=$(find "$FAILED_DIR" -type f -name "*.fail" | wc -l)

log_step "[+] Channel processing complete:"
log_step "    - Total channels processed: $TOTAL_CHANNELS"
log_step "    - Successfully retrieved: $SUCCESSFUL_CHANNELS"

if [[ $TOTAL_CHANNELS -eq 0 || $SUCCESSFUL_CHANNELS -eq 0 ]]; then
  log_step "[!] No channels were processed or retrieved. No playlist will be saved."
  dialog --backtitle "$DIALOG_BACKTITLE" --tailbox "$LOGFILE" 40 88
  rm -f "$LOGFILE"
  exit 0
fi

if [[ $FAILED_CHANNELS -gt 0 ]]; then
  PERCENT_SUCCESS=$(( (SUCCESSFUL_CHANNELS * 100) / TOTAL_CHANNELS ))
  log_step "    - Failed to retrieve: $FAILED_CHANNELS"
  log_step "    - Success rate: ${PERCENT_SUCCESS}%"

  log_step "    [!] Channels that failed by genre:"
  for GENRE_ID in "${!GENRE_MAP[@]}"; do
    GENRE_FAILS=$(find "$FAILED_DIR" -name "${GENRE_ID}_*.fail" | wc -l)
    if [[ $GENRE_FAILS -gt 0 ]]; then
      log_step "       ${GENRE_MAP[$GENRE_ID]}: $GENRE_FAILS channels failed"
      EXAMPLES=0
      while IFS= read -r fail_file && [[ $EXAMPLES -lt 5 ]]; do
        CHANNEL_NAME=$(cat "$fail_file")
        log_step "         - $CHANNEL_NAME"
        ((EXAMPLES++))
      done < <(find "$FAILED_DIR" -name "${GENRE_ID}_*.fail" -type f | sort | head -5)

      if [[ $GENRE_FAILS -gt 5 ]]; then
        log_step "         - ... and $(( GENRE_FAILS - 5 )) more"
      fi
    fi
  done
else
  log_step "    - All channels successfully retrieved! (100% success)"
fi

log_step "[+] Playlist saved as $SOURCE_M3U"

TMP_PROXY_OUTFILE=$(mktemp /tmp/proxy_${PORTAL_NAME}_XXXXXX.m3u)

echo "#EXTM3U" > "$TMP_PROXY_OUTFILE"
while IFS= read -r line; do
  if [[ "$line" =~ ^#EXTINF ]]; then
    echo "$line" >> "$TMP_PROXY_OUTFILE"
    read -r real_url
    if [[ -n "$VOD_MODE" ]]; then
      if [[ "$real_url" =~ stream=([^&]+) ]]; then
        VOD_STREAM="${BASH_REMATCH[1]}"
        echo "$PROXY_SERVER/$PORTAL_NAME/$VOD_STREAM" >> "$TMP_PROXY_OUTFILE"
      else
        echo "$real_url" >> "$TMP_PROXY_OUTFILE"
      fi
    else
      if [[ "$real_url" =~ stream=([0-9]+) ]]; then
        CH_ID="${BASH_REMATCH[1]}"
      else
        CH_ID=$(echo "$real_url" | grep -oE '/([0-9]+)(\?|$)' | grep -oE '[0-9]+' | tail -1)
      fi
      if [[ -n "$CH_ID" ]]; then
        echo "$PROXY_SERVER/$PORTAL_NAME/$CH_ID" >> "$TMP_PROXY_OUTFILE"
      else
        echo "$real_url" >> "$TMP_PROXY_OUTFILE"
      fi
    fi
  fi
done < "$SOURCE_M3U"

mv "$TMP_PROXY_OUTFILE" "$PROXY_M3U"
if [[ $EUID -eq 0 ]]; then
  chown "$USER":www-data "$PROXY_M3U" 2>/dev/null || true
fi
chmod 664 "$PROXY_M3U"

log_step "[+] Proxy playlist saved as $PROXY_M3U"
dialog --backtitle "$DIALOG_BACKTITLE" --tailbox "$LOGFILE" 40 88
rm -f "$LOGFILE"
