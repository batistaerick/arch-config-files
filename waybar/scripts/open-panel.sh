#!/usr/bin/env bash

set -euo pipefail

class="${1:-}"
shift || true

if [[ -z "$class" || "$#" -eq 0 ]]; then
  echo "Usage: open-panel.sh <class> <command> [args...]" >&2
  exit 2
fi

target_monitor="${WAYBAR_PANEL_MONITOR:-HDMI-A-1}"

if ! hyprctl monitors -j | jq -e --arg monitor "$target_monitor" '.[] | select(.name == $monitor)' >/dev/null; then
  target_monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' | head -n1)"
fi

lua_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

focus_monitor() {
  [[ -n "$target_monitor" ]] || return 0
  hyprctl dispatch "hl.dsp.focus({ monitor = \"$(lua_escape "$target_monitor")\" })" >/dev/null || true
}

focus_existing() {
  local address
  address="$(hyprctl clients -j | jq -r --arg class "$class" '.[] | select(.class == $class) | .address' | head -n1)"
  [[ -n "$address" && "$address" != "null" ]] || return 1
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null || true
  return 0
}

focus_monitor

if focus_existing; then
  exit 0
fi

setsid -f "$@" >/dev/null 2>&1

for _ in {1..20}; do
  sleep 0.05
  focus_existing && exit 0
done
