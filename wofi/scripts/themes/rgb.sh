#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"
RGB_FILE="$CURRENT_DIR/rgb.color"

[[ -f "$RGB_FILE" ]] || exit 0

RGB_COLOR="$(cat "$RGB_FILE" | tr -d '#[:space:]')"

if [[ ! "$RGB_COLOR" =~ ^[0-9A-Fa-f]{6}$ ]]; then
  notify-send "RGB Theme" "Invalid RGB color: $RGB_COLOR"
  exit 1
fi

if ! command -v openrgb >/dev/null 2>&1; then
  notify-send "RGB Theme" "OpenRGB is not installed"
  exit 1
fi

openrgb --mode Static --color "$RGB_COLOR" >/dev/null 2>&1 || true

for zone in 0 1 2 3 4; do
  openrgb --device 0 --zone "$zone" --mode Static --color "$RGB_COLOR" >/dev/null 2>&1 || true
done

for device in 0 1 2 3 4 5; do
  openrgb --device "$device" --mode Static --color "$RGB_COLOR" >/dev/null 2>&1 || true
done
