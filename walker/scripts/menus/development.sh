#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"

options="󰐊  Start Doola Setup
  VS Code
  IntelliJ
  LazyVim
  LazyVim Commands
  AI Tools
󰨇  Grafana Logs
  Cloud"

chosen=$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Development")

case "$chosen" in
  "󰐊  Start Doola Setup")
    "$ACTIONS_DIR/development/start-doola-setup.sh"
    ;;
  "  VS Code")
    BACK_MENU="$MENUS_DIR/development.sh" "$ACTIONS_DIR/development/open-project.sh" vscode
    ;;
  "  IntelliJ")
    BACK_MENU="$MENUS_DIR/development.sh" "$ACTIONS_DIR/development/open-project.sh" intellij
    ;;
  "  LazyVim")
    BACK_MENU="$MENUS_DIR/development.sh" "$ACTIONS_DIR/development/open-project.sh" nvim
    ;;
  "  LazyVim Commands")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/vim.sh"
    ;;
  "  AI Tools")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/ai-tools.sh"
    ;;
  "󰨇  Grafana Logs")
    AWS_PROFILE="$("$MENUS_DIR/cloud/aws/menu.sh" --choose-profile-only)"
    [ -z "$AWS_PROFILE" ] && exit 0
    "$MENUS_DIR/cloud/aws/grafana.sh" "$AWS_PROFILE"
    ;;
  "  Cloud")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/cloud.sh"
    ;;
  "")
    exit 0
    ;;
esac
