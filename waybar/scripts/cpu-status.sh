#!/usr/bin/env bash

set -euo pipefail

cache_file="/tmp/waybar-cpu-stat-${UID}"
active_class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""' 2>/dev/null || true)"
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

idle_all=$((idle + iowait))
non_idle=$((user + nice + system + irq + softirq + steal))
total=$((idle_all + non_idle))
usage=0

if [[ -f "$cache_file" ]]; then
  read -r prev_total prev_idle < "$cache_file" || true
  total_delta=$((total - prev_total))
  idle_delta=$((idle_all - prev_idle))
  if (( total_delta > 0 )); then
    usage=$(((100 * (total_delta - idle_delta)) / total_delta))
  fi
fi

printf '%s %s\n' "$total" "$idle_all" > "$cache_file"

class="inactive"
if [[ "$active_class" == "system-monitor" ]]; then
  class="active"
fi

load="$(cut -d' ' -f1-3 /proc/loadavg)"
text=" <span size='small'>${usage}%</span>"
tooltip="CPU: ${usage}%
Load: ${load}"

jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
