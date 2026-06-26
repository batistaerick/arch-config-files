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

resolve_theme_id() {
  local theme="$1"

  case "$theme" in
    "Catppuccin Latte")
      printf '%s' "com.github.catppuccin.latte.jetbrains"
      ;;
    "Catppuccin Frappé")
      printf '%s' "com.github.catppuccin.frappe.jetbrains"
      ;;
    "Catppuccin Macchiato")
      printf '%s' "com.github.catppuccin.macchiato.jetbrains"
      ;;
    "Catppuccin Mocha")
      printf '%s' "com.github.catppuccin.mocha.jetbrains"
      ;;
    "Islands Catppuccin Latte")
      printf '%s' "com.github.catppuccin.latte.islands.jetbrains"
      ;;
    "Islands Catppuccin Frappé")
      printf '%s' "com.github.catppuccin.frappe.islands.jetbrains"
      ;;
    "Islands Catppuccin Macchiato")
      printf '%s' "com.github.catppuccin.macchiato.islands.jetbrains"
      ;;
    "Islands Catppuccin Mocha")
      printf '%s' "com.github.catppuccin.mocha.islands.jetbrains"
      ;;
    "One Dark")
      printf '%s' "f92a0fa7-1a98-47cd-b5cb-78ff67e6f4f3"
      ;;
    "One Dark Islands")
      printf '%s' "71b26d33-3d44-42f4-8166-31b17c762b32"
      ;;
    "One Dark Vivid")
      printf '%s' "4b6007f7-b596-4ee2-96f9-968d3d3eb392"
      ;;
    "One Dark Vivid Islands")
      printf '%s' "a109ba15-600a-476f-b7cc-46d832daba9d"
      ;;
    "Gruvbox Dark Medium")
      printf '%s' "3ef5925f-3169-46ca-ba19-96a58f317428"
      ;;
    "Gruvbox Dark Soft")
      printf '%s' "72be8783-3a4d-4044-bb03-191e61d21ed3"
      ;;
    "Gruvbox Dark Hard")
      printf '%s' "761771ad-a164-482d-96ee-fca15bf0a238"
      ;;
    "Gruvbox Light Medium")
      printf '%s' "1eaba802-33fc-4d50-a13d-616387745dc0"
      ;;
    "Gruvbox Light Soft")
      printf '%s' "d32e62e0-f0e1-4eab-b191-5304a2b628e1"
      ;;
    "Gruvbox Light Hard")
      printf '%s' "f2de70af-bc81-47f2-a734-4c807d5ca444"
      ;;
    "Nord")
      printf '%s' "1324eea6-b737-4305-8a73-14af69073eae"
      ;;
    "Tanne")
      printf '%s' "3ee24c2b-dfef-4bee-b37e-18bd2864ffeb"
      ;;
    "Dracula")
      printf '%s' "371dce76-a3c5-4429-91af-41cf86094744"
      ;;
    "Islands Dracula")
      printf '%s' "9a1b2c3d-4e5f-6789-abcd-ef0123456789"
      ;;
    *)
      printf '%s' "$theme"
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

write_laf_file() {
  local laf_file="$1"
  local theme_id="$2"
  local escaped_theme_id
  local previous_schemes

  escaped_theme_id="$(xml_escape "$theme_id")"
  previous_schemes="$(sed -n '/<lafs-to-previous-schemes>/,/<\/lafs-to-previous-schemes>/p' "$laf_file" 2>/dev/null || true)"

  mkdir -p "$(dirname "$laf_file")"

  {
    printf '%s\n' \
      '<application>' \
      '  <component name="LafManager">' \
      "    <laf themeId=\"$escaped_theme_id\" />"

    if [[ -n "$previous_schemes" ]]; then
      printf '%s\n' "$previous_schemes"
    fi

    printf '%s\n' \
      '  </component>' \
      '</application>'
  } > "$laf_file"
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
RESOLVED_THEME_ID="$(resolve_theme_id "$SCHEME_NAME")"

write_colors_file "$OPTIONS_DIR/colors.scheme.xml" "$RESOLVED_SCHEME_NAME"
write_laf_file "$OPTIONS_DIR/laf.xml" "$RESOLVED_THEME_ID"

if [[ -d "$SETTINGS_SYNC_OPTIONS_DIR" ]]; then
  write_colors_file "$SETTINGS_SYNC_OPTIONS_DIR/colors.scheme.xml" "$RESOLVED_SCHEME_NAME"
  write_laf_file "$SETTINGS_SYNC_OPTIONS_DIR/laf.xml" "$RESOLVED_THEME_ID"
fi
