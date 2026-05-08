#!/usr/bin/env bash

set -e

CURRENT_DIR="$HOME/.config/theme/current"
SDDM_THEME_FILE="$CURRENT_DIR/sddm.theme"

if [[ ! -f "$SDDM_THEME_FILE" ]]; then
  notify-send "SDDM Theme" "No sddm.theme found in current theme"
  exit 0
fi

SDDM_THEME="$(tr -d '\r' < "$SDDM_THEME_FILE" | xargs)"

if [[ -z "$SDDM_THEME" ]]; then
  notify-send "SDDM Theme" "sddm.theme is empty"
  exit 1
fi

sudo -n /usr/local/bin/set-sddm-theme "$SDDM_THEME"
