#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"

WOFI_THEMES_DIR="$HOME/.config/wofi/themes"
CURRENT_FILE="$WOFI_THEMES_DIR/current.css"

mkdir -p "$WOFI_THEMES_DIR"

if [[ -f "$CURRENT_DIR/light.mode" ]]; then
  ln -sf "$WOFI_THEMES_DIR/light.css" "$CURRENT_FILE"
else
  ln -sf "$WOFI_THEMES_DIR/dark.css" "$CURRENT_FILE"
fi
