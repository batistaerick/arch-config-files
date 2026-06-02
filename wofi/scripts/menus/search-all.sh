#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"
AWS_MENUS_DIR="$MENUS_DIR/cloud/aws"
STYLE_MENUS_DIR="$MENUS_DIR/style"
CAPTURE_MENUS_DIR="$MENUS_DIR/capture"
TOGGLE_ACTIONS_DIR="$ACTIONS_DIR/toggle"
CAPTURE_ACTIONS_DIR="$ACTIONS_DIR/capture"
SHARE_ACTIONS_DIR="$ACTIONS_DIR/share"

initial_query="${1:-}"

options="←  Back
󰣇  Apps > Search Apps
  AI Tools > Codex
  AI Tools > Claude Code
  Cloud
  Cloud > AWS
  Cloud > AWS > SSO Login
  Cloud > AWS > Check Auth
  Cloud > AWS > CloudWatch
  Cloud > AWS > ECS
  Cloud > AWS > S3
  Cloud > AWS > Aurora / RDS
  Cloud > AWS > ECR
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
  Capture > Record
  Capture > Record + Audio
  Capture > Record + Webcam
  Capture > Record + Audio + Webcam
  Capture > Stop Recording
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
    wofi --dmenu --no-sort --matching=multi-contains --cache-file /dev/null --prompt="Search All" --search "$initial_query"
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
  "  Cloud")
    "$MENUS_DIR/cloud.sh"
    ;;
  "  Cloud > AWS")
    "$AWS_MENUS_DIR/menu.sh"
    ;;
  "  Cloud > AWS > SSO Login")
    AWS_PROFILE="$("$AWS_MENUS_DIR/menu.sh" --choose-profile-only)"
    [[ -z "$AWS_PROFILE" ]] && exit 0
    source "$AWS_MENUS_DIR/common.sh"
    run_in_kitty "AWS SSO - $AWS_PROFILE" "
echo 'Opening AWS SSO login...'
echo
$(aws_base) sso login
"
    ;;
  "  Cloud > AWS > Check Auth")
    AWS_PROFILE="$("$AWS_MENUS_DIR/menu.sh" --choose-profile-only)"
    [[ -z "$AWS_PROFILE" ]] && exit 0
    source "$AWS_MENUS_DIR/common.sh"
    run_in_kitty "AWS Auth - $AWS_PROFILE" "
echo 'Checking AWS auth...'
echo
$(aws_base) sts get-caller-identity
"
    ;;
  "  Cloud > AWS > CloudWatch")
    AWS_PROFILE="$("$AWS_MENUS_DIR/menu.sh" --choose-profile-only)"
    [[ -z "$AWS_PROFILE" ]] && exit 0
    "$AWS_MENUS_DIR/cloudwatch.sh" "$AWS_PROFILE"
    ;;
  "  Cloud > AWS > ECS")
    AWS_PROFILE="$("$AWS_MENUS_DIR/menu.sh" --choose-profile-only)"
    [[ -z "$AWS_PROFILE" ]] && exit 0
    "$AWS_MENUS_DIR/ecs.sh" "$AWS_PROFILE"
    ;;
  "  Cloud > AWS > S3")
    AWS_PROFILE="$("$AWS_MENUS_DIR/menu.sh" --choose-profile-only)"
    [[ -z "$AWS_PROFILE" ]] && exit 0
    "$AWS_MENUS_DIR/s3.sh" "$AWS_PROFILE"
    ;;
  "  Cloud > AWS > Aurora / RDS")
    AWS_PROFILE="$("$AWS_MENUS_DIR/menu.sh" --choose-profile-only)"
    [[ -z "$AWS_PROFILE" ]] && exit 0
    "$AWS_MENUS_DIR/rds.sh" "$AWS_PROFILE"
    ;;
  "  Cloud > AWS > ECR")
    AWS_PROFILE="$("$AWS_MENUS_DIR/menu.sh" --choose-profile-only)"
    [[ -z "$AWS_PROFILE" ]] && exit 0
    "$AWS_MENUS_DIR/ecr.sh" "$AWS_PROFILE"
    ;;
  "  Style > Theme")
    "$STYLE_MENUS_DIR/theme.sh"
    ;;
  "  Style > Wallpaper")
    "$STYLE_MENUS_DIR/wallpaper.sh"
    ;;
  "󰔎  Toggle > Screensaver")
    notify-send "Toggle" "Screensaver action is not implemented yet"
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
  "󰔎  Toggle > Configs")
    code "$HOME/.config" &
    ;;
  "󰔎  Toggle > Reboot BIOS")
    kitty -e systemctl reboot --firmware-setup
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
