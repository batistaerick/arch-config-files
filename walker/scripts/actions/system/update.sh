#!/usr/bin/env bash
set -euo pipefail
# Fresh distro installations enforce snapshots through pacman's pre-upgrade hook.
# Existing desktops without those hooks retain their normal update workflow.
case "${1:-}" in
  pacman) sudo pacman -Syu ;;
  yay) yay -Syu ;;
  full) sudo pacman -Syu; yay -Sua --devel ;;
  *) echo 'Usage: update.sh pacman|yay|full' >&2; exit 2 ;;
esac
