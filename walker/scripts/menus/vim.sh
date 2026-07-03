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
  o                         New line below
  O                         New line above
  A                         Append at end of line
  I                         Insert at start of line
  C                         Change to end of line
  x                         Delete character
  dd                        Delete line
  D                         Delete to end of line
  cc                        Change whole line
  yy                        Yank line
  p                         Paste after cursor
  P                         Paste before cursor
  r                         Replace one character
  J                         Join next line
󰅇  Copy and paste
  yy                        Copy line
  y                         Copy selection
  p                         Paste after cursor
  P                         Paste before cursor
  \"_d                       Delete without yanking
  \"_x                       Delete char without yanking
  \"+y                       Copy to system clipboard
  \"+p                       Paste from system clipboard
  :set paste                Enable paste mode
  :set nopaste              Disable paste mode
󰉿  Text objects
  diw                       Delete inner word
  ciw                       Change inner word
  yiw                       Yank inner word
  daw                       Delete a word
  caw                       Change a word
  di\"                       Delete inside quotes
  ci\"                       Change inside quotes
  yi\"                       Yank inside quotes
  di(                       Delete inside parentheses
  ci(                       Change inside parentheses
  yi(                       Yank inside parentheses
  cit                       Change inside tag
  vat                       Select around tag
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
  :%s/old/new/gc            Replace with confirm
  :g/pattern/d              Delete matching lines
  :v/pattern/d              Delete nonmatching lines
󰈞  Files and project
  :e file                   Open file
  :Ex                       Open file explorer
  :find file                Find file in path
  :grep text **/*           Search text in files
  :vimgrep /text/g **/*     Search with quickfix
  :copen                    Open quickfix list
  :cnext                    Next quickfix result
  :cprev                    Previous quickfix result
  <leader><space>           Find project files
  <leader>/                 Search in project
  <leader>,                 Switch buffers
  <leader>e                 File explorer
󰒓  LSP and code
  gd                        Go to definition
  gr                        Go to references
  K                         Hover documentation
  ]d                        Next diagnostic
  [d                        Previous diagnostic
  <leader>ca                Code action
  <leader>cr                Rename symbol
  <leader>cf                Format file
  <leader>cd                Line diagnostics
  :LspInfo                  Show LSP info
  :Mason                    Manage language tools
󰊢  Git
  ]h                        Next git hunk
  [h                        Previous git hunk
  <leader>gb                Git blame line
  <leader>gg                Open lazygit
  :Gitsigns preview_hunk    Preview git hunk
  :Gitsigns reset_hunk      Reset git hunk
󰖲  Windows
  Ctrl-w s                  Horizontal split
  Ctrl-w v                  Vertical split
  Ctrl-w h/j/k/l            Move between windows
  Ctrl-w =                  Equalize windows
  Ctrl-w q                  Close window
  Ctrl-w o                  Keep only current window
  Ctrl-w T                  Move window to tab
󰓩  Tabs and buffers
  :e file                   Edit file
  :bn                       Next buffer
  :bp                       Previous buffer
  :bd                       Delete buffer
  :ls                       List buffers
  :tabnew                   New tab
  gt                        Next tab
  gT                        Previous tab
  :b#                       Previous active buffer
  :bufdo w                  Save all buffers
  :wall                     Save all files
  :qa                       Quit all
  Terminal
  :terminal                 Open terminal
  Ctrl-\\ Ctrl-n             Terminal normal mode
  :split | terminal         Terminal split
  :vsplit | terminal        Terminal vsplit
󰃀  Marks and jumps
  ma                        Set mark a
  'a                        Jump to line mark a
  `a                        Jump to exact mark a
  Ctrl-o                    Jump back
  Ctrl-i                    Jump forward
  :marks                    List marks
  :jumps                    List jumps
  :changes                  List changes
  g;                        Previous change
  g,                        Next change
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
󰙅  Sessions and plugins
  :Lazy                     Plugin manager
  :Lazy update              Update plugins
  :Lazy sync                Sync plugins
  :checkhealth              Check Neovim health
  :Inspect                  Inspect highlight
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
  "" | 󰌌* | 󰁔* | * | 󰅇* | 󰉿* | 󰒆* | 󰍉* | 󰈞* | 󰒓* | 󰊢* | 󰖲* | 󰓩* | * | 󰃀* | 󰑋* | 󰘖* | 󰙅* | 󰋖*)
    exit 0
    ;;
  *)
    copy_command
    ;;
esac
