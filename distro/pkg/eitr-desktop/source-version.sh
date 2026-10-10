#!/usr/bin/env bash
# Prints the eitr-desktop package version for an Eitr tree: computed from Git
# for a checkout, or read from the stamp build-iso.sh writes into its export.
set -euo pipefail

repo="${1:?usage: source-version.sh REPO}"
repo="$(cd -- "$repo" && pwd -P)"
stamp="$repo/distro/pkg/eitr-desktop/source-version"

if [[ "$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" == "$repo" ]]; then
  printf '0.r%s.g%s\n' "$(git -C "$repo" rev-list --count HEAD)" "$(git -C "$repo" rev-parse --short=7 HEAD)"
elif [[ -f "$stamp" ]]; then
  version="$(<"$stamp")"
  [[ "$version" =~ ^0\.r[0-9]+\.g[0-9a-f]{7,}$ ]] || { printf 'Invalid version stamp: %s\n' "$stamp" >&2; exit 1; }
  printf '%s\n' "$version"
else
  printf '%s is neither a Git checkout nor a stamped export of Eitr.\n' "$repo" >&2
  exit 1
fi
