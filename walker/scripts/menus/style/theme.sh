#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/themes"
CURRENT_THEME_FILE="$HOME/.cache/current-theme"
CURRENT_COLORS_FILE="$HOME/.config/theme/current/colors.toml"

current_theme=""
if [[ -f "$CURRENT_THEME_FILE" ]]; then
  current_theme="$(tr -d '[:space:]' < "$CURRENT_THEME_FILE")"
fi

accent="#7fbbb3"
if [[ -f "$CURRENT_COLORS_FILE" ]]; then
  theme_accent="$(
    sed -nE 's/^[[:space:]]*accent[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$CURRENT_COLORS_FILE" |
      head -n 1
  )"

  if [[ "$theme_accent" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    accent="$theme_accent"
  fi
fi

pango_escape() {
  local value="$1"

  value="${value//&/&amp;}"
  value="${value//</&lt;}"
  value="${value//>/&gt;}"
  value="${value//\"/&quot;}"
  value="${value//\'/&apos;}"

  printf '%s' "$value"
}

normalize_theme_name() {
  echo "$1" |
    sed -E 's/<[^>]+>//g' |
    tr '[:upper:]' '[:lower:]' |
    tr ' ' '-'
}

theme_options() {
  while IFS= read -r theme; do
    if [[ -n "$current_theme" && "$theme" == "$current_theme" ]]; then
      printf '<span foreground="%s" weight="bold" style="italic">%s</span>\n' "$accent" "$(pango_escape "$theme")"
    else
      printf '%s\n' "$theme"
    fi
  done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)
}

chosen="$(
  theme_options |
    $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --allow-markup --parse-search --cache-file /dev/null --prompt="Theme"
)"

[ -z "$chosen" ] && exit 0

theme_name="$(normalize_theme_name "$chosen")"
preview="$THEMES_DIR/$theme_name/preview.png"
preview_pid=""

preview_is_open() {
  [[ -n "$preview_pid" ]] && kill -0 "$preview_pid" 2>/dev/null
}

close_preview() {
  if preview_is_open; then
    kill "$preview_pid" 2>/dev/null || true
  fi

  preview_pid=""
}

if [[ -f "$preview" ]]; then
  imv "$preview" &
  preview_pid="$!"
else
  notify-send "Theme preview" "No preview.png found for $theme_name"
fi

while true; do
  options="Apply
Cancel"

  action="$(
    printf '%s\n' "$options" |
    $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --prompt="Apply $theme_name?"
  )"

  case "$action" in
    "Apply")
      close_preview
      setsid -f "$HOME/.config/walker/scripts/actions/style/apply.sh" "$theme_name" >/tmp/apply.log 2>&1 < /dev/null
      exit 0
      ;;
    "Cancel" | "")
      close_preview
      exit 0
      ;;
  esac
done
