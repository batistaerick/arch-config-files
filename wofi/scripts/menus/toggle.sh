#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"

options="←  Back\n󱄄  Screensaver\n󰔎  Nightlight\n󱫖  Idle Lock\n󰂛  Notifications\n󰍜  Top Bar\n  Reboot bios"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Toggle")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󱄄  Screensaver")
    kitty --class screensaver -e cmatrix -ab
    ;;
  "󰔎  Nightlight")
    "$ACTIONS_DIR/nightlight.sh"
    ;;
  "󱫖  Idle Lock")
    "$ACTIONS_DIR/idle-lock.sh"
    ;;
  "󰂛  Notifications")
    "$ACTIONS_DIR/notification-silencing.sh"
    ;;
  "󰍜  Top Bar")
    "$ACTIONS_DIR/toggle-waybar.sh"
    ;;
  "  Reboot bios")
    kitty -e systemctl reboot --firmware-setup
    ;;
esac
