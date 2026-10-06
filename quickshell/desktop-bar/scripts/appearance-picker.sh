#!/usr/bin/env bash
set -euo pipefail

mode="${1:-wallpaper}"
case "$mode" in
  wallpaper|theme) ;;
  *) exit 2 ;;
esac

quickshell ipc -c desktop-bar call -- appearance show "$mode"
