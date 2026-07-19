#!/bin/bash
#######################################################################################
# IPTV Stalker Portal Manager © tem_invictus 2025
# More info: https://www.digital-eliteboard.com/threads/stalker-portal-manager.538885/
#######################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORTAL_REGISTRY_DEFAULT="/var/www/stalker/portals.list"
LEGACY_PORTAL_REGISTRY="$SCRIPT_DIR/portals.list"
PORTAL_REGISTRY=${PORTAL_REGISTRY:-$PORTAL_REGISTRY_DEFAULT}
if [[ ! -f "$PORTAL_REGISTRY" && -f "$LEGACY_PORTAL_REGISTRY" ]]; then
  PORTAL_REGISTRY="$LEGACY_PORTAL_REGISTRY"
fi
PORTAL_DATA_BASE=${PORTAL_DATA_BASE:-/var/www/stalker}
CACHE_DIR=${CACHE_DIR:-$SCRIPT_DIR/html}
CACHE_TTL=${CACHE_TTL:-60}
CACHE_FILE="$CACHE_DIR/stats.json"

url_decode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}" 2>/dev/null || true
}

is_valid_portal_name() {
  [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]]
}

PORTAL_QUERY=""
if [[ -n "${QUERY_STRING:-}" ]]; then
  IFS='&' read -ra QUERY_PARTS <<< "$QUERY_STRING"
  for part in "${QUERY_PARTS[@]}"; do
    key="${part%%=*}"
    value="${part#*=}"
    key=$(url_decode "$key")
    value=$(url_decode "$value")
    if [[ "$key" == "portal" ]]; then
      PORTAL_QUERY="$value"
      break
    fi
  done
fi

send_headers() {
  printf '%s\r\n' "Content-Type: application/json" "Cache-Control: no-store" "Pragma: no-cache"
  printf '\r\n'
}

serve_cache_if_fresh() {
  if [[ -f "$CACHE_FILE" ]]; then
    local now ts age
    now=$(date +%s)
    ts=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    age=$((now - ts))
    if (( age >= 0 && age < CACHE_TTL )); then
      send_headers
      cat "$CACHE_FILE"
      exit 0
    fi
  fi
}

emit_error() {
  send_headers
  jq -n --arg message "$1" '{error: $message}'
  exit 0
}

