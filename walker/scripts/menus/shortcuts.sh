#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"
ACTIONS_DIR="$HOME/.config/walker/scripts/actions"

options="󰌌  Launchers
  SUPER + Enter             Open terminal
  SUPER + Space             Open main menu
  SUPER + /                 Show shortcuts
  SUPER + Shift + /         Show Vim commands
  SUPER + E                 Open file manager
  SUPER + F                 Search apps
  SUPER + G                 Search Google
  SUPER + V                 Paste clipboard history
  SUPER + P                 Fuzzy-find files
  SUPER + Ctrl + P          Fuzzy-find text
󰖲  Windows
  SUPER + W                 Close active window
  SUPER + T                 Toggle floating and pin
  SUPER + Ctrl + F          Toggle fullscreen
  SUPER + Shift + P         Toggle pseudo tiling
  SUPER + A                 Toggle split direction
  SUPER + Shift + A         Rotate split direction
󰆾  Focus
  SUPER + J                 Focus left
  SUPER + K                 Focus down
  SUPER + I                 Focus up
  SUPER + L                 Focus right
󰙀  Move And Resize
  SUPER + Shift + J         Resize narrower
  SUPER + Shift + K         Resize taller
  SUPER + Shift + I         Resize shorter
  SUPER + Shift + L         Resize wider
  SUPER + Ctrl + J          Move window left
  SUPER + Ctrl + K          Move window down
  SUPER + Ctrl + I          Move window up
  SUPER + Ctrl + L          Move window right
󰎤  Workspaces
  SUPER + 1                 Go to workspace 1
  SUPER + 2                 Go to workspace 2
  SUPER + 3                 Go to workspace 3
  SUPER + 4                 Go to workspace 4
  SUPER + 5                 Go to workspace 5
  SUPER + 6                 Go to workspace 6
  SUPER + 7                 Go to workspace 7
  SUPER + 8                 Go to workspace 8
  SUPER + 9                 Go to workspace 9
  SUPER + 0                 Go to workspace 10
  SUPER + Shift + 1         Move window to workspace 1
  SUPER + Shift + 2         Move window to workspace 2
  SUPER + Shift + 3         Move window to workspace 3
  SUPER + Shift + 4         Move window to workspace 4
  SUPER + Shift + 5         Move window to workspace 5
  SUPER + Shift + 6         Move window to workspace 6
  SUPER + Shift + 7         Move window to workspace 7
  SUPER + Shift + 8         Move window to workspace 8
  SUPER + Shift + 9         Move window to workspace 9
  SUPER + Shift + 0         Move window to workspace 10
  SUPER + S                 Toggle special workspace
  SUPER + Shift + S         Move window to special workspace
  SUPER + Ctrl + S          Move window to workspace 1
  SUPER + Mouse Wheel Down  Next existing workspace
  SUPER + Mouse Wheel Up    Previous existing workspace
  Capture And Desktop
  Print                     Full screenshot
  SUPER + Print             Selection screenshot
  SUPER + Shift + N         Next wallpaper
  SUPER + Ctrl + N          Wallpaper picker
  SUPER + Shift + Space     Toggle Waybar
  SUPER + N                 Notification center
  SUPER + =                 Color picker
  SUPER + M                 Lock screen
  SUPER + ;                 Character picker
  Media And Hardware
  F8                        Play or pause media
  F9                        Next media
  Volume Up                 Raise volume
  Volume Down               Lower volume
  Volume Mute               Toggle output mute
  Mic Mute                  Toggle microphone mute
  Brightness Up             Raise brightness
  Brightness Down           Lower brightness
  Media Previous            Previous media
  Media Play/Pause          Play or pause media
  Media Next                Next media"

chosen="$(
  echo -e "$options" |
    $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --cache-file /dev/null --width 820 --height 720 --prompt="Shortcuts"
)"

