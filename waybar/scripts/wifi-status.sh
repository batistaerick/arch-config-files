#!/usr/bin/env bash

set -euo pipefail

active_class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""' 2>/dev/null || true)"
class="disconnected"
icon=""
tooltip="Wi-Fi: disconnected"

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

    if [[ "$rssi" =~ ^-?[0-9]+$ ]]; then
      if (( rssi >= -50 )); then
        icon="󰤨"
      elif (( rssi >= -60 )); then
        icon="󰤥"
      elif (( rssi >= -70 )); then
        icon="󰤢"
      elif (( rssi >= -80 )); then
        icon="󰤟"
      else
        icon="󰤯"
      fi
      tooltip="Wi-Fi: ${ssid:-connected}\nSignal: ${rssi} dBm\nInterface: $station"
    else
      icon="󰤨"
      tooltip="Wi-Fi: ${ssid:-connected}\nInterface: $station"
    fi
    class="connected"
  fi
fi

if [[ "$active_class" == "setup-wifi" ]]; then
  class="$class active"
fi

jq -cn --arg text "$icon" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
