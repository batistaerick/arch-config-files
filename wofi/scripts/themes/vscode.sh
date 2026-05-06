#!/usr/bin/env bash

CURRENT_DIR="$HOME/.config/theme/current"
VSCODE_THEME_FILE="$CURRENT_DIR/vscode.json"

[[ ! -f "$VSCODE_THEME_FILE" ]] && exit 0

THEME_NAME="$(python - "$VSCODE_THEME_FILE" <<'PY'
import json, sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
print(data.get("name", ""))
PY
)"

EXTENSION_ID="$(python - "$VSCODE_THEME_FILE" <<'PY'
import json, sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
print(data.get("extension", ""))
PY
)"

[[ -z "$THEME_NAME" ]] && exit 0

if [[ -n "$EXTENSION_ID" ]] && command -v code >/dev/null 2>&1; then
  if ! code --list-extensions | grep -qx "$EXTENSION_ID"; then
    code --install-extension "$EXTENSION_ID" >/dev/null 2>&1 || true
  fi
fi

USER_SETTINGS="$HOME/.config/Code/User/settings.json"
mkdir -p "$(dirname "$USER_SETTINGS")"

[[ ! -f "$USER_SETTINGS" ]] && echo "{}" > "$USER_SETTINGS"

python - "$USER_SETTINGS" "$THEME_NAME" <<'PY'
import json
import re
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
theme_name = sys.argv[2]

raw = settings_path.read_text()

# Remove // comments and /* */ comments, while being careful enough for normal VS Code settings.
raw = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)
raw = re.sub(r"^\s*//.*$", "", raw, flags=re.M)

# Remove trailing commas before } or ]
raw = re.sub(r",(\s*[}\]])", r"\1", raw)

try:
    data = json.loads(raw)
except Exception as e:
    print(f"Could not parse VS Code settings: {e}", file=sys.stderr)
    sys.exit(1)

data["workbench.colorTheme"] = theme_name

settings_path.write_text(
    json.dumps(data, indent=2, ensure_ascii=False) + "\n"
)
PY
