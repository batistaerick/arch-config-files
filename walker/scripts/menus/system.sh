#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"

options="  Audio
  WiFi
  Bluetooth
  Dotfiles
  Update
  About"

chosen="$(
  echo -e "$options" |
    $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="System"
)"

case "$chosen" in
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
