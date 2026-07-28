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
HYPR_SCRIPTS_DIR="$HOME/.config/hypr/scripts"

initial_query="${1:-}"

options="←  Back
󰣇  Apps > Search Apps
󰅩  Development
󰅩  Development > VS Code
󰅩  Development > IntelliJ
󰅩  Development > LazyVim
󰅩  Development > AI Tools
󰅩  Development > AI Tools > Codex > New
󰅩  Development > AI Tools > Codex > Resume Picker
󰅩  Development > AI Tools > Codex > Resume by Name or ID
󰅩  Development > AI Tools > Claude Code > New
󰅩  Development > AI Tools > Claude Code > New Named
󰅩  Development > AI Tools > Claude Code > Resume Picker
󰅩  Development > AI Tools > Claude Code > Resume by Name
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
⏻  Power > Lock
⏻  Power > Shutdown
⏻  Power > Reboot
⏻  Power > Reboot BIOS
⏻  Power > Suspend
⏻  Power > Logout"

run_ai_tool() {
  local tool="$1"
  local action="$2"
  local dev_dir="$HOME/Development"

  repo="$(
    find "$dev_dir" -mindepth 3 -maxdepth 3 -type d -name ".git" |
      sed "s|$dev_dir/||; s|/.git||" |
      sort |
      wofi --width 500 --dmenu --no-sort --cache-file /dev/null --prompt="Repository"
  )"

  [[ -z "$repo" ]] && exit 0

  repo_path="$dev_dir/$repo"

  case "$tool" in
    codex)
      case "$action" in
        new)
          kitty --directory "$repo_path" zsh -ic 'codex; exec zsh'
          ;;
        resume-picker)
          kitty --directory "$repo_path" zsh -ic 'codex resume; exec zsh'
          ;;
        resume-name)
          session_name="$(prompt_text "Codex Session Name or ID")"
          [[ -z "$session_name" ]] && exit 0
          kitty --directory "$repo_path" env AI_SESSION_NAME="$session_name" zsh -ic 'codex resume "$AI_SESSION_NAME"; exec zsh'
          ;;
      esac
      ;;

    claude)
      case "$action" in
        new)
          kitty --directory "$repo_path" zsh -ic 'claude; exec zsh'
          ;;
        new-named)
          session_name="$(prompt_text "Claude Session Name")"
          [[ -z "$session_name" ]] && exit 0
          kitty --directory "$repo_path" env AI_SESSION_NAME="$session_name" zsh -ic 'claude -n "$AI_SESSION_NAME"; exec zsh'
          ;;
        resume-picker)
          kitty --directory "$repo_path" zsh -ic 'claude -r; exec zsh'
          ;;
        resume-name)
          session_name="$(prompt_text "Claude Session Name")"
          [[ -z "$session_name" ]] && exit 0
          kitty --directory "$repo_path" env AI_SESSION_NAME="$session_name" zsh -ic 'claude -r "$AI_SESSION_NAME"; exec zsh'
          ;;
      esac
      ;;
  esac
}

prompt_text() {
  local prompt="$1"

  printf "" |
    wofi --width 500 --dmenu --no-sort --cache-file /dev/null --prompt="$prompt"
}

open_setup_window() {
  local class="$1"
  shift

  "$HOME/.config/wofi/scripts/actions/toggle-setup-window.sh" "$class" "$@"
}

chosen="$(
  echo "$options" |
    sed '/^[[:space:]]*$/d' |
    wofi --width 500 --dmenu --no-sort --matching=multi-contains --cache-file /dev/null --prompt="Search All" --search "$initial_query"
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
    BACK_MENU="$MENUS_DIR/search-all.sh" "$DEVELOPMENT_ACTIONS_DIR/open-project.sh" vscode
    ;;
  "󰅩  Development > IntelliJ")
    BACK_MENU="$MENUS_DIR/search-all.sh" "$DEVELOPMENT_ACTIONS_DIR/open-project.sh" intellij
    ;;
  "󰅩  Development > LazyVim")
    BACK_MENU="$MENUS_DIR/search-all.sh" "$DEVELOPMENT_ACTIONS_DIR/open-project.sh" nvim
    ;;
  "󰅩  Development > AI Tools")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/ai-tools.sh"
    ;;
  "󰅩  Development > AI Tools > Codex > New")
    run_ai_tool codex new
    ;;
  "󰅩  Development > AI Tools > Codex > Resume Picker")
    run_ai_tool codex resume-picker
    ;;
  "󰅩  Development > AI Tools > Codex > Resume by Name or ID")
    run_ai_tool codex resume-name
    ;;
  "󰅩  Development > AI Tools > Claude Code > New")
    run_ai_tool claude new
    ;;
  "󰅩  Development > AI Tools > Claude Code > New Named")
    run_ai_tool claude new-named
    ;;
  "󰅩  Development > AI Tools > Claude Code > Resume Picker")
    run_ai_tool claude resume-picker
    ;;
  "󰅩  Development > AI Tools > Claude Code > Resume by Name")
    run_ai_tool claude resume-name
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
    open_setup_window "pavucontrol" pavucontrol
    ;;
  "  System > WiFi")
    open_setup_window "setup-wifi" kitty --class setup-wifi -e impala
    ;;
  "  System > Bluetooth")
    open_setup_window "blueman-manager" blueman-manager
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
  "⏻  Power > Lock")
    "$HYPR_SCRIPTS_DIR/manual-lock.sh"
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
    loginctl lock-session && sleep 1 && systemctl suspend
    ;;
  "⏻  Power > Logout")
    uwsm stop
    ;;
  "")
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