emit_portal_usage_report() {
  local portal_name="$1"
  if [[ -z "$portal_name" ]]; then
    emit_error "Portal parameter required"
  fi
  if ! is_valid_portal_name "$portal_name"; then
    emit_error "Invalid portal name"
  fi

  local portal_dir="$PORTAL_DATA_BASE/$portal_name"
  local stats_file="$portal_dir/mac_stats.txt"
  if [[ ! -d "$portal_dir" ]]; then
    emit_error "Portal not found"
  fi

  if [[ ! -f "$stats_file" ]]; then
    send_headers
    jq -n --arg portal "$portal_name" '{portal: $portal, totals: {macs: 0, attempts: 0, successes: 0, avg_success_rate: 0}, mac_usage: []}'
    exit 0
  fi

  local portal_payload
  portal_payload=$(awk -F'|' '
    function is_mac(str) { return (str ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/) }
    function to_int(val) { return (val ~ /^[0-9]+$/) ? val : 0 }
    {
      mac=$1
      gsub(/^[ \t]+|[ \t]+$/, "", mac)
      if (!is_mac(mac)) { next }
      success=to_int($2)
      attempts=to_int($3)
      rate=(attempts>0)?(success/attempts):0
      printf "%s|%d|%d|%.8f\n", mac, success, attempts, rate
    }
  ' "$stats_file" | jq -Rn --arg portal "$portal_name" '
    [inputs | select(length>0) | (split("|") | {
      mac: .[0],
      success: ((.[1] | tonumber?) // 0),
      attempts: ((.[2] | tonumber?) // 0),
      success_rate: ((.[3] | tonumber?) // 0)
    })] as $rows
    | ($rows | sort_by([.success_rate, .attempts]) | reverse) as $ordered
    | ($ordered | reduce .[] as $item ({attempts: 0, successes: 0}; {
        attempts: (.attempts + ($item.attempts // 0)),
        successes: (.successes + ($item.success // 0))
      })) as $agg
    | {
        portal: $portal,
        totals: {
          macs: ($ordered | length),
          attempts: $agg.attempts,
          successes: $agg.successes,
          avg_success_rate: (if $agg.attempts > 0 then ($agg.successes / $agg.attempts) else 0 end)
        },
        mac_usage: ($ordered | map(. + { success_rate_percent: (if .attempts > 0 then (.success_rate * 100) else 0 end) }))
      }
  ')

  send_headers
  printf '%s\n' "$portal_payload"
  exit 0
}

if [[ ! -f "$PORTAL_REGISTRY" ]]; then
  emit_error "Portal registry not found"
fi

mkdir -p "$CACHE_DIR"
if [[ -n "$PORTAL_QUERY" ]]; then
  emit_portal_usage_report "$PORTAL_QUERY"
fi
serve_cache_if_fresh

total_portals=0
total_macs=0
active_macs=0
declare -a PORTAL_ROWS=()
total_inactive=0
total_unknown=0
total_no_expiration=0
total_expired=0
today=$(date +%Y-%m-%d)

while IFS='|' read -r portal_name portal_url mac portal_delay portal_request_delay || [[ -n "$portal_name$portal_url$mac$portal_delay$portal_request_delay" ]]; do
  [[ -z "$portal_name" ]] && continue
  total_portals=$((total_portals + 1))
  local_request_delay=${portal_request_delay:-0.3}
  local_check_delay=${portal_delay:-30}
  macs_info_file="$PORTAL_DATA_BASE/$portal_name/macs_info.txt"
  portal_macs=0
  portal_active=0
  portal_inactive=0
  portal_unknown=0
  portal_no_expiration=0
  portal_expired=0
  if [[ -f "$macs_info_file" ]]; then
    portal_stats=$(awk -F'|' -v today="$today" '
      function is_mac(str) { return (str ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/) }
      BEGIN { total=active=inactive=unknown=noexp=expired=0 }
      {
        mac=$1
        gsub(/^[ \\t]+|[ \\t]+$/, "", mac)
        if (!is_mac(mac)) { next }
        total++
        status=$3
        gsub(/^[ \\t]+|[ \\t]+$/, "", status)
        status=tolower(status)
        if (status=="yes") { active++ }
        else if (status=="no") { inactive++ }
        else { unknown++ }
          expiry=$2
          gsub(/^[ \t]+|[ \t]+$/, "", expiry)
          if (expiry=="" || tolower(expiry)=="no limit") { noexp++ }
          else if (expiry < today) { expired++ }
      }
      END { printf "%d|%d|%d|%d|%d|%d", total, active, inactive, unknown, noexp, expired }
    ' "$macs_info_file")
    IFS='|' read -r portal_macs portal_active portal_inactive portal_unknown portal_no_expiration portal_expired <<< "$portal_stats"
    portal_macs=${portal_macs:-0}
    portal_active=${portal_active:-0}
    portal_inactive=${portal_inactive:-0}
    portal_unknown=${portal_unknown:-0}
    portal_no_expiration=${portal_no_expiration:-0}
    portal_expired=${portal_expired:-0}
  fi
  total_macs=$((total_macs + portal_macs))
  active_macs=$((active_macs + portal_active))
  total_inactive=$((total_inactive + portal_inactive))
  total_unknown=$((total_unknown + portal_unknown))
  total_no_expiration=$((total_no_expiration + portal_no_expiration))
  total_expired=$((total_expired + portal_expired))
  PORTAL_ROWS+=("$portal_name|$portal_url|$portal_macs|$portal_active|$portal_inactive|$portal_unknown|$portal_no_expiration|$portal_expired|$local_request_delay|$local_check_delay")
done < "$PORTAL_REGISTRY"

portal_json='[]'
if (( ${#PORTAL_ROWS[@]} > 0 )); then
  portal_json=$(printf '%s
' "${PORTAL_ROWS[@]}" | jq -Rn '
    [inputs | select(length>0) | (split("|") | {
      name: .[0],
      url: .[1],
      macs: ((.[2] | tonumber?) // 0),
      active: ((.[3] | tonumber?) // 0),
      inactive: ((.[4] | tonumber?) // 0),
      unknown: ((.[5] | tonumber?) // 0),
      no_expiration: ((.[6] | tonumber?) // 0),
      expired: ((.[7] | tonumber?) // 0),
      request_delay: ((.[8] | tonumber?) // 0.3),
      check_delay: ((.[9] | tonumber?) // 30)
    })]
  ')
fi

timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
final_json=$(jq -n \
  --arg generated_at "$timestamp" \
  --argjson totalPortals "$total_portals" \
  --argjson totalMacs "$total_macs" \
  --argjson activeMacs "$active_macs" \
  --argjson inactiveMacs "$total_inactive" \
  --argjson unknownMacs "$total_unknown" \
  --argjson noExpirationMacs "$total_no_expiration" \
  --argjson expiredMacs "$total_expired" \
  --argjson portals "$portal_json" \
  '{generated_at: $generated_at, totals: {portals: $totalPortals, macs: $totalMacs, active_macs: $activeMacs, inactive_macs: $inactiveMacs, unknown_macs: $unknownMacs, no_expiration_macs: $noExpirationMacs, expired_macs: $expiredMacs}, portals: $portals}')

tmp_file=$(mktemp)
printf '%s\n' "$final_json" > "$tmp_file"
chmod 644 "$tmp_file"
command mv -f "$tmp_file" "$CACHE_FILE"

send_headers
cat "$CACHE_FILE"
