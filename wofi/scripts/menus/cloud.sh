#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"

options="←  Back
  AWS
  GCP
󰠅  Azure"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Cloud")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "  AWS")
    "$MENUS_DIR/cloud/aws/menu.sh"
    ;;
  "  GCP")
    notify-send "Cloud" "GCP menu not implemented yet"
    ;;
  "󰠅  Azure")
    notify-send "Cloud" "Azure menu not implemented yet"
    ;;
  "")
    exit 0
    ;;
esac
