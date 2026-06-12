#!/usr/bin/env bash

options="←  Back
  Shutdown
  Reboot
  Reboot BIOS
  Suspend
  Logout"

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
