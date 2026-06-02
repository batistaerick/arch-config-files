#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
BACK_MENU="${BACK_MENU:-$MENUS_DIR/main.sh}"

options="←  Back
  AWS
  GCP
󰠅  Azure"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Cloud")

case "$chosen" in
  "←  Back")
    "$BACK_MENU"
    ;;
  "  AWS")
    "$MENUS_DIR/cloud/aws/menu.sh"
    ;;
  "  GCP")
    "$MENUS_DIR/cloud/gcp/menu.sh"
    ;;
  "󰠅  Azure")
    "$MENUS_DIR/cloud/azure/menu.sh"
    ;;
  "")
    exit 0
    ;;
esac
