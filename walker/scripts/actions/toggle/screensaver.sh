#!/usr/bin/env bash

if pgrep -x hyprlock >/dev/null; then
  notify-send -u low "󱄄  Screensaver already running"
  exit 0
fi

if command -v uwsm >/dev/null 2>&1; then
  uwsm app -- bash "$HOME/.config/quickshell/lockscreen/scripts/launch.sh" lock >/dev/null 2>&1 &
else
  setsid bash "$HOME/.config/quickshell/lockscreen/scripts/launch.sh" lock >/dev/null 2>&1 &
fi
