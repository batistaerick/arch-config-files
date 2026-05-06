#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"

options="󰣇  Apps\n  AI Tools\n  Style\n󰔎  Toggle\n  Capture\n  Share\n  Update\n  Setup\n  About\n⏻  Power"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Find...")

case "$chosen" in
  "󰣇  Apps")
    "$MENUS_DIR/search.sh"
    ;;
  "  AI Tools")
    "$MENUS_DIR/ai-tools.sh"
    ;;
  "  Style")
    "$MENUS_DIR/style.sh"
    ;;
  "󰔎  Toggle")
    "$MENUS_DIR/toggle.sh"
    ;;
  "  Capture")
    "$MENUS_DIR/capture.sh"
    ;;
  "  Share")
    "$MENUS_DIR/share.sh"
    ;;
  "  Update")
    "$MENUS_DIR/update.sh"
    ;;
  "  Setup")
    "$MENUS_DIR/setup.sh"
    ;;
  "  About")
    "$ACTIONS_DIR/about.sh"
    ;;
  "⏻  Power")
    "$MENUS_DIR/power.sh"
    ;;
  "")
    exit 0
    ;;
  *)
    "$MENUS_DIR/search-all.sh" "$chosen"
    ;;
esac
