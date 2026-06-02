#!/usr/bin/env bash

DEV_DIR="$HOME/Development"
MENUS_DIR="$HOME/.config/wofi/scripts/menus"
BACK_MENU="${BACK_MENU:-$MENUS_DIR/main.sh}"

options="←  Back
  Codex
󰚩  Claude Code"

chosen="$(echo -e "$options" | wofi --dmenu --no-sort --cache-file /dev/null --prompt="AI Tool")"

[[ -z "$chosen" ]] && exit 0

case "$chosen" in
  "←  Back")
    "$BACK_MENU"
    exit 0
    ;;
esac

repo="$(
  find "$DEV_DIR" -mindepth 3 -maxdepth 3 -type d -name ".git" |
    sed "s|$DEV_DIR/||; s|/.git||" |
    sort |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="Repository"
)"

[[ -z "$repo" ]] && exit 0

repo_path="$DEV_DIR/$repo"

case "$chosen" in
  "  Codex")
    kitty --directory "$repo_path" zsh -ic 'codex; exec zsh'
    ;;
  "󰚩  Claude Code")
    kitty --directory "$repo_path" zsh -ic 'claude; exec zsh'
    ;;
  *)
    exit 0
    ;;
esac
