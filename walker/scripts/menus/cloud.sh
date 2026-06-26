#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
BACK_MENU="${BACK_MENU:-$MENUS_DIR/native-main.sh}"

options="  AWS
  GCP
󰠅  Azure"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Cloud")

case "$chosen" in
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
