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
if [[ -e "$build_root" ]]; then
  printf 'Build directory exists: %s (remove it manually after checking mounts).\n' "$build_root" >&2
  exit 1
fi

mkdir -p "$profile" "$repo_root/distro/out"
cp -a "$profile_source/." "$profile/"
cat "$repo_root/distro/packages.txt" >> "$profile/packages.x86_64"
sort -u -o "$profile/packages.x86_64" "$profile/packages.x86_64"
mkdir -p "$profile/airootfs/opt/desktop-config"
rsync -a --exclude=.git --exclude=distro/build --exclude=distro/out \
  "$repo_root/" "$profile/airootfs/opt/desktop-config/"
mkarchiso -v -w "$build_root/work" -o "$repo_root/distro/out" "$profile"
