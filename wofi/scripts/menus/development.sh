#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/wofi/scripts/menus"
ACTIONS_DIR="$HOME/.config/wofi/scripts/actions"

options="←  Back
󰐊  Start Doola Setup
  VS Code
  IntelliJ
  Neovim
  AI Tools
  Cloud"

chosen=$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="Development")

case "$chosen" in
  "←  Back")
    "$MENUS_DIR/main.sh"
    ;;
  "󰐊  Start Doola Setup")
    "$HOME/.config/walker/scripts/actions/development/start-doola-setup.sh"
    ;;
  "  VS Code")
    BACK_MENU="$MENUS_DIR/development.sh" "$ACTIONS_DIR/development/open-project.sh" vscode
    ;;
  "  IntelliJ")
    BACK_MENU="$MENUS_DIR/development.sh" "$ACTIONS_DIR/development/open-project.sh" intellij
    ;;
  "  Neovim")
    BACK_MENU="$MENUS_DIR/development.sh" "$ACTIONS_DIR/development/open-project.sh" nvim
    ;;
  "  AI Tools")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/ai-tools.sh"
    ;;
  "  Cloud")
    BACK_MENU="$MENUS_DIR/development.sh" "$MENUS_DIR/cloud.sh"
    ;;
  "")
    exit 0
    ;;
esac
