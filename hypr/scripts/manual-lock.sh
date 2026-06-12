#!/usr/bin/env bash
set -euo pipefail

DISPLAY_OFF_AFTER=900
SUSPEND_AFTER=1800

if pgrep -x hyprlock >/dev/null; then
  notify-send -u low "󱄄  Screensaver already running"
  exit 0
fi

hyprlock &
lock_pid=$!

(
  sleep "$DISPLAY_OFF_AFTER"
  if pgrep -x hyprlock >/dev/null; then
    hyprctl dispatch dpms off
  fi
) &
display_timer_pid=$!

(
  sleep "$SUSPEND_AFTER"
  if pgrep -x hyprlock >/dev/null; then
    systemctl suspend
  fi
) &
suspend_timer_pid=$!

cleanup() {
  kill "$display_timer_pid" "$suspend_timer_pid" 2>/dev/null || true
  hyprctl dispatch dpms on >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM
wait "$lock_pid"
