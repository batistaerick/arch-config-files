#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"

options="  Audio
  WiFi
  Bluetooth
󰌌  Keyboard
  Dotfiles
  Update
󰃢  Cleanup
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
  "󰌌  Keyboard")
    walker --provider menus:keyboard
    ;;
  "  Dotfiles")
    code "$HOME/.config" &
    ;;
  "  Update")
    "$MENUS_DIR/update.sh"
    ;;
  "󰃢  Cleanup")
    kitty --class system-cleanup -e "$ACTIONS_DIR/system/cleanup.sh"
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
