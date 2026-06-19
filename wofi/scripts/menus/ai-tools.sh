#!/usr/bin/env bash

DEV_DIR="$HOME/Development"
MENUS_DIR="$HOME/.config/wofi/scripts/menus"
BACK_MENU="${BACK_MENU:-$MENUS_DIR/main.sh}"

options="←  Back
  Codex > New
  Codex > Resume Picker
  Codex > Resume by Name or ID
󰚩  Claude Code > New
󰚩  Claude Code > New Named
󰚩  Claude Code > Resume Picker
󰚩  Claude Code > Resume by Name"

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

prompt_text() {
  local prompt="$1"

  printf "" |
    wofi --dmenu --no-sort --cache-file /dev/null --prompt="$prompt"
}

case "$chosen" in
  "  Codex > New")
    kitty --directory "$repo_path" zsh -ic 'codex; exec zsh'
    ;;
  "  Codex > Resume Picker")
    kitty --directory "$repo_path" zsh -ic 'codex resume; exec zsh'
    ;;
  "  Codex > Resume by Name or ID")
    session_name="$(prompt_text "Codex Session Name or ID")"
    [[ -z "$session_name" ]] && exit 0
    kitty --directory "$repo_path" env AI_SESSION_NAME="$session_name" zsh -ic 'codex resume "$AI_SESSION_NAME"; exec zsh'
    ;;
  "󰚩  Claude Code > New")
    kitty --directory "$repo_path" zsh -ic 'claude; exec zsh'
    ;;
  "󰚩  Claude Code > New Named")
    session_name="$(prompt_text "Claude Session Name")"
    [[ -z "$session_name" ]] && exit 0
    kitty --directory "$repo_path" env AI_SESSION_NAME="$session_name" zsh -ic 'claude -n "$AI_SESSION_NAME"; exec zsh'
    ;;
  "󰚩  Claude Code > Resume Picker")
    kitty --directory "$repo_path" zsh -ic 'claude -r; exec zsh'
    ;;
  "󰚩  Claude Code > Resume by Name")
    session_name="$(prompt_text "Claude Session Name")"
    [[ -z "$session_name" ]] && exit 0
    kitty --directory "$repo_path" env AI_SESSION_NAME="$session_name" zsh -ic 'claude -r "$AI_SESSION_NAME"; exec zsh'
    ;;
  *)
    exit 0
    ;;
esac
