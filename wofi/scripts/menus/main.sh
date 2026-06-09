#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"

options="󰣇  Apps
󰅩  Development
  Style
󰔎  Toggle
  Capture
  Share
󰌌  Shortcuts
  System
⏻  Power"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Find...")

case "$chosen" in
  "󰣇  Apps")
    "$MENUS_DIR/search.sh"
    ;;
  "󰅩  Development")
    "$MENUS_DIR/development.sh"
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
  "󰌌  Shortcuts")
    "$MENUS_DIR/shortcuts.sh"
    ;;
  "  System")
    "$MENUS_DIR/system.sh"
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
