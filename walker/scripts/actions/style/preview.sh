#!/usr/bin/env bash
set -euo pipefail

sleep 0.2
category="theme"
if [[ -n "${1:-}" ]]; then
  if [[ -f "$HOME/.config/themes/$1/light.mode" ]]; then
    category="theme-light"
  else
    category="theme-dark"
  fi
fi
exec bash "$HOME/.config/quickshell/desktop-bar/scripts/appearance-picker.sh" "$category"
