#!/usr/bin/env bash

options="←  Back\n  Audio\n  WiFi\n  Bluetooth\n  Configs"

chosen="$(
  echo -e "$options" |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="Setup"
)"

case "$chosen" in
  "←  Back")
    ~/.config/wofi/scripts/menus/main.sh
    ;;
  "  Audio")
    pavucontrol
    ;;
  "  WiFi")
    kitty -e impala
    ;;
  "  Bluetooth")
    blueman-manager
    ;;
  "  Configs")
    code ~/.config &
    ;;
  "")
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
