#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"

SWAYNC_DIR="$HOME/.config/swaync"
CURRENT_FILE="$SWAYNC_DIR/style.css"
GENERATOR="$SWAYNC_DIR/generate-theme.py"

mkdir -p "$SWAYNC_DIR"

if [[ -f "$CURRENT_DIR/colors.toml" && -f "$GENERATOR" ]]; then
  python3 "$GENERATOR" "$CURRENT_DIR/colors.toml" "$CURRENT_FILE"
elif [[ -f "$CURRENT_DIR/light.mode" ]]; then
  ln -sf "$SWAYNC_DIR/catppuccin-latte.css" "$CURRENT_FILE"
else
  ln -sf "$SWAYNC_DIR/catppuccin-frappe.css" "$CURRENT_FILE"
fi

timeout 2s swaync-client -rs 2>/dev/null || true
