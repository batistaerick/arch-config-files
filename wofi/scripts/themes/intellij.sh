#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$HOME/.config/theme/current"
INTELLIJ_THEME_FILE="$CURRENT_DIR/intellij.theme"

[[ ! -f "$INTELLIJ_THEME_FILE" ]] && exit 0

SCHEME_NAME="$(tr -d '\r' < "$INTELLIJ_THEME_FILE" | head -n 1 | xargs)"

[[ -z "$SCHEME_NAME" ]] && exit 0

xml_escape() {
  local value="$1"
  value="${value//&/&amp;}"
  value="${value//</&lt;}"
  value="${value//>/&gt;}"
  value="${value//\"/&quot;}"
  value="${value//\'/&apos;}"
  printf '%s' "$value"
}

resolve_scheme_name() {
  local scheme="$1"

  case "$scheme" in
    Light|Dark|Darcula|"High contrast")
      printf '%s' "$scheme"
      ;;
    _@user_*)
      printf '%s' "$scheme"
      ;;
    *)
      printf '_@user_%s' "$scheme"
      ;;
  esac
}

write_colors_file() {
  local colors_file="$1"
  local scheme="$2"
  local escaped_scheme

  escaped_scheme="$(xml_escape "$scheme")"

  mkdir -p "$(dirname "$colors_file")"

  printf '%s\n' \
    '<application>' \
    '  <component name="EditorColorsManagerImpl">' \
    "    <global_color_scheme name=\"$escaped_scheme\" />" \
    '  </component>' \
    '</application>' \
    > "$colors_file"
}

IDEA_CONFIG_DIR="$(
  find "$HOME/.config/JetBrains" -maxdepth 1 -type d \
    \( -name "IdeaIC*" -o -name "IntelliJIdea*" \) 2>/dev/null \
    | sort -V \
    | tail -n 1
)"

if [[ -z "$IDEA_CONFIG_DIR" ]]; then
  notify-send "IntelliJ Theme" "No IntelliJ config folder found"
  exit 1
fi

OPTIONS_DIR="$IDEA_CONFIG_DIR/options"
SETTINGS_SYNC_OPTIONS_DIR="$IDEA_CONFIG_DIR/settingsSync/options"
RESOLVED_SCHEME_NAME="$(resolve_scheme_name "$SCHEME_NAME")"

write_colors_file "$OPTIONS_DIR/colors.scheme.xml" "$RESOLVED_SCHEME_NAME"

if [[ -d "$SETTINGS_SYNC_OPTIONS_DIR" ]]; then
  write_colors_file "$SETTINGS_SYNC_OPTIONS_DIR/colors.scheme.xml" "$RESOLVED_SCHEME_NAME"
fi
