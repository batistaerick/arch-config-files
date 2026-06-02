#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"

options="←  Back
  Audio
  WiFi
  Bluetooth
  Dotfiles
  Update
  About"

chosen="$(
  echo -e "$options" |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="System"
)"

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
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
  "  Dotfiles")
    code "$HOME/.config" &
    ;;
  "  Update")
    "$MENUS_DIR/update.sh"
    ;;
  "  About")
    "$ACTIONS_DIR/about.sh"
    ;;
  "")
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
