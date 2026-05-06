#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"

initial_query="${1:-}"

options="←  Back
󰣇  Apps > Search Apps
  AI Tools > Codex
  AI Tools > Claude Code
  Style > Theme
  Style > Wallpaper
󰔎  Toggle > Screensaver
󰔎  Toggle > Nightlight
󰔎  Toggle > Idle Lock
󰔎  Toggle > Notifications
󰔎  Toggle > Top Bar
󰔎  Toggle > Configs
󰔎  Toggle > Reboot BIOS
  Capture > Screenshot
  Capture > Screenshot Selection
  Capture > Screenshot Full Screen
  Capture > Screenrecord
  Capture > Color Picker
  Share > Clipboard
  Share > File
  Share > Folder
  Update > Pacman
  Update > Yay
  Update > Full Upgrade Clean
  Setup > Audio
  Setup > WiFi
  Setup > Bluetooth
  About
⏻  Power > Shutdown
⏻  Power > Reboot
⏻  Power > Suspend
⏻  Power > Logout"

run_ai_tool() {
  local tool="$1"
  local dev_dir="$HOME/Development"

  repo="$(
    find "$dev_dir" -mindepth 3 -maxdepth 3 -type d -name ".git" |
      sed "s|$dev_dir/||; s|/.git||" |
      sort |
      wofi --dmenu --no-sort --cache-file /dev/null --prompt="Repository"
  )"

  [[ -z "$repo" ]] && exit 0

  repo_path="$dev_dir/$repo"

  case "$tool" in
    codex)
      kitty --directory "$repo_path" zsh -ic 'codex; exec zsh'
      ;;

    claude)
      kitty --directory "$repo_path" zsh -ic 'claude; exec zsh'
      ;;
  esac
}

open_setup_window() {
  local class="$1"
  local command="$2"

  if hyprctl clients -j | jq -e ".[] | select(.class == \"$class\")" >/dev/null; then
    hyprctl dispatch togglespecialworkspace setup
  else
    hyprctl dispatch exec "[workspace special:setup silent] $command"
    sleep 0.3
    hyprctl dispatch togglespecialworkspace setup
  fi
}

chosen="$(
  echo "$options" |
    sed '/^[[:space:]]*$/d' |
    wofi \
      --dmenu \
      --no-sort \
      --matching=multi-contains \
      --cache-file /dev/null \
      --prompt="Search All" \
      --search "$initial_query"
)"

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󰣇  Apps > Search Apps")
    "$MENUS_DIR/search.sh"
    ;;
  "  AI Tools > Codex")
    run_ai_tool codex
    ;;
  "  AI Tools > Claude Code")
    run_ai_tool claude
    ;;
  "  Style > Theme")
    "$MENUS_DIR/theme.sh"
    ;;
  "  Style > Wallpaper")
    "$MENUS_DIR/wallpaper.sh"
    ;;
  "󰔎  Toggle > Screensaver")
    "$ACTIONS_DIR/capture.sh"
    ;;
  "󰔎  Toggle > Nightlight")
    "$ACTIONS_DIR/nightlight.sh"
    ;;
  "󰔎  Toggle > Idle Lock")
    "$ACTIONS_DIR/idle-lock.sh"
    ;;
  "󰔎  Toggle > Notifications")
    "$ACTIONS_DIR/notification-silencing.sh"
    ;;
  "󰔎  Toggle > Top Bar")
    "$ACTIONS_DIR/toggle-waybar.sh"
    ;;
  "󰔎  Toggle > Configs")
    code "$HOME/.config" &
    ;;
  "󰔎  Toggle > Reboot BIOS")
    kitty -e systemctl reboot --firmware-setup
    ;;
  "  Capture > Screenshot")
    "$MENUS_DIR/screenshot.sh"
    ;;
  "  Capture > Screenshot Selection")
    "$ACTIONS_DIR/screenshot-selection.sh"
    ;;
  "  Capture > Screenshot Full Screen")
    "$ACTIONS_DIR/screenshot-full.sh"
    ;;
  "  Capture > Screenrecord")
    (sleep 0.2 && obs >/dev/null 2>&1) &
    ;;
  "  Capture > Color Picker")
    (sleep 0.2 && hyprpicker -a) &
    ;;
  "  Share > Clipboard")
    "$ACTIONS_DIR/localsend-share.sh" clipboard
    ;;
  "  Share > File")
    kitty -e "$ACTIONS_DIR/localsend-share.sh" file
    ;;
  "  Share > Folder")
    kitty -e "$ACTIONS_DIR/localsend-share.sh" folder
    ;;
  "  Update > Pacman")
    kitty -e sudo pacman -Syu
    ;;
  "  Update > Yay")
    kitty -e yay -Syu
    ;;
  "  Update > Full Upgrade Clean")
    kitty -e bash -c "sudo pacman -Syu && yay -Sua --devel"
    ;;
  "  Setup > Audio")
    open_setup_window "pavucontrol" "pavucontrol"
    ;;
  "  Setup > WiFi")
    open_setup_window "setup-wifi" "kitty --class setup-wifi -e impala"
    ;;
  "  Setup > Bluetooth")
    open_setup_window "blueman-manager" "blueman-manager"
    ;;
  "  About")
    "$ACTIONS_DIR/about.sh"
    ;;
  "⏻  Power > Shutdown")
    systemctl poweroff
    ;;
  "⏻  Power > Reboot")
    systemctl reboot
    ;;
  "⏻  Power > Suspend")
    systemctl suspend
    ;;
  "⏻  Power > Logout")
    hyprctl dispatch exit
    ;;
  "")
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
