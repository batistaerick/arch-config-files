#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
  pkill -x hypridle
  notify-send -u low "󱫖  Stop locking computer when idle"
else
  if command -v uwsm >/dev/null 2>&1; then
    uwsm app -- hypridle >/dev/null 2>&1 &
  else
    setsid hypridle >/dev/null 2>&1 &
  fi

  notify-send -u low "󱫖  Now locking computer when idle"
fi

pkill -RTMIN+9 waybar 2>/dev/null || true
