#!/usr/bin/env bash
set -euo pipefail
if [[ ! -x /usr/local/lib/eitr/eitr-system || ! -f /etc/pacman.d/hooks/05-eitr-snapshot-pre.hook ]]; then
  echo 'Snapshot-protected updates are not configured. See Eitr distro/README.md; no update was started.' >&2
  exit 1
fi
case "${1:-}" in
  pacman) sudo pacman -Syu ;;
  yay) yay -Syu ;;
  full) sudo pacman -Syu; yay -Sua --devel ;;
  *) echo 'Usage: update.sh pacman|yay|full' >&2; exit 2 ;;
esac
