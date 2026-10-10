#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$HOME/.config/theme/current"
VSCODE_THEME_FILE="$CURRENT_DIR/vscode.json"
USER_SETTINGS="$HOME/.config/Code/User/settings.json"
HELPER="$(dirname "${BASH_SOURCE[0]}")/vscode-theme.py"

[[ -f "$VSCODE_THEME_FILE" ]] || exit 0

{
  IFS= read -r THEME_NAME
  IFS= read -r EXTENSION_ID
  IFS= read -r LOCAL_VSIX
} < <(python3 "$HELPER" read "$VSCODE_THEME_FILE")

[[ -n "$THEME_NAME" ]] || exit 0

if [[ -n "$EXTENSION_ID" ]] && command -v code >/dev/null 2>&1; then
  if ! code --list-extensions | grep -qx "$EXTENSION_ID"; then
    if [[ -n "$LOCAL_VSIX" && -f "$CURRENT_DIR/$LOCAL_VSIX" ]]; then
      code --install-extension "$CURRENT_DIR/$LOCAL_VSIX"
    else
      code --install-extension "$EXTENSION_ID"
    fi
  fi
fi

mkdir -p "$(dirname "$USER_SETTINGS")"
python3 "$HELPER" set "$USER_SETTINGS" "$THEME_NAME"
