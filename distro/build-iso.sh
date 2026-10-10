#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile_source=/usr/share/archiso/configs/releng
build_root="$repo_root/distro/build"
profile="$build_root/profile"

if [[ ${EUID} -eq 0 ]]; then
  printf 'Run as a regular user with sudo access.\n' >&2
  exit 1
fi
if [[ ! -d "$profile_source" ]] || ! command -v mkarchiso >/dev/null; then
  printf 'Install archiso first: sudo pacman -S archiso\n' >&2
  exit 1
fi
if ! git -C "$repo_root" rev-parse --verify --quiet HEAD >/dev/null; then
  printf 'Build from a Git checkout with at least one commit.\n' >&2
  exit 1
fi
if [[ -n "$(git -C "$repo_root" status --porcelain --untracked-files=no)" ]]; then
  printf 'Warning: uncommitted changes are not included; the ISO uses committed HEAD.\n' >&2
fi
if [[ -e "$build_root" ]]; then
  printf 'Build directory exists: %s (remove it manually after checking mounts).\n' "$build_root" >&2
  exit 1
fi

mkdir -p "$profile" "$repo_root/distro/out"
cp -a "$profile_source/." "$profile/"
# Export committed files only, so ignored or untracked machine-local state
# (primary display, caches, notification settings) never reaches the image.
desktop_config="$profile/airootfs/opt/desktop-config"
mkdir -p "$desktop_config"
git -C "$repo_root" archive --format=tar HEAD | tar -x -C "$desktop_config"
sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$desktop_config/distro/packages.txt" >> "$profile/packages.x86_64"
sort -u -o "$profile/packages.x86_64" "$profile/packages.x86_64"
mkarchiso -v -w "$build_root/work" -o "$repo_root/distro/out" "$profile"
