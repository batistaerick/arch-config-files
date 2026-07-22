#!/usr/bin/env bash
set -euo pipefail

config="$HOME/.config/waybar/config.jsonc"
runtime_config="/tmp/waybar-config-${UID}.jsonc"
output="DP-3"

if [[ -r /sys/class/drm/card0-HDMI-A-1/status ]] && grep -qx connected /sys/class/drm/card0-HDMI-A-1/status; then
  output="HDMI-A-1"
elif compgen -G "/sys/class/drm/card*-HDMI-A-1/status" >/dev/null; then
  for status in /sys/class/drm/card*-HDMI-A-1/status; do
    if grep -qx connected "$status"; then
      output="HDMI-A-1"
      break
    fi
  done
fi

sed -E "s/^[[:space:]]*\"output\": \"[^\"]+\",/  \"output\": \"${output}\",/" "$config" >"$runtime_config"

exec waybar -c "$runtime_config" -s "$HOME/.config/waybar/style.css"
