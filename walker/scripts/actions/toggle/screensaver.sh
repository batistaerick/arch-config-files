#!/usr/bin/env bash

if pgrep -x hyprlock >/dev/null; then
  notify-send -u low "󱄄  Screensaver already running"
  exit 0
fi

if command -v uwsm >/dev/null 2>&1; then
  uwsm app -- hyprlock >/dev/null 2>&1 &
else
  setsid hyprlock >/dev/null 2>&1 &
fi
