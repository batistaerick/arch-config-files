#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"
HYPR_SCRIPTS_DIR="$HOME/.config/hypr/scripts"

options="←  Back
  Shutdown
  Reboot
  Lock
  Suspend
  Logout
  Reboot BIOS"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Power")

case $chosen in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "  Shutdown")
    systemctl poweroff
    ;;
  "  Reboot")
    systemctl reboot
    ;;
  "  Lock")
    "$HYPR_SCRIPTS_DIR/manual-lock.sh"
    ;;
  "  Suspend")
    loginctl lock-session && sleep 1 && systemctl suspend
    ;;
  "  Logout")
    hyprctl dispatch exit
    ;;
  "  Reboot BIOS")
    kitty -e systemctl reboot --firmware-setup
    ;;
esac
