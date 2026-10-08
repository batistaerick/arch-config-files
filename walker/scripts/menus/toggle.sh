#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"
TOGGLE_ACTIONS_DIR="$ACTIONS_DIR/toggle"

options="󱄄  Screensaver
󰔎  Nightlight
󱫖  Idle Lock
󰂛  Notifications
󰍜  Desktop Bar"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Toggle")

case "$chosen" in
  "󱄄  Screensaver")
    "$TOGGLE_ACTIONS_DIR/screensaver.sh"
    ;;
  "󰔎  Nightlight")
    "$TOGGLE_ACTIONS_DIR/nightlight.sh"
    ;;
  "󱫖  Idle Lock")
    "$TOGGLE_ACTIONS_DIR/idle-lock.sh"
    ;;
  "󰂛  Notifications")
    "$TOGGLE_ACTIONS_DIR/notification-silencing.sh"
    ;;
  "󰍜  Desktop Bar")
    "$TOGGLE_ACTIONS_DIR/desktop-bar.sh"
    ;;
esac
