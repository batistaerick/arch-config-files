#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
CAPTURE_MENUS_DIR="$MENUS_DIR/capture"

options="←  Back
󰄀  Screenshot
  Screenrecord
󰴑  OCR text
󰐲  QR code
󰑕  Transcode
󰈊  Color"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Capture")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󰄀  Screenshot")
    "$CAPTURE_MENUS_DIR/screenshot.sh"
    ;;
  "  Screenrecord")
    "$CAPTURE_MENUS_DIR/screenrecord.sh"
    ;;
  "󰴑  OCR text")
    "$HOME/.config/walker/scripts/actions/capture/text.sh"
    ;;
  "󰐲  QR code")
    "$HOME/.config/walker/scripts/actions/capture/qr.sh"
    ;;
  "󰑕  Transcode")
    "$HOME/.config/walker/scripts/actions/capture/transcode.sh"
    ;;
  "󰈊  Color")
    (sleep 0.2 && hyprpicker -a) &
    ;;
esac
