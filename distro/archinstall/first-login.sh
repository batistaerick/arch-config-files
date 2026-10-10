#!/usr/bin/env bash
# Offered on the first console login after eitr-guided-install, until the Eitr
# desktop installer has completed once. Safe to run again by hand.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/eitr"
done_marker="$state_dir/guided-install-complete"
rerun="bash $repo_root/distro/archinstall/first-login.sh"

[[ ! -e "$done_marker" ]] || exit 0

printf '\nWelcome to Eitr. The base system is ready; the desktop is not installed yet.\n'
if ! getent ahosts archlinux.org >/dev/null 2>&1; then
  printf 'No internet connection was found. Ethernet connects automatically; for Wi-Fi:\n'
  printf '  iwctl station list\n  iwctl station <device> connect <network>\n'
  printf 'Then run: %s\n\n' "$rerun"
  exit 0
fi
printf 'The installer downloads the desktop packages, builds AUR packages and the\n'
printf 'eitr-desktop package, and asks for your sudo password. It never overwrites\n'
printf 'existing files in your home.\n'
read -r -p 'Install the Eitr desktop now? [y/N] ' answer
if [[ ! "$answer" =~ ^[Yy] ]]; then
  printf 'Skipped. Run it later with: %s\n\n' "$rerun"
  exit 0
fi
if ! bash "$repo_root/distro/install.sh" --check; then
  printf '\nThe pre-install check stopped. Fix the reported issue, then run: %s\n' "$rerun" >&2
  printf 'NVIDIA systems need a driver choice first, for example: DISTRO_NVIDIA_DRIVER=open %s\n' "$rerun" >&2
  printf 'See %s/distro/README.md.\n\n' "$repo_root" >&2
  exit 1
fi
bash "$repo_root/distro/install.sh"
mkdir -p -- "$state_dir"
touch -- "$done_marker"
printf '\nEitr is installed. Reboot to start the desktop: sudo systemctl reboot\n'
