#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"
AWS_MENUS_DIR="$MENUS_DIR/cloud/aws"
GCP_MENUS_DIR="$MENUS_DIR/cloud/gcp"
AZURE_MENUS_DIR="$MENUS_DIR/cloud/azure"
STYLE_MENUS_DIR="$MENUS_DIR/style"
CAPTURE_MENUS_DIR="$MENUS_DIR/capture"
TOGGLE_ACTIONS_DIR="$ACTIONS_DIR/toggle"
CAPTURE_ACTIONS_DIR="$ACTIONS_DIR/capture"
SHARE_ACTIONS_DIR="$ACTIONS_DIR/share"
DEVELOPMENT_ACTIONS_DIR="$ACTIONS_DIR/development"

initial_query="${1:-}"

options="←  Back
󰣇  Apps > Search Apps
󰅩  Development
󰅩  Development > VS Code
󰅩  Development > IntelliJ
󰅩  Development > Neovim
󰅩  Development > AI Tools
󰅩  Development > AI Tools > Codex
󰅩  Development > AI Tools > Claude Code
󰅩  Development > Cloud
󰅩  Development > Cloud > AWS
󰅩  Development > Cloud > GCP
󰅩  Development > Cloud > Azure
  Style > Theme
  Style > Wallpaper
󰔎  Toggle > Screensaver
󰔎  Toggle > Nightlight
󰔎  Toggle > Idle Lock
󰔎  Toggle > Notifications
󰔎  Toggle > Top Bar
  Capture > Screenshot
  Capture > Screenshot Selection
  Capture > Screenshot Full Screen
  Capture > Screenrecord
  Capture > Record
  Capture > Record + Audio
  Capture > Record + Webcam
  Capture > Record + Audio + Webcam
  Capture > Stop Recording
  Capture > Color Picker
  Share > Clipboard
  Share > File
  Share > Folder
  System
  System > Audio
  System > WiFi
  System > Bluetooth
  System > Dotfiles
  System > Update
  System > Update > Pacman
  System > Update > Yay
  System > Update > Full Upgrade Clean
  System > About
⏻  Power > Shutdown
⏻  Power > Reboot
⏻  Power > Reboot BIOS
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
    wofi --dmenu --no-sort --matching=multi-contains --cache-file /dev/null --prompt="Search All" --search "$initial_query"
)"

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󰣇  Apps > Search Apps")
    "$MENUS_DIR/search.sh"
    ;;
  "󰅩  Development")
    "$MENUS_DIR/development.sh"
    ;;
  "󰅩  Development > VS Code")
    "$DEVELOPMENT_ACTIONS_DIR/open-project.sh" vscode
    ;;
  "󰅩  Development > IntelliJ")
    "$DEVELOPMENT_ACTIONS_DIR/open-project.sh" intellij
    ;;
  "󰅩  Development > Neovim")
    "$DEVELOPMENT_ACTIONS_DIR/open-project.sh" nvim
    ;;
  "󰅩  Development > AI Tools")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/ai-tools.sh"
    ;;
  "󰅩  Development > AI Tools > Codex")
    run_ai_tool codex
    ;;
  "󰅩  Development > AI Tools > Claude Code")
    run_ai_tool claude
    ;;
  "󰅩  Development > Cloud")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/cloud.sh"
    ;;
  "󰅩  Development > Cloud > AWS")
    "$MENUS_DIR/cloud/aws/menu.sh"
    ;;
  "󰅩  Development > Cloud > GCP")
    "$MENUS_DIR/cloud/gcp/menu.sh"
    ;;
  "󰅩  Development > Cloud > Azure")
    "$MENUS_DIR/cloud/azure/menu.sh"
    ;;
  "  Style > Theme")
    "$STYLE_MENUS_DIR/theme.sh"
    ;;
  "  Style > Wallpaper")
    "$STYLE_MENUS_DIR/wallpaper.sh"
    ;;
  "󰔎  Toggle > Screensaver")
    "$TOGGLE_ACTIONS_DIR/screensaver.sh"
    ;;
  "󰔎  Toggle > Nightlight")
    "$TOGGLE_ACTIONS_DIR/nightlight.sh"
    ;;
  "󰔎  Toggle > Idle Lock")
    "$TOGGLE_ACTIONS_DIR/idle-lock.sh"
    ;;
  "󰔎  Toggle > Notifications")
    "$TOGGLE_ACTIONS_DIR/notification-silencing.sh"
    ;;
  "󰔎  Toggle > Top Bar")
    "$TOGGLE_ACTIONS_DIR/waybar.sh"
    ;;
  "  Capture > Screenshot")
    "$CAPTURE_MENUS_DIR/screenshot.sh"
    ;;
  "  Capture > Screenshot Selection")
    "$CAPTURE_ACTIONS_DIR/screenshot-selection.sh"
    ;;
  "  Capture > Screenshot Full Screen")
    "$CAPTURE_ACTIONS_DIR/screenshot-full.sh"
    ;;
  "  Capture > Screenrecord")
    "$CAPTURE_MENUS_DIR/screenrecord.sh"
    ;;
  "  Capture > Record")
    "$CAPTURE_MENUS_DIR/screenrecord.sh" record
    ;;
  "  Capture > Record + Audio")
    "$CAPTURE_MENUS_DIR/screenrecord.sh" audio
    ;;
  "  Capture > Record + Webcam")
    "$CAPTURE_MENUS_DIR/screenrecord.sh" webcam
    ;;
  "  Capture > Record + Audio + Webcam")
    "$CAPTURE_MENUS_DIR/screenrecord.sh" audio-webcam
    ;;
  "  Capture > Stop Recording")
    "$CAPTURE_MENUS_DIR/screenrecord.sh" stop
    ;;
  "  Capture > Color Picker")
    (sleep 0.2 && hyprpicker -a) &
    ;;
  "  Share > Clipboard")
    "$SHARE_ACTIONS_DIR/localsend-share.sh" clipboard
    ;;
  "  Share > File")
    kitty -e "$SHARE_ACTIONS_DIR/localsend-share.sh" file
    ;;
  "  Share > Folder")
    kitty -e "$SHARE_ACTIONS_DIR/localsend-share.sh" folder
    ;;
  "  System")
    "$MENUS_DIR/system.sh"
    ;;
  "  System > Audio")
    open_setup_window "pavucontrol" "pavucontrol"
    ;;
  "  System > WiFi")
    open_setup_window "setup-wifi" "kitty --class setup-wifi -e impala"
    ;;
  "  System > Bluetooth")
    open_setup_window "blueman-manager" "blueman-manager"
    ;;
  "  System > Dotfiles")
    code "$HOME/.config" &
    ;;
  "  System > Update")
    "$MENUS_DIR/update.sh"
    ;;
  "  System > Update > Pacman")
    kitty -e sudo pacman -Syu
    ;;
  "  System > Update > Yay")
    kitty -e yay -Syu
    ;;
  "  System > Update > Full Upgrade Clean")
    kitty -e bash -c "sudo pacman -Syu && yay -Sua --devel"
    ;;
  "  System > About")
    "$ACTIONS_DIR/about.sh"
    ;;
  "⏻  Power > Shutdown")
    systemctl poweroff
    ;;
  "⏻  Power > Reboot")
    systemctl reboot
    ;;
  "⏻  Power > Reboot BIOS")
    kitty -e systemctl reboot --firmware-setup
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
