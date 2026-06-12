#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"
HYPR_SCRIPTS_DIR="$HOME/.config/hypr/scripts"

options="←  Back
  Lock
  Shutdown
  Reboot
  Reboot BIOS
  Suspend
  Logout"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Power")

case $chosen in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "  Lock")
    "$HYPR_SCRIPTS_DIR/manual-lock.sh"
    ;;
  "  Shutdown")
    systemctl poweroff
    ;;
  "  Reboot")
    systemctl reboot
    ;;
  "  Reboot BIOS")
    kitty -e systemctl reboot --firmware-setup
    ;;
  "  Suspend")
    loginctl lock-session && sleep 1 && systemctl suspend
    ;;
  "  Logout")
    hyprctl dispatch exit
    ;;
esac
