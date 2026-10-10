#!/usr/bin/env bash
set -euo pipefail
# Only the distro's System Update path creates snapshots.
full_update() { sudo pacman -Syu; yay -Sua --devel; }
case "${1:-}" in
  system)
    if [[ -f /etc/eitr/system-update-policy.conf ]]; then
      helper=/usr/local/lib/eitr/eitr-system
      [[ -x "$helper" ]] || { echo 'Distro snapshot helper is missing; update aborted.' >&2; exit 1; }
      exec 9>"${XDG_RUNTIME_DIR:-/tmp}/eitr-system-update-$UID.lock"
      flock -n 9 || { echo 'Another System Update is running.' >&2; exit 1; }
      sudo "$helper" snapshot-pre
      full_update
      sudo "$helper" snapshot-post
    else
      full_update
    fi
    ;;
  pacman) sudo pacman -Syu ;;
  yay) yay -Sua --devel ;;
  full) full_update ;;
  *) echo 'Usage: update.sh system|pacman|yay|full' >&2; exit 2 ;;
esac
