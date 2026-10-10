#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dirs=(Kvantum elephant fastfetch hypr kitty lockscreen nvim nwg-look quickshell swayosd themes walker xdg-desktop-portal xsettingsd)
config_files=(dolphinrc filetypesrc mimeapps.list)

if [[ ${EUID} -eq 0 ]]; then
  printf 'Run as the new desktop user, not root.\n' >&2
  exit 1
fi
if ! command -v pacman >/dev/null || ! command -v sudo >/dev/null; then
  printf 'This installer requires an installed Arch Linux system and sudo.\n' >&2
  exit 1
fi
if [[ ${1:-} == --check ]]; then
  if systemctl is-enabled --quiet NetworkManager.service 2>/dev/null; then
    printf 'NetworkManager is enabled. This desktop uses iwd/networkd; resolve that conflict first.\n' >&2
    exit 1
  fi
  for item in "${config_dirs[@]}" "${config_files[@]}"; do
    [[ -e "$repo_root/$item" ]] || { printf 'Missing source: %s\n' "$item" >&2; exit 1; }
    [[ ! -e "$HOME/.config/$item" ]] || { printf 'Already exists: %s\n' "$HOME/.config/$item" >&2; exit 1; }
  done
  if ! pacman -Si steam >/dev/null 2>&1; then
    printf 'Enable [multilib] in /etc/pacman.conf, run sudo pacman -Sy, then retry.\n' >&2
    exit 1
  fi
  bash "$repo_root/distro/hardware/detect.sh" >/dev/null
  [[ ! -e "$HOME/.config/theme/current" ]] || { printf 'Already exists: theme/current\n' >&2; exit 1; }
  printf 'Fresh-install target looks clear for %s. No changes made.\n' "$HOME"
  exit 0
fi
if [[ $# -ne 0 ]]; then
  printf 'Usage: %s [--check]\n' "$0" >&2
  exit 2
fi

bash "$0" --check
hardware_output="$(bash "$repo_root/distro/hardware/detect.sh")"
mapfile -t hardware_packages <<< "$hardware_output"
mapfile -t official < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$repo_root/distro/packages.txt")
mapfile -t apps < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$repo_root/distro/apps.txt")
mapfile -t aur < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$repo_root/distro/aur-packages.txt")
mapfile -t aur_apps < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$repo_root/distro/aur-apps.txt")

sudo pacman -Syu --needed -- "${hardware_packages[@]}" "${official[@]}" "${apps[@]}"
if ! command -v yay >/dev/null; then
  build_dir="$(mktemp -d)"
  trap 'rm -rf -- "$build_dir"' EXIT
  git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
  (cd "$build_dir/yay" && makepkg -si --noconfirm --options '!debug')
fi
yay -S --needed --mflags "--options !debug" -- "${aur[@]}" "${aur_apps[@]}"

bash "$repo_root/distro/install-development.sh"
# Use the managed Node runtime for the remaining npm-based setup.
export NVM_DIR="$HOME/.nvm"
set +u
source "$NVM_DIR/nvm.sh"
nvm use default
set -u

# Authentication is intentionally not copied from the backup.
if ! command -v claude >/dev/null; then
  claude_installer="$(mktemp)"
  curl -fsSL https://claude.ai/install.sh -o "$claude_installer"
  bash "$claude_installer"
  rm -f -- "$claude_installer"
fi
if ! command -v codex >/dev/null; then
  npm install --global --prefix "$HOME/.local" @openai/codex
fi

mkdir -p "$HOME/.config" "$HOME/.cache" "$HOME/.local/bin"
for item in "${config_dirs[@]}" "${config_files[@]}"; do
  cp -a -- "$repo_root/$item" "$HOME/.config/$item"
done
mkdir -p "$HOME/.config/systemd/user"
cp -a -- "$repo_root/systemd/user/." "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now nightlight-auto.timer
mkdir -p "$HOME/.config/theme/current" "$HOME/.config/hypr/themes"
cp -a -- "$repo_root/themes/catppuccin/." "$HOME/.config/theme/current/"
printf 'catppuccin\n' > "$HOME/.cache/current-theme"
wallpaper="$(find "$HOME/.config/theme/current/backgrounds" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n 1)"
if [[ -n "$wallpaper" ]]; then
  ln -s -- "$wallpaper" "$HOME/.cache/current-wallpaper-image"
  printf '%s\n' "$wallpaper" > "$HOME/.cache/current-wallpaper"
fi
if [[ -f "$HOME/.config/theme/current/hyprland.lua" ]]; then
  cp -- "$HOME/.config/theme/current/hyprland.lua" "$HOME/.config/hypr/themes/current.lua"
fi
if [[ -f "$HOME/.config/theme/current/theme-env.conf" ]]; then
  cp -- "$HOME/.config/theme/current/theme-env.conf" "$HOME/.config/hypr/theme-env.conf"
fi
touch "$HOME/.config/hypr/portable.mode"
ln -s -- ../../.config/walker/bin/walker "$HOME/.local/bin/walker"
for launcher in streaming-app netflix crunchyroll; do
  install -m 755 -- "$repo_root/HOME_FILES/.local/bin/$launcher" "$HOME/.local/bin/$launcher"
done
icon_source="$repo_root/HOME_FILES/.local/share/icons/hicolor"
icon_target="$HOME/.local/share/icons/hicolor"
mkdir -p "$icon_target"
cp -a -- "$icon_source/." "$icon_target/"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/share/dbus-1/services"
cp -a -- "$repo_root/HOME_FILES/.local/share/dbus-1/services/." "$HOME/.local/share/dbus-1/services/"
cp -a -- "$repo_root/HOME_FILES/.local/share/applications/." "$HOME/.local/share/applications/"
update-desktop-database "$HOME/.local/share/applications"

if [[ ! -e "$HOME/.zshrc" ]]; then
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  ln -s /usr/share/zsh/plugins/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  ln -s /usr/share/zsh/plugins/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  cp -- "$repo_root/HOME_FILES/.zshrc" "$HOME/.zshrc"
  cp -- "$repo_root/HOME_FILES/.p10k.zsh" "$HOME/.p10k.zsh"
  cp -- "$repo_root/HOME_FILES/.ls_colors" "$HOME/.ls_colors"
fi

sudo install -Dm644 "$repo_root/distro/network/20-ethernet.network" /etc/systemd/network/20-ethernet.network
sudo install -Dm644 "$repo_root/distro/network/20-wifi.network" /etc/systemd/network/20-wifi.network
if [[ ! -e /etc/resolv.conf && ! -L /etc/resolv.conf ]]; then
  sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

sudo python3 "$HOME/.config/quickshell/lockscreen/scripts/install-login.py"
sudo usermod -s /usr/bin/zsh "$(id -un)"
sudo systemctl enable iwd systemd-networkd systemd-resolved bluetooth sddm
printf '\nInstalled desktop files for %s. Reboot after reviewing network and SDDM setup.\n' "$USER"
printf 'Choose a theme in Walker after first login to generate the remaining app styles.\n'
