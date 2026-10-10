#!/usr/bin/env bash
set -euo pipefail
# Only the distro's System Update path creates snapshots.
full_update() { sudo pacman -Syu; yay -Sua --devel; }
case "${1:-}" in
  system)
    if [[ -f /etc/eitr/system-update-policy.conf ]]; then
      # Packaged helper first; /usr/local/lib holds earlier manual installs.
      helper=''
      for candidate in /usr/lib/eitr/eitr-system /usr/local/lib/eitr/eitr-system; do
        if [[ -x "$candidate" ]]; then helper="$candidate"; break; fi
      done
      [[ -n "$helper" ]] || { echo 'Distro snapshot helper is missing; update aborted.' >&2; exit 1; }
      exec 9>"${XDG_RUNTIME_DIR:-/tmp}/eitr-system-update-$UID.lock"
      flock -n 9 || { echo 'Another System Update is running.' >&2; exit 1; }
      sudo "$helper" snapshot-pre
      # Always pair the pre snapshot, even when the upgrade fails or is declined.
      outcome=failed
      trap 'sudo "$helper" snapshot-post "$outcome"' EXIT
      full_update
      outcome=success
    else
      full_update
    fi
    ;;
  pacman) sudo pacman -Syu ;;
  yay) yay -Sua --devel ;;
  full) full_update ;;
  *) echo 'Usage: update.sh system|pacman|yay|full' >&2; exit 2 ;;
esac
