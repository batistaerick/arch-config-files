#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"
INTELLIJ_THEME_FILE="$CURRENT_DIR/intellij.theme"

[[ ! -f "$INTELLIJ_THEME_FILE" ]] && exit 0

SCHEME_NAME="$(tr -d '\r' < "$INTELLIJ_THEME_FILE" | xargs)"

[[ -z "$SCHEME_NAME" ]] && exit 0

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
COLORS_FILE="$OPTIONS_DIR/colors.scheme.xml"

mkdir -p "$OPTIONS_DIR"

cat > "$COLORS_FILE" <<EOF
<application>
  <component name="EditorColorsManagerImpl">
    <global_color_scheme name="$SCHEME_NAME" />
  </component>
</application>
EOF
