#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"
TOGGLE_ACTIONS_DIR="$ACTIONS_DIR/toggle"

options="←  Back
󱄄  Screensaver
󰔎  Nightlight
󱫖  Idle Lock
󰂛  Notifications
󰍜  Top Bar
  Reboot bios"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Toggle")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󱄄  Screensaver")
    notify-send "Toggle" "Screensaver action is not implemented yet"
    ;;
  "󰔎  Nightlight")
    "$TOGGLE_ACTIONS_DIR/nightlight.sh"
    ;;
  "󱫖  Idle Lock")
    "$TOGGLE_ACTIONS_DIR/idle-lock.sh"
    ;;
  "󰂛  Notifications")
    "$TOGGLE_ACTIONS_DIR/notification-silencing.sh"
    ;;
  "󰍜  Top Bar")
    "$TOGGLE_ACTIONS_DIR/waybar.sh"
    ;;
  "  Reboot bios")
    kitty -e systemctl reboot --firmware-setup
    ;;
esac
