#!/usr/bin/env bash

set -euo pipefail

case "${1:-toggle}" in
  status)
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
      echo true
    else
      echo false
    fi
    ;;
  toggle)
    if [[ "${SWAYNC_TOGGLE_STATE:-}" == "true" ]]; then
      bluetoothctl power on >/dev/null
    else
      bluetoothctl power off >/dev/null
    fi
    ;;
  *)
    echo "Usage: bluetooth-power.sh [status|toggle]" >&2
    exit 2
    ;;
esac
