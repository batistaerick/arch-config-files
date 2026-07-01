#!/usr/bin/env bash

DEV_DIR="$HOME/Development"
MENUS_DIR="$HOME/.config/walker/scripts/menus"
BACK_MENU="${BACK_MENU:-$MENUS_DIR/native-main.sh}"
WALKER_DMENU="$HOME/.config/walker/bin/walker-dmenu"

case "${1:-}" in
  codex-new)
    chosen="  Codex > New"
    ;;
  codex-resume-picker)
    chosen="  Codex > Resume Picker"
    ;;
  codex-resume-name)
    chosen="  Codex > Resume by Name or ID"
    ;;
  claude-new)
    chosen="󰚩  Claude Code > New"
    ;;
  claude-new-named)
    chosen="󰚩  Claude Code > New Named"
    ;;
  claude-resume-picker)
    chosen="󰚩  Claude Code > Resume Picker"
    ;;
  claude-resume-name)
    chosen="󰚩  Claude Code > Resume by Name"
    ;;
  *)
    options="  Codex > New
  Codex > Resume Picker
  Codex > Resume by Name or ID
󰚩  Claude Code > New
󰚩  Claude Code > New Named
󰚩  Claude Code > Resume Picker
󰚩  Claude Code > Resume by Name"

    chosen="$(echo -e "$options" | $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="AI Tool")"
    ;;
esac

[[ -z "$chosen" ]] && exit 0

if [ ! -d "$DEV_DIR" ]; then
  notify-send "AI Tools" "$DEV_DIR does not exist"
  exit 0
fi

choose_project_dir() {
  local current rel prompt open_label chosen_dir next
  local dirs=()
  local options=()

  current="$DEV_DIR"

  while true; do
    rel="${current#$DEV_DIR}"
    rel="${rel#/}"

    if [ -z "$rel" ]; then
      prompt="AI project"
      open_label="  Open Development"
    else
      prompt="AI project: $rel"
      open_label="  Open $rel"
    fi

    mapfile -t dirs < <(
      find "$current" -mindepth 1 -maxdepth 1 -type d \
        ! -name ".git" \
        ! -name "node_modules" \
        ! -name ".idea" \
        ! -name ".gradle" \
        ! -name "target" \
        ! -name "build" \
        -printf "%f\n" |
        sort
    )

    options=("$open_label")

    for chosen_dir in "${dirs[@]}"; do
      options+=("󰉋  $chosen_dir")
    done

    chosen_dir="$(printf "%s\n" "${options[@]}" | "$WALKER_DMENU" --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="$prompt")"

    case "$chosen_dir" in
      "")
        return 1
        ;;
      "$open_label")
        printf "%s\n" "$current"
        return 0
        ;;
      󰉋\ *)
        next="${chosen_dir#󰉋  }"

        if [ -d "$current/$next" ]; then
          current="$current/$next"
        fi
        ;;
    esac
  done
}

repo_path="$(choose_project_dir)" || exit 0

prompt_text() {
  local prompt="$1"

  printf "" |
    "$WALKER_DMENU" --dmenu --no-sort --cache-file /dev/null --prompt="$prompt"
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
