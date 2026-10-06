#!/usr/bin/env bash
set -euo pipefail

root="$HOME/.config/quickshell/lockscreen"
mode="${1:-lock}"
case "$mode" in
  select)
    if ! python3 "$root/scripts/settings.py" select "${2:?Missing lockscreen}"; then
      notify-send -u critical "Selection failed" "The login screen could not be updated. Run the login installer again."
      exit 1
    fi
    if [[ -x /usr/local/bin/desktop-login-select ]]; then
      notify-send -u low "Lockscreen and login selected" "Applies to your next lock and login."
    else
      notify-send -u low "Lockscreen selected" "${2} will be used the next time you lock."
    fi
    exit 0
    ;;
  lock|preview) ;;
  *) exit 2 ;;
esac
choice="${2:-$(python3 "$root/scripts/settings.py" current)}"
if [[ "$mode" == lock ]]; then
  runtime="${XDG_RUNTIME_DIR:?Missing runtime directory}"
  exec 9>"$runtime/desktop-lockscreen.lock"
  flock -n 9 || exit 0
  pgrep -x hyprlock >/dev/null && exit 0
  if [[ "$choice" == hyprlock || ! -f "$root/themes/$choice/Main.qml" ]]; then
    exec hyprlock
  fi
  export DESKTOP_LOCK_PREVIEW=0
else
  if [[ "$choice" == hyprlock ]]; then
    notify-send -u low "Hyprlock preview" "Use the lock shortcut to view your existing Hyprlock."
    exit 0
  fi
  export DESKTOP_LOCK_PREVIEW=1
fi

# Validate before resolving the theme path; no arbitrary QML paths are accepted.
export DESKTOP_LOCK_CONFIG="$(python3 "$root/scripts/settings.py" config "$choice")"
export DESKTOP_LOCK_THEME="$root/themes/$choice"
export QML_IMPORT_PATH="$root/imports${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export QML2_IMPORT_PATH="$QML_IMPORT_PATH"
if [[ "$mode" == preview ]]; then
  exec quickshell -n -p "$root/preview.qml"
fi
exec quickshell -n -c lockscreen
