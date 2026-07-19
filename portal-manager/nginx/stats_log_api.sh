#!/bin/bash
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

set -euo pipefail

LOG_FILE=${LOG_FILE:-/var/www/stalker/iptv_proxy.log}
DEFAULT_LINES=${DEFAULT_LINES:-200}
MAX_LINES=${MAX_LINES:-500}

send_headers() {
  printf '%s\r\n' "Content-Type: application/json" "Cache-Control: no-store"
  printf '\r\n'
}

emit_error() {
  send_headers
  jq -n --arg message "$1" '{error: $message}'
  exit 0
}

url_decode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}" 2>/dev/null || true
}

LINES_REQUEST=$DEFAULT_LINES
if [[ -n "${QUERY_STRING:-}" ]]; then
  IFS='&' read -ra params <<< "$QUERY_STRING"
  for chunk in "${params[@]}"; do
    key="${chunk%%=*}"
    value="${chunk#*=}"
    key=$(url_decode "$key")
    value=$(url_decode "$value")
    if [[ "$key" == "lines" ]]; then
      if [[ "$value" =~ ^[0-9]+$ ]]; then
        LINES_REQUEST=$value
      fi
      break
    fi
  done
fi

if (( LINES_REQUEST < 1 )); then
  LINES_REQUEST=$DEFAULT_LINES
elif (( LINES_REQUEST > MAX_LINES )); then
  LINES_REQUEST=$MAX_LINES
fi

if [[ ! -f "$LOG_FILE" ]]; then
  emit_error "Log file not found"
fi

LOG_CONTENT=$(tail -n "$LINES_REQUEST" "$LOG_FILE" 2>/dev/null || true)
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

send_headers
printf '%s' "$LOG_CONTENT" | jq -R -s --arg logfile "$LOG_FILE" --argjson lines "$LINES_REQUEST" --arg generated "$TIMESTAMP" '
  {
    log_file: $logfile,
    requested_lines: $lines,
    generated_at: $generated,
    lines: (split("\n") | map(select(length>0)))
  }
'
