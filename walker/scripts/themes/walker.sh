#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="${CURRENT_DIR:-$HOME/.config/theme/current}"
WALKER_THEME_DIR="${WALKER_THEME_DIR:-$HOME/.config/walker/themes/current}"
CURRENT_FILE="$WALKER_THEME_DIR/style.css"

mkdir -p "$WALKER_THEME_DIR"

is_light_mode() {
  [[ -f "$CURRENT_DIR/light.mode" ]]
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

if [[ ! -f "$CURRENT_DIR/colors.toml" ]]; then
  cp /etc/xdg/walker/themes/default/style.css "$CURRENT_FILE"
  exit 0
fi

accent="$(theme_value accent)"
foreground="$(theme_value foreground)"
background="$(theme_value background)"
selection_foreground="$(theme_value selection_foreground)"
selection_background="$(theme_value selection_background)"
error_background="$(theme_value color1)"
color0="$(theme_value color0)"
color8="$(theme_value color8)"

if [[ -z "$accent" || -z "$foreground" || -z "$background" ]]; then
  cp /etc/xdg/walker/themes/default/style.css "$CURRENT_FILE"
  exit 0
fi

selection_foreground="${selection_foreground:-$background}"
selection_background="${selection_background:-$accent}"
error_background="${error_background:-$accent}"
color0="${color0:-$background}"
color8="${color8:-$color0}"

if is_light_mode; then
  window_alpha="0.92"
  input_alpha="0.76"
  selected_alpha="0.22"
  border_alpha="0.72"
  shadow_alpha="0.16"
else
  window_alpha="0.88"
  input_alpha="0.58"
  selected_alpha="0.26"
  border_alpha="0.72"
  shadow_alpha="0.34"
fi

cat > "$CURRENT_FILE" <<EOF
@define-color window_bg_color $(rgba "$background" "$window_alpha");
@define-color base_bg_color $background;
@define-color input_bg_color $(rgba "$color0" "$input_alpha");
@define-color accent_bg_color $accent;
@define-color theme_fg_color $foreground;
@define-color selected_bg_color $(rgba "$color8" "$selected_alpha");
@define-color selected_fg_color $selection_foreground;
@define-color error_bg_color $error_background;
@define-color error_fg_color $selection_foreground;

* {
  all: unset;
  font-family: "JetBrainsMono Nerd Font", monospace;
  font-size: 12px;
}

popover {
  background: @window_bg_color;
  border: 1px solid $(rgba "$accent" "$border_alpha");
  border-radius: 8px;
  padding: 10px;
}

.normal-icons {
  -gtk-icon-size: 13px;
}

.large-icons {
  -gtk-icon-size: 24px;
}

scrollbar {
  opacity: 0;
}

.box-wrapper {
  box-shadow:
    0 19px 38px $(rgba "$background" "$shadow_alpha"),
    0 15px 12px $(rgba "$background" "$shadow_alpha");
  background: @window_bg_color;
  padding: 18px;
  border-radius: 8px;
  border: 2px solid $(rgba "$accent" "$border_alpha");
}

.preview-box,
.elephant-hint,
.placeholder,
.list,
.preview {
  color: @theme_fg_color;
}

.search-container {
  border-radius: 6px;
}

.input placeholder {
  opacity: 0.5;
}

.input selection {
  background: @selected_bg_color;
  color: @selected_fg_color;
}

.input {
  caret-color: @theme_fg_color;
  background: @input_bg_color;
  padding: 10px;
  color: @theme_fg_color;
  border-radius: 6px;
  border: 1px solid $(rgba "$accent" "0.28");
}

.item-box {
  border-radius: 6px;
  padding: 10px;
}

.item-quick-activation {
  background: $(rgba "$accent" "0.20");
  border-radius: 5px;
  padding: 10px;
}

child:hover .item-box,
child:selected .item-box,
row:selected .item-box {
  background: @selected_bg_color;
}

child:selected .item-text,
row:selected .item-text {
  color: @selected_fg_color;
}

.item-subtext {
  font-size: 12px;
  opacity: 0.62;
}

.providerlist .item-subtext {
  font-size: unset;
  opacity: 0.75;
}

.item-image-text {
  font-size: 18px;
}

.preview {
  border: 1px solid $(rgba "$accent" "0.25");
  border-radius: 8px;
}

.calc .item-text {
  font-size: 24px;
}

.symbols .item-image {
  font-size: 24px;
}

.todo.done .item-text-box {
  opacity: 0.25;
}

.todo.urgent {
  font-size: 24px;
}

.todo.active {
  font-weight: bold;
}

.bluetooth.disconnected {
  opacity: 0.5;
}

.preview .large-icons {
  -gtk-icon-size: 48px;
}

.keybinds {
  padding-top: 10px;
  border-top: 1px solid $(rgba "$accent" "0.24");
  font-size: 12px;
  color: @theme_fg_color;
}

.keybind-button {
  opacity: 0.55;
}

.keybind-button:hover {
  opacity: 0.75;
}

.keybind-bind {
  text-transform: lowercase;
  opacity: 0.45;
}

.keybind-label {
  padding: 2px 4px;
  border-radius: 4px;
  border: 1px solid @theme_fg_color;
}

.error {
  padding: 10px;
  background: @error_bg_color;
  color: @error_fg_color;
  border-radius: 6px;
}

:not(.calc).current {
  font-style: italic;
}

.preview-content.archlinuxpkgs,
.preview-content.dnfpackages {
  font-family: monospace;
}
EOF
