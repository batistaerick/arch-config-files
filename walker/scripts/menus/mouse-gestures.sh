#!/usr/bin/env bash

options="Desktop: double left-click       Wallpaper carousel
Desktop: double right-click      Theme carousel
Bar: double left-click           Blur / Theme Color
Bar: double right-click          One bar / three sections
Bar: left-click and drag         Move to a screen edge
Workspace: right-click           Workspace style"

chosen=$(printf '%s\n' "$options" | "$HOME/.config/walker/bin/walker-dmenu" --dmenu --no-sort --cache-file /dev/null --width 780 --prompt="Mouse Gestures")
case "$chosen" in
  "Desktop: double left-click"*)
    bash "$HOME/.config/quickshell/desktop-bar/scripts/appearance-picker.sh" wallpaper ;;
  "Desktop: double right-click"*)
    bash "$HOME/.config/quickshell/desktop-bar/scripts/appearance-picker.sh" theme ;;
  "Bar: double left-click"*)
    python3 "$HOME/.config/quickshell/desktop-bar/scripts/bar-settings.py" toggle appearance ;;
  "Bar: double right-click"*)
    python3 "$HOME/.config/quickshell/desktop-bar/scripts/bar-settings.py" toggle layout ;;
  "Bar: left-click and drag"*)
    "$HOME/.config/walker/bin/walker" --provider menus:bar-position ;;
  "Workspace: right-click"*)
    "$HOME/.config/walker/bin/walker" --provider menus:workspaces ;;
esac
