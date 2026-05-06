#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"

SWAYNC_DIR="$HOME/.config/swaync"
CURRENT_FILE="$SWAYNC_DIR/style.css"

mkdir -p "$SWAYNC_DIR"

if [[ -f "$CURRENT_DIR/light.mode" ]]; then
  ln -sf "$SWAYNC_DIR/catppuccin-latte.css" "$CURRENT_FILE"
else
  ln -sf "$SWAYNC_DIR/catppuccin-frappe.css" "$CURRENT_FILE"
fi

swaync-client -rs 2>/dev/null || true
