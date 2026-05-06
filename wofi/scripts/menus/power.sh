#!/usr/bin/env bash

options="←  Back\n  Shutdown\n  Reboot\n  Suspend\n  Logout"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Power")

case $chosen in
  "←  Back")
    ~/.config/wofi/scripts/menus/main.sh
    ;;
  "  Shutdown")
    systemctl poweroff
    ;;
  "  Reboot")
    systemctl reboot
    ;;
  "  Suspend")
    systemctl suspend
    ;;
  "  Logout")
    hyprctl dispatch exit
    ;;
esac
