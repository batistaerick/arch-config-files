#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"

options="󰕮  Workspace Overview
  Audio
  WiFi
  Bluetooth
󰌌  Keyboard
󰍬  Microphone
󰃭  Calendar
󰖐  Weather
󰍛  Hardware
󱜙  AI Usage
  Dotfiles
  Update
󰃢  Cleanup
  About"

chosen="$(
  echo -e "$options" |
    $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="System"
)"

case "$chosen" in
  "󰕮  Workspace Overview")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" overview
    ;;
  "  Audio")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" volume
    ;;
  "  WiFi")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" wifi
    ;;
  "  Bluetooth")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" bluetooth
    ;;
  "󰌌  Keyboard")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" keyboard
    ;;
  "󰍬  Microphone")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" mic
    ;;
  "󰃭  Calendar")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" calendar
    ;;
  "󰖐  Weather")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" weather
    ;;
  "󰍛  Hardware")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" hardware
    ;;
  "󱜙  AI Usage")
    bash "$HOME/.config/quickshell/desktop-bar/scripts/show-panel.sh" ai
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
