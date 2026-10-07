#!/usr/bin/env bash
set -euo pipefail

mode="${1:-wallpaper}"
case "$mode" in
  wallpaper|theme|theme-dark|theme-light) ;;
  *) exit 2 ;;
esac

quickshell ipc -c desktop-bar call -- appearance show "$mode"