case "$chosen" in
  "" | 󰌌* | 󰖲* | 󰆾* | 󰙀* | 󰎤* | * | *)
    exit 0
    ;;
  "  SUPER + Enter"*)
    kitty &
    ;;
  "  SUPER + Space"*)
    "$MENUS_DIR/native-main.sh"
    ;;
  "  SUPER + /"*)
    "$MENUS_DIR/shortcuts.sh"
    ;;
  "  SUPER + Shift + /"*)
    "$MENUS_DIR/vim.sh"
    ;;
  "  SUPER + E"*)
    dolphin --new-window &
    ;;
  "  SUPER + F"*)
    "$MENUS_DIR/search.sh"
    ;;
  "  SUPER + G"*)
    "$ACTIONS_DIR/search/google.sh"
    ;;
  "  SUPER + V"*)
    cliphist list | $HOME/.config/walker/bin/walker-dmenu --dmenu --width 1000 | cliphist decode | wl-copy && wtype -M ctrl v -m ctrl
    ;;
  "  SUPER + P"*)
    kitty --class fif-terminal -e zsh -c 'source ~/.zshrc; fif; kill -9 $$' &
    ;;
  "  SUPER + Ctrl + P"*)
    kitty --class fifs-terminal -e zsh -c 'source ~/.zshrc; fifs; exit 0' &
    ;;
  "  SUPER + W"*)
    hyprctl dispatch killactive
    ;;
  "  SUPER + T"*)
    hyprctl --batch "dispatch togglefloating; dispatch pin"
    ;;
  "  SUPER + Ctrl + F"*)
    hyprctl dispatch 'hl.dsp.window.fullscreen()'
    ;;
  "  SUPER + Shift + P"*)
    hyprctl dispatch pseudo
    ;;
  "  SUPER + A"*)
    hyprctl dispatch layoutmsg togglesplit
    ;;
  "  SUPER + Shift + A"*)
    hyprctl dispatch layoutmsg rotatesplit
    ;;
  "  SUPER + J"*)
    hyprctl dispatch movefocus l
    ;;
  "  SUPER + K"*)
    hyprctl dispatch movefocus d
    ;;
  "  SUPER + I"*)
    hyprctl dispatch movefocus u
    ;;
  "  SUPER + L"*)
    hyprctl dispatch movefocus r
    ;;
  "  SUPER + Shift + J"*)
    hyprctl dispatch resizeactive -15 0
    ;;
  "  SUPER + Shift + K"*)
    hyprctl dispatch resizeactive 0 15
    ;;
  "  SUPER + Shift + I"*)
    hyprctl dispatch resizeactive 0 -15
    ;;
  "  SUPER + Shift + L"*)
    hyprctl dispatch resizeactive 15 0
    ;;
  "  SUPER + Ctrl + J"*)
    hyprctl dispatch movewindow l
    ;;
  "  SUPER + Ctrl + K"*)
    hyprctl dispatch movewindow d
    ;;
  "  SUPER + Ctrl + I"*)
    hyprctl dispatch movewindow u
    ;;
  "  SUPER + Ctrl + L"*)
    hyprctl dispatch movewindow r
    ;;
  "  SUPER + 1"*)
    hyprctl dispatch workspace 1
    ;;
  "  SUPER + 2"*)
    hyprctl dispatch workspace 2
    ;;
  "  SUPER + 3"*)
    hyprctl dispatch workspace 3
    ;;
  "  SUPER + 4"*)
    hyprctl dispatch workspace 4
    ;;
  "  SUPER + 5"*)
    hyprctl dispatch workspace 5
    ;;
  "  SUPER + 6"*)
    hyprctl dispatch workspace 6
    ;;
  "  SUPER + 7"*)
    hyprctl dispatch workspace 7
    ;;
  "  SUPER + 8"*)
    hyprctl dispatch workspace 8
    ;;
  "  SUPER + 9"*)
    hyprctl dispatch workspace 9
    ;;
  "  SUPER + 0"*)
    hyprctl dispatch workspace 10
    ;;
  "  SUPER + Shift + 1"*)
    hyprctl dispatch movetoworkspace 1
    ;;
  "  SUPER + Shift + 2"*)
    hyprctl dispatch movetoworkspace 2
    ;;
  "  SUPER + Shift + 3"*)
    hyprctl dispatch movetoworkspace 3
    ;;
  "  SUPER + Shift + 4"*)
    hyprctl dispatch movetoworkspace 4
    ;;
  "  SUPER + Shift + 5"*)
    hyprctl dispatch movetoworkspace 5
    ;;
  "  SUPER + Shift + 6"*)
    hyprctl dispatch movetoworkspace 6
    ;;
  "  SUPER + Shift + 7"*)
    hyprctl dispatch movetoworkspace 7
    ;;
  "  SUPER + Shift + 8"*)
    hyprctl dispatch movetoworkspace 8
    ;;
  "  SUPER + Shift + 9"*)
    hyprctl dispatch movetoworkspace 9
    ;;
  "  SUPER + Shift + 0"*)
    hyprctl dispatch movetoworkspace 10
    ;;
  "  SUPER + Shift + S"*)
    hyprctl dispatch movetoworkspace special:magic
    ;;
  "  SUPER + Ctrl + S"*)
    hyprctl dispatch movetoworkspace 1
    ;;
  "  SUPER + S"*)
    hyprctl dispatch togglespecialworkspace magic
    ;;
  "  SUPER + Mouse Wheel Down"*)
    hyprctl dispatch workspace e+1
    ;;
  "  SUPER + Mouse Wheel Up"*)
    hyprctl dispatch workspace e-1
    ;;
  "  Print"*)
    "$ACTIONS_DIR/capture/screenshot-full.sh"
    ;;
  "  SUPER + Print"*)
    "$ACTIONS_DIR/capture/screenshot-selection.sh"
    ;;
  "  SUPER + Shift + N"*)
    "$ACTIONS_DIR/wallpaper/next.sh"
    ;;
  "  SUPER + Ctrl + N"*)
    walker --provider menus:wallpaper
    ;;
  "  SUPER + Shift + Space"*)
    "$ACTIONS_DIR/toggle/waybar.sh"
    ;;
  "  SUPER + N"*)
    swaync-client -t -sw
    ;;
  "  SUPER + ="*)
    hyprpicker -a
    ;;
  "  SUPER + M"*)
    hyprlock
    ;;
  "  SUPER + ;"*)
    gnome-characters &
    ;;
  "  F8"* | "  Media Play/Pause"*)
    playerctl play-pause
    ;;
  "  F9"* | "  Media Next"*)
    playerctl next
    ;;
  "  Volume Up"*)
    swayosd-client --output-volume=2 --max-volume=100
    ;;
  "  Volume Down"*)
    swayosd-client --output-volume=-2 --max-volume=100
    ;;
  "  Volume Mute"*)
    swayosd-client --output-volume=mute-toggle --max-volume=100
    ;;
  "  Mic Mute"*)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    ;;
  "  Brightness Up"*)
    swayosd-client --brightness +2
    ;;
  "  Brightness Down"*)
    swayosd-client --brightness -2
    ;;
  "  Media Previous"*)
    playerctl previous
    ;;
esac
