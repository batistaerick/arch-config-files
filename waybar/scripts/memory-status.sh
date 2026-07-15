#!/usr/bin/env bash

set -euo pipefail

active_class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""' 2>/dev/null || true)"
mem_total_kb="$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)"
mem_available_kb="$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo)"
mem_used_kb=$((mem_total_kb - mem_available_kb))
percentage=$(((100 * mem_used_kb) / mem_total_kb))

used_gib="$(awk -v kb="$mem_used_kb" 'BEGIN { printf "%.1f", kb / 1024 / 1024 }')"
total_gib="$(awk -v kb="$mem_total_kb" 'BEGIN { printf "%.1f", kb / 1024 / 1024 }')"
available_gib="$(awk -v kb="$mem_available_kb" 'BEGIN { printf "%.1f", kb / 1024 / 1024 }')"

class="inactive"
if [[ "$active_class" == "system-monitor" ]]; then
  class="active"
fi

text=" <span size='small'>${percentage}%</span>"
tooltip="RAM: ${used_gib}G / ${total_gib}G (${percentage}%)\nAvailable: ${available_gib}G"

jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
