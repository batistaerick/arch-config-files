#!/usr/bin/env bash

set -u

section() {
  printf '\n\033[1;36m%s\033[0m\n' "$1"
}

size_of() {
  du -sh "$@" 2>/dev/null | sort -hr || true
}

confirm() {
  local prompt="$1"
  local answer

  printf "%s [y/N] " "$prompt"
  read -r answer

  case "$answer" in
    y | Y | yes | YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

run_if_available() {
  local command_name="$1"

  shift

  if command -v "$command_name" >/dev/null 2>&1; then
    "$@"
  else
    printf "Skipping %s: command not found\n" "$command_name"
  fi
}

section "Current Disk Usage"
df -h /

section "Cache Sizes"
size_of \
  "$HOME/.cache/yay" \
  /var/cache/pacman/pkg \
  "$HOME/.cache/yarn" \
  "$HOME/.npm" \
  "$HOME/.cache/go-build" \
  "$HOME/go/pkg/mod" \
  "$HOME/.local/share/pnpm/store" \
  "$HOME/.cache/pnpm" \
  "$HOME/.cache/JetBrains" \
  "$HOME/.cache/google-chrome"

section "Cleanup"

if confirm "Clean yay/AUR build cache?"; then
  run_if_available yay yay -Sc
fi

if confirm "Clean old pacman package cache?"; then
  run_if_available paccache sudo paccache -r
fi

if confirm "Clean npm cache?"; then
  run_if_available npm npm cache clean --force
fi

if confirm "Clean yarn cache?"; then
  run_if_available yarn yarn cache clean
fi

if confirm "Prune pnpm store?"; then
  run_if_available pnpm pnpm store prune
fi

if confirm "Clean Go build/module cache?"; then
  run_if_available go go clean -cache -modcache
fi

section "Disk Usage After Cleanup"
df -h /

printf '\nDone. Press Enter to close...'
read -r _
