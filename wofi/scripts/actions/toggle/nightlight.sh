#!/usr/bin/env bash

ON_TEMP=4000
STATE_FILE="$HOME/.cache/nightlight-enabled"

start_hyprsunset() {
  if pgrep -x hyprsunset >/dev/null; then
    return
  fi

  if command -v uwsm >/dev/null 2>&1; then
    uwsm app -- hyprsunset >/dev/null 2>&1 &
  else
    setsid hyprsunset >/dev/null 2>&1 &
  fi

  sleep 1
}

start_hyprsunset

if [[ -f "$STATE_FILE" ]]; then
  hyprctl hyprsunset identity
  rm -f "$STATE_FILE"
  notify-send -u low "  Daylight screen temperature"
else
  hyprctl hyprsunset temperature "$ON_TEMP"
  touch "$STATE_FILE"
  notify-send -u low "  Nightlight screen temperature"
fi
