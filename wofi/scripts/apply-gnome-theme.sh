#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"

GTK_ENV_FILE="$HOME/.config/hypr/theme-env.conf"
GTK3_DIR="$HOME/.config/gtk-3.0"
GTK4_DIR="$HOME/.config/gtk-4.0"

FONT_NAME="JetBrainsMono Nerd Font 11"
CURSOR_THEME="default"
CURSOR_SIZE="24"

mkdir -p "$HOME/.config/hypr" "$GTK3_DIR" "$GTK4_DIR"

# Icon theme from current theme folder
if [[ -f "$CURRENT_DIR/icons.theme" ]]; then
  ICON_THEME="$(<"$CURRENT_DIR/icons.theme")"
else
  ICON_THEME="Yaru"
fi

if [[ -f "$CURRENT_DIR/light.mode" ]]; then
  GTK_THEME="Adwaita"
  COLOR_SCHEME="prefer-light"
else
  GTK_THEME="Dracula"
  COLOR_SCHEME="prefer-dark"
fi

# GNOME / GTK settings
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME"
gsettings set org.gnome.desktop.interface font-name "$FONT_NAME"
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"

# GTK3 + GTK4 settings
for dir in "$GTK3_DIR" "$GTK4_DIR"; do
  cat > "$dir/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=$FONT_NAME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-application-prefer-dark-theme=$([[ "$COLOR_SCHEME" == "prefer-dark" ]] && echo true || echo false)
EOF
done

# Hyprland env
cat > "$GTK_ENV_FILE" <<EOF
env = GTK_THEME,$GTK_THEME
env = ADW_DEBUG_COLOR_SCHEME,$COLOR_SCHEME
EOF

export GTK_THEME="$GTK_THEME"
export ADW_DEBUG_COLOR_SCHEME="$COLOR_SCHEME"

dbus-update-activation-environment --systemd \
  GTK_THEME \
  ADW_DEBUG_COLOR_SCHEME

hyprctl reload >/dev/null 2>&1 || true
nautilus -q >/dev/null 2>&1 || true
