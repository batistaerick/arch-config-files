#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"

options="←  Back
  AI Tools
  Cloud"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Development")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "  AI Tools")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/ai-tools.sh"
    ;;
  "  Cloud")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/cloud.sh"
    ;;
  "")
    exit 0
    ;;
esac
