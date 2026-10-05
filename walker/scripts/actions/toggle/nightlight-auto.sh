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

apply_nightlight_state() {
  local hour

  hour="$(date +%H)"
  start_hyprsunset

  if ((10#$hour >= 18 || 10#$hour < 9)); then
    hyprctl hyprsunset temperature "$ON_TEMP" >/dev/null 2>&1
    touch "$STATE_FILE"
  else
    hyprctl hyprsunset identity >/dev/null 2>&1
    rm -f "$STATE_FILE"
  fi
}

apply_nightlight_state
