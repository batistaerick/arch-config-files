#!/usr/bin/env bash

MENUS_DIR="$HOME/.config/walker/scripts/menus"

options="$(cat <<'EOF'
󰌌  Basics
  i                         Insert before cursor
  a                         Insert after cursor
  Esc                       Return to normal mode
  :w                        Save file
  :q                        Quit window
  :wq                       Save and quit
  :q!                       Quit without saving
󰁔  Movement
  h / j / k / l             Move left / down / up / right
  w                         Next word
  b                         Previous word
  e                         End of word
  0                         Start of line
  ^                         First nonblank character
  $                         End of line
  gg                        First line
  G                         Last line
  {number}G                 Go to line number
  Editing
  u                         Undo
  Ctrl-r                    Redo
  .                         Repeat last change
  x                         Delete character
  dd                        Delete line
  D                         Delete to end of line
  yy                        Yank line
  p                         Paste after cursor
  P                         Paste before cursor
  J                         Join next line
󰉿  Text objects
  diw                       Delete inner word
  ciw                       Change inner word
  yiw                       Yank inner word
  di\"                       Delete inside quotes
  ci\"                       Change inside quotes
  di(                       Delete inside parentheses
  ci(                       Change inside parentheses
󰒆  Visual mode
  v                         Visual character mode
  V                         Visual line mode
  Ctrl-v                    Visual block mode
  y                         Yank selection
  d                         Delete selection
  >                         Indent selection
  <                         Unindent selection
󰍉  Search and replace
  /text                     Search forward
  ?text                     Search backward
  n                         Next search match
  N                         Previous search match
  *                         Search word under cursor forward
  #                         Search word under cursor backward
  :noh                      Clear search highlight
  :%s/old/new/g             Replace in whole file
  :s/old/new/g              Replace in current line
󰖲  Windows
  Ctrl-w s                  Horizontal split
  Ctrl-w v                  Vertical split
  Ctrl-w h/j/k/l            Move between windows
  Ctrl-w =                  Equalize windows
  Ctrl-w q                  Close window
󰓩  Tabs and buffers
  :e file                   Edit file
  :bn                       Next buffer
  :bp                       Previous buffer
  :bd                       Delete buffer
  :ls                       List buffers
  :tabnew                   New tab
  gt                        Next tab
  gT                        Previous tab
󰃀  Marks and jumps
  ma                        Set mark a
  'a                        Jump to line mark a
  `a                        Jump to exact mark a
  Ctrl-o                    Jump back
  Ctrl-i                    Jump forward
  :marks                    List marks
󰑋  Registers and macros
  :reg                      List registers
  \"0p                       Paste last yanked text
  \"+y                       Yank to system clipboard
  \"+p                       Paste from system clipboard
  qa                        Record macro into register a
  q                         Stop recording macro
  @a                        Play macro a
  @@                        Replay last macro
󰘖  Folds
  za                        Toggle fold
  zo                        Open fold
  zc                        Close fold
  zR                        Open all folds
  zM                        Close all folds
󰋖  Help
  :Tutor                    Open Vim tutor
  :help motion              Help for motions
  :help text-objects        Help for text objects
  :help quickref            Quick reference
EOF
)"

chosen="$(
  echo -e "$options" |
    $HOME/.config/walker/bin/walker-dmenu --dmenu --no-sort --matching=contains --cache-file /dev/null --width 820 --height 720 --prompt="Vim Commands"
)"

copy_command() {
  local command_text

  command_text="$(printf '%s' "$chosen" | cut -c 3-28 | sed -E 's/[[:space:]]+$//')"

  if [[ -n "$command_text" ]]; then
    printf '%s' "$command_text" | wl-copy
    notify-send "Vim command copied" "$command_text"
  fi
}

case "$chosen" in
  "" | 󰌌* | 󰁔* | * | 󰉿* | 󰒆* | 󰍉* | 󰖲* | 󰓩* | 󰃀* | 󰑋* | 󰘖* | 󰋖*)
    exit 0
    ;;
  *)
    copy_command
    ;;
esac
