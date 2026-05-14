#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
OBS_WEBSOCKET="obsws://localhost:4455/lWa6WIjfEf5CSKtv"

obs_running() {
  pgrep -x obs >/dev/null
}

focus_obs() {
  hyprctl dispatch focuswindow "class:^(com.obsproject.Studio)$" >/dev/null 2>&1
}

open_obs() {
  if obs_running; then
    focus_obs
  else
    obs >/dev/null 2>&1 &
  fi
}

wait_for_obs() {
  for _ in {1..30}; do
    obs-cmd --websocket "$OBS_WEBSOCKET" recording status >/dev/null 2>&1 && return 0
    sleep 0.2
  done

  notify-send "OBS" "OBS WebSocket is not responding." -u critical
  exit 1
}

start_recording_scene() {
  local scene="$1"

  if ! obs_running; then
    obs >/dev/null 2>&1 &
  fi

  wait_for_obs

  obs-cmd --websocket "$OBS_WEBSOCKET" scene switch "$scene"
  sleep 0.3
  obs-cmd --websocket "$OBS_WEBSOCKET" recording start

  notify-send "OBS Recording" "Started: $scene"
}

stop_recording() {
  if ! obs_running; then
    notify-send "OBS" "OBS is not running."
    exit 0
  fi

  wait_for_obs

  obs-cmd --websocket "$OBS_WEBSOCKET" recording stop
  notify-send "OBS Recording" "Stopped"

  sleep 0.5
  open_obs
}

options="←  Back
  Open OBS
󰑊  Record
󰕾  Record + audio
󰖠  Record + webcam
󰍬  Record + audio + webcam
  Stop recording"

chosen="$(echo "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Screenrecord")"

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/capture.sh"
    ;;
  "  Open OBS")
    open_obs
    ;;
  "󰑊  Record")
    start_recording_scene "Screen"
    ;;
  "󰕾  Record + audio")
    start_recording_scene "Screen + Audio"
    ;;
  "󰖠  Record + webcam")
    start_recording_scene "Screen + Webcam"
    ;;
  "󰍬  Record + audio + webcam")
    start_recording_scene "Screen + Audio + Webcam"
    ;;
  "  Stop recording")
    stop_recording
    ;;
esac
