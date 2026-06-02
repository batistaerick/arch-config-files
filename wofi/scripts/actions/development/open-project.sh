#!/usr/bin/env bash

set -euo pipefail

DEV_DIR="${DEV_DIR:-$HOME/Development}"
tool="${1:-}"

if [ -z "$tool" ]; then
  exit 1
fi

if [ ! -d "$DEV_DIR" ]; then
  notify-send "Development" "$DEV_DIR does not exist"
  exit 0
fi

case "$tool" in
  vscode)
    command_name="code"
    title="VS Code"
    app_icon=""
    ;;
  intellij)
    command_name="idea"
    title="IntelliJ"
    app_icon=""
    ;;
  nvim)
    command_name="nvim"
    title="Neovim"
    app_icon=""
    ;;
  *)
    notify-send "Development" "Unknown editor: $tool"
    exit 1
    ;;
esac

if ! command -v "$command_name" >/dev/null 2>&1; then
  notify-send "$title" "$command_name is not installed"
  exit 0
fi

current="$DEV_DIR"

while true; do
  rel="${current#$DEV_DIR}"
  rel="${rel#/}"

  if [ -z "$rel" ]; then
    prompt="Open project"
    open_label="$app_icon  Open Development"
  else
    prompt="Open project: $rel"
    open_label="$app_icon  Open $rel"
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

  options=("←  Back" "$open_label")

  for dir in "${dirs[@]}"; do
    options+=("󰉋  $dir")
  done

  chosen="$(printf "%s\n" "${options[@]}" | wofi --dmenu --no-sort --matching=contains --cache-file /dev/null --prompt="$prompt")"

  case "$chosen" in
    "")
      exit 0
      ;;
    "←  Back")
      if [ "$current" = "$DEV_DIR" ]; then
        exit 0
      fi

      current="$(dirname "$current")"
      ;;
    "$open_label")
      if [ "$tool" = "nvim" ]; then
        kitty --directory "$current" -e nvim . >/dev/null 2>&1 &
      else
        "$command_name" "$current" >/dev/null 2>&1 &
      fi

      exit 0
      ;;
    󰉋\ *)
      next="${chosen#󰉋  }"

      if [ -d "$current/$next" ]; then
        current="$current/$next"
      fi
      ;;
  esac
done
