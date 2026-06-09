#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="${CURRENT_DIR:-$HOME/.config/theme/current}"
WOFI_THEMES_DIR="${WOFI_THEMES_DIR:-$HOME/.config/wofi/themes}"
CURRENT_FILE="${CURRENT_FILE:-$WOFI_THEMES_DIR/current.css}"

mkdir -p "$WOFI_THEMES_DIR"

is_light_mode() {
  [[ -f "$CURRENT_DIR/light.mode" ]]
}

fallback_theme_file() {
  if is_light_mode; then
    printf '%s\n' "$WOFI_THEMES_DIR/light.css"
  else
    printf '%s\n' "$WOFI_THEMES_DIR/dark.css"
  fi
}

theme_value() {
  local key="$1"
  local file="$CURRENT_DIR/colors.toml"

  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      if (match($0, /"#[0-9A-Fa-f]{6}"/)) {
        print substr($0, RSTART + 1, 7)
      }
      exit
    }
  ' "$file"
}

hex_to_rgb() {
  local hex="${1#\#}"

  printf '%d, %d, %d' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

rgba() {
  local hex="$1"
  local alpha="$2"

  printf 'rgba(%s, %s)' "$(hex_to_rgb "$hex")" "$alpha"
}

copy_fallback_theme() {
  rm -f "$CURRENT_FILE"
  cp "$(fallback_theme_file)" "$CURRENT_FILE"
}

if [[ ! -f "$CURRENT_DIR/colors.toml" ]]; then
  copy_fallback_theme
  exit 0
fi

accent="$(theme_value accent)"
foreground="$(theme_value foreground)"
background="$(theme_value background)"
selection_foreground="$(theme_value selection_foreground)"
selection_background="$(theme_value selection_background)"
color0="$(theme_value color0)"
color1="$(theme_value color1)"
color2="$(theme_value color2)"
color3="$(theme_value color3)"
color4="$(theme_value color4)"
color5="$(theme_value color5)"
color6="$(theme_value color6)"
color8="$(theme_value color8)"

if [[ -z "$accent" || -z "$foreground" || -z "$background" ]]; then
  copy_fallback_theme
  exit 0
fi

selection_foreground="${selection_foreground:-$background}"
selection_background="${selection_background:-$accent}"
color0="${color0:-$background}"
color1="${color1:-$accent}"
color2="${color2:-$accent}"
color3="${color3:-$accent}"
color4="${color4:-$accent}"
color5="${color5:-$accent}"
color6="${color6:-$accent}"
color8="${color8:-$color0}"

if is_light_mode; then
  window_alpha="0.75"
  field_alpha="0.82"
  selected_alpha="0.68"
  glow_alpha="0.22"
else
  window_alpha="0.75"
  field_alpha="0.72"
  selected_alpha="0.64"
  glow_alpha="0.32"
fi

rm -f "$CURRENT_FILE"

cat > "$CURRENT_FILE" <<EOF
* {
  font-family: "JetBrainsMono Nerd Font", monospace;
  font-size: 14px;
}

@keyframes theme-border-spin {
  0% {
    border-top-color: $color1;
    border-right-color: $color3;
    border-bottom-color: $color2;
    border-left-color: $color4;
    box-shadow: 0 0 16px $(rgba "$color1" "$glow_alpha");
  }

  25% {
    border-top-color: $color4;
    border-right-color: $color1;
    border-bottom-color: $color3;
    border-left-color: $color2;
    box-shadow: 0 0 16px $(rgba "$color4" "$glow_alpha");
  }

  50% {
    border-top-color: $color2;
    border-right-color: $color4;
    border-bottom-color: $color1;
    border-left-color: $color3;
    box-shadow: 0 0 16px $(rgba "$color2" "$glow_alpha");
  }

  75% {
    border-top-color: $color3;
    border-right-color: $color2;
    border-bottom-color: $color4;
    border-left-color: $color1;
    box-shadow: 0 0 16px $(rgba "$color3" "$glow_alpha");
  }

  100% {
    border-top-color: $color1;
    border-right-color: $color3;
    border-bottom-color: $color2;
    border-left-color: $color4;
    box-shadow: 0 0 16px $(rgba "$color1" "$glow_alpha");
  }
}

window {
  padding: 10px;
  background-color: $(rgba "$background" "$window_alpha");
  border-radius: 8px;
  border: 2px solid $accent;
  animation-name: theme-border-spin;
  animation-duration: 2.4s;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
}

#inner-box {
  margin: 4px;
  padding: 10px;
  background-color: transparent;
}

#outer-box {
  background-color: transparent;
}

#input {
  margin: 13px;
  padding: 8px 10px;
  color: $foreground;
  background-color: $(rgba "$color0" "$field_alpha");
  border: none;
  border-radius: 6px;
}

#input image {
  margin-left: 9px;
  background-color: transparent;
}

#input:focus {
  outline: none;
  box-shadow: none;
}

#text {
  background-color: transparent;
  margin: 5px;
  color: $foreground;
}

#entry {
  background-color: transparent;
  border-radius: 6px;
}

#entry:selected {
  border: none;
  outline: none;
  box-shadow: none;
  background-color: $(rgba "$color8" "$selected_alpha");
}

#entry arrow {
  margin-left: -15px;
  border: none;
  color: transparent;
}

#entry:selected #text {
  color: $selection_background;
}

#entry:drop(active) {
  background-color: $selection_background !important;
}

#entry image {
  padding-right: 10px;
  background-color: transparent;
}

#entry:selected image {
  background-color: transparent;
}
EOF
