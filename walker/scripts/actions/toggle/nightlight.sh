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

restart_waybar_if_needed() {
  if grep -q "custom/nightlight" "$HOME/.config/waybar/config.jsonc" 2>/dev/null; then
    if command -v omarchy-restart-waybar >/dev/null 2>&1; then
      omarchy-restart-waybar
    else
      pkill waybar
      sleep 0.3
      waybar >/dev/null 2>&1 &
    fi
  fi
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

restart_waybar_if_needed
