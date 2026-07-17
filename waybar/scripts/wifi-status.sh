#!/usr/bin/env bash

set -euo pipefail

active_class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""' 2>/dev/null || true)"
public_ip_cache="/tmp/waybar-public-ip-${UID}"
public_ip_ttl_seconds=300
class="disconnected"
icon=""
tooltip="Wi-Fi: disconnected"

public_ip() {
  local now cache_mtime cached

  now="$(date +%s)"
  if [[ -f "$public_ip_cache" ]]; then
    cache_mtime="$(stat -c %Y "$public_ip_cache" 2>/dev/null || echo 0)"
    if ((now - cache_mtime < public_ip_ttl_seconds)); then
      cached="$(<"$public_ip_cache")"
      if [[ -n "$cached" ]]; then
        printf '%s\n' "$cached"
        return
      fi
    fi
  fi

  cached="$(curl --max-time 1 --silent --show-error --fail https://api.ipify.org 2>/dev/null || true)"
  if [[ -n "$cached" ]]; then
    printf '%s\n' "$cached" > "$public_ip_cache"
    printf '%s\n' "$cached"
  elif [[ -f "$public_ip_cache" ]]; then
    cat "$public_ip_cache"
  fi
}

if rfkill -J 2>/dev/null | jq -e '.rfkilldevices[]? | select(.type == "wlan" and (.soft == "blocked" or .hard == "blocked"))' >/dev/null; then
  class="off"
  icon="󰤮"
  tooltip="Wi-Fi: off"
else
  station="$(
    timeout 1 iwctl station list 2>/dev/null |
      sed -r 's/\x1B\[[0-9;]*[mK]//g' |
      awk '$2 == "connected" { print $1; exit }'
  )"

  if [[ -n "$station" ]]; then
    station_details="$(
      timeout 1 iwctl station "$station" show 2>/dev/null |
        sed -r 's/\x1B\[[0-9;]*[mK]//g'
    )"
    ssid="$(awk '$1 == "Connected" && $2 == "network" { $1=""; $2=""; sub(/^[[:space:]]+/, ""); print; exit }' <<<"$station_details")"
    rssi="$(awk '$1 == "RSSI" { print $2; exit }' <<<"$station_details")"
    local_ip="$(ip -4 -o addr show dev "$station" scope global 2>/dev/null | awk '{ split($4, parts, "/"); print parts[1]; exit }')"
    wan_ip="$(public_ip)"

    if [[ "$rssi" =~ ^-?[0-9]+$ ]]; then
      if ((rssi >= -50)); then
        icon="󰤨"
      elif ((rssi >= -60)); then
        icon="󰤥"
      elif ((rssi >= -70)); then
        icon="󰤢"
      elif ((rssi >= -80)); then
        icon="󰤟"
      else
        icon="󰤯"
      fi
      tooltip="Wi-Fi: ${ssid:-connected}
Signal: ${rssi} dBm
Interface: $station
Local IP: ${local_ip:-unavailable}
Public IP: ${wan_ip:-unavailable}"
    else
      icon="󰤨"
      tooltip="Wi-Fi: ${ssid:-connected}
Interface: $station
Local IP: ${local_ip:-unavailable}
Public IP: ${wan_ip:-unavailable}"
    fi
    class="connected"
  fi
fi

if [[ "$active_class" == "setup-wifi" ]]; then
  class="$class active"
fi

jq -cn --arg text "$icon" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
