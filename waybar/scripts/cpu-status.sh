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
temperature="$(
  sensors 2>/dev/null |
    awk '
      /^Package id 0:/ {
        gsub(/^\+/, "", $4)
        gsub(/°C.*/, "°C", $4)
        print $4
        found = 1
        exit
      }
      /^PECI 0.0:/ && temp == "" {
        gsub(/^\+/, "", $3)
        gsub(/°C.*/, "°C", $3)
        temp = $3
      }
      END {
        if (!found && temp != "") print temp
      }
    '
)"

if [[ -n "$temperature" ]]; then
  text=" <span size='small'>${usage}%</span>"
  tooltip="CPU: ${usage}%
Temperature: ${temperature}
Load: ${load}"
else
  text=" <span size='small'>${usage}%</span>"
  tooltip="CPU: ${usage}%
Load: ${load}"
fi

jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
