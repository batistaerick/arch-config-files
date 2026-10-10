#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_dirs=(Kvantum elephant fastfetch hypr kitty lockscreen nvim nwg-look quickshell swayosd themes walker xdg-desktop-portal)
config_files=(dolphinrc filetypesrc mimeapps.list)
shell_files=(.zshrc .p10k.zsh .ls_colors)
# Paths this installer created are recorded here, so a rerun after a partial
# failure skips them instead of mistaking them for pre-existing user configs.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/eitr"
install_record="$state_dir/installed-paths"

cleanup_paths=()
cleanup() {
  if (( ${#cleanup_paths[@]} )); then rm -rf -- "${cleanup_paths[@]}"; fi
}
trap cleanup EXIT

die() { printf '%s\n' "$*" >&2; exit 1; }
manifest() { sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$1"; }

is_recorded() { [[ -f "$install_record" ]] && grep -Fxq -- "$1" "$install_record"; }
record() {
  is_recorded "$1" && return
  mkdir -p -- "$state_dir"
  printf '%s\n' "$1" >> "$install_record"
}

same_content() {
  if [[ -L "$1" || -L "$2" ]]; then
    [[ -L "$1" && -L "$2" && "$(readlink -- "$1")" == "$(readlink -- "$2")" ]]
  else
    diff -rq -- "$1" "$2" >/dev/null 2>&1
  fi
}

# Prints clear, installed, or conflict for one source -> target pair.
target_state() {
  if [[ ! -e "$2" && ! -L "$2" ]]; then printf 'clear\n'
  elif is_recorded "${2#"$HOME"/}"; then printf 'installed\n'
  elif same_content "$1" "$2"; then printf 'installed\n'
  else printf 'conflict\n'
  fi
}

# Copies through a staging path so an interrupted copy never leaves a partial
# target that a rerun would treat as a user config.
install_path() {
  local source="$1" target="$2" parent staging
  case "$(target_state "$source" "$target")" in
    installed) record "${target#"$HOME"/}"; return ;;
    conflict) die "Refusing to overwrite existing user file: $target" ;;
  esac
  parent="$(dirname -- "$target")"
  mkdir -p -- "$parent"
  staging="$(mktemp -d -- "$parent/.eitr-install.XXXXXX")"
  cleanup_paths+=("$staging")
  cp -a -- "$source" "$staging/item"
  mv -T -- "$staging/item" "$target"
  record "${target#"$HOME"/}"
}

clone_once() {
  local url="$1" target="$2" parent staging
  if [[ -d "$target/.git" ]]; then return; fi
  [[ ! -e "$target" ]] || die "Exists but is not a Git checkout: $target"
  parent="$(dirname -- "$target")"
  mkdir -p -- "$parent"
  staging="$(mktemp -d -- "$parent/.eitr-clone.XXXXXX")"
  cleanup_paths+=("$staging")
  git clone --depth 1 -- "$url" "$staging/item"
  mv -T -- "$staging/item" "$target"
}

# Oh My Zsh loads custom plugins from <name>/<name>.plugin.zsh, while Arch
# installs these plugins as <name>.zsh, so a small loader bridges the names.
zsh_plugin_loader() {
  local name="$1" loader="$HOME/.oh-my-zsh/custom/plugins/$1/$1.plugin.zsh"
  [[ ! -e "$loader" ]] || return 0
  mkdir -p -- "$(dirname -- "$loader")"
  printf 'source /usr/share/zsh/plugins/%s/%s.zsh\n' "$name" "$name" > "$loader"
}

sources=()
targets=()
add_target() { sources+=("$1"); targets+=("$2"); }
add_tree() {
  local source_root="$1" target_root="$2" file
  [[ -d "$source_root" ]] || return 0
  while IFS= read -r -d '' file; do
    add_target "$file" "$target_root/${file#"$source_root"/}"
  done < <(find "$source_root" \( -type f -o -type l \) -print0 | sort -z)
}
collect_targets() {
  local item
  for item in "${config_dirs[@]}" "${config_files[@]}"; do
    add_target "$repo_root/$item" "$HOME/.config/$item"
  done
  add_target "$repo_root/themes/catppuccin" "$HOME/.config/theme/current"
  add_tree "$repo_root/systemd/user" "$HOME/.config/systemd/user"
  add_tree "$repo_root/HOME_FILES/.local" "$HOME/.local"
}

shell_setup_clear() {
  local name
  for name in "${shell_files[@]}"; do
    [[ "$(target_state "$repo_root/HOME_FILES/$name" "$HOME/$name")" != conflict ]] || return 1
  done
}

validate_manifests() {
  local -a official=("$@") missing=() aur=() not_found=()
  local package found
  if ! pacman -Si -- "${official[@]}" >/dev/null 2>&1; then
    # pacman -Si does not resolve virtual packages; -Sp resolves like -S does.
    for package in "${official[@]}"; do
      pacman -Si -- "$package" >/dev/null 2>&1 ||
        pacman -Sp --print-format '%n' -- "$package" >/dev/null 2>&1 ||
        missing+=("$package")
    done
  fi
  if (( ${#missing[@]} )); then
    die "Official manifest entries not found in enabled repositories: ${missing[*]}"
  fi
  mapfile -t aur < <(manifest "$repo_root/distro/aur-packages.txt"; manifest "$repo_root/distro/aur-apps.txt")
  if ! command -v yay >/dev/null; then
    printf 'yay is not installed yet; AUR manifest names were not validated.\n'
    return
  fi
  found="$(yay -Si -- "${aur[@]}" 2>/dev/null | sed -n 's/^Name[[:space:]]*:[[:space:]]*//p')" || true
  for package in "${aur[@]}"; do
    grep -Fxq -- "$package" <<< "$found" || not_found+=("$package")
  done
  if (( ${#not_found[@]} )); then
    die "AUR manifest entries not found: ${not_found[*]}"
  fi
}

if [[ ${EUID} -eq 0 ]]; then
  die 'Run as the new desktop user, not root.'
fi
if ! command -v pacman >/dev/null || ! command -v sudo >/dev/null; then
  die 'This installer requires an installed Arch Linux system and sudo.'
fi
if [[ ${1:-} == --check ]]; then
  if systemctl is-enabled --quiet NetworkManager.service 2>/dev/null; then
    die 'NetworkManager is enabled. This desktop uses iwd/networkd; resolve that conflict first.'
  fi
  if [[ $(findmnt -n -o FSTYPE /) != btrfs ]]; then
    die 'Eitr snapshot-protected updates require a Btrfs root. Use Btrfs on the fresh target.'
  fi
  for item in "${config_dirs[@]}" "${config_files[@]}"; do
    [[ -e "$repo_root/$item" ]] || die "Missing source: $item"
  done
  collect_targets
  conflicts=()
  installed=0
  for index in "${!targets[@]}"; do
    case "$(target_state "${sources[$index]}" "${targets[$index]}")" in
      conflict) conflicts+=("${targets[$index]}") ;;
      installed) installed=$((installed + 1)) ;;
    esac
  done
  if (( ${#conflicts[@]} )); then
    printf 'Existing user config would be overwritten; move it aside first:\n' >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    exit 1
  fi
  (( installed == 0 )) || printf 'Already installed by this installer (will skip): %d paths\n' "$installed"
  shell_setup_clear || printf 'Existing Zsh files found; Zsh/Oh My Zsh setup will be skipped.\n'
  if ! pacman -Si steam >/dev/null 2>&1; then
    die 'Enable [multilib] in /etc/pacman.conf, run sudo pacman -Sy, then retry.'
  fi
  hardware_output="$(bash "$repo_root/distro/hardware/detect.sh")"
  mapfile -t hardware_packages <<< "$hardware_output"
  mapfile -t official < <(manifest "$repo_root/distro/packages.txt"; manifest "$repo_root/distro/apps.txt")
  validate_manifests "${hardware_packages[@]}" "${official[@]}"
  printf 'Fresh-install target looks clear for %s. No changes made.\n' "$HOME"
  exit 0
fi
if [[ $# -ne 0 ]]; then
  printf 'Usage: %s [--check]\n' "$0" >&2
  exit 2
fi

bash "$0" --check
collect_targets
hardware_output="$(bash "$repo_root/distro/hardware/detect.sh")"
mapfile -t hardware_packages <<< "$hardware_output"
mapfile -t official < <(manifest "$repo_root/distro/packages.txt")
mapfile -t apps < <(manifest "$repo_root/distro/apps.txt")
mapfile -t aur < <(manifest "$repo_root/distro/aur-packages.txt")
mapfile -t aur_apps < <(manifest "$repo_root/distro/aur-apps.txt")

sudo pacman -Syu --needed -- "${hardware_packages[@]}" "${official[@]}" "${apps[@]}"
if ! command -v yay >/dev/null; then
  build_dir="$(mktemp -d)"
  cleanup_paths+=("$build_dir")
  git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
  (cd "$build_dir/yay" && makepkg -si --noconfirm --options '!debug')
fi
yay -S --needed --mflags "--options !debug" -- "${aur[@]}" "${aur_apps[@]}"

# Development runtimes and AI CLIs are installed only by explicit menu selection.
# These are installer-owned reference copies, refreshed on every run.
mkdir -p "$HOME/.local/share/eitr"
install -m 644 "$repo_root/distro/software.json" "$HOME/.local/share/eitr/software.json"
install -m 644 "$repo_root/distro/installers.json" "$HOME/.local/share/eitr/installers.json"
install -m 644 "$repo_root/distro/RECOVERY.md" "$HOME/.local/share/eitr/RECOVERY.md"
sudo install -Dm755 "$repo_root/distro/system/eitr-system.py" /usr/local/lib/eitr/eitr-system
sudo /usr/local/lib/eitr/eitr-system snapshots-setup
sudo install -Dm644 "$repo_root/distro/system-update-policy.conf" /etc/eitr/system-update-policy.conf

mkdir -p "$HOME/.config" "$HOME/.cache" "$HOME/.local/bin"
for index in "${!targets[@]}"; do
  install_path "${sources[$index]}" "${targets[$index]}"
done

if ! is_recorded step:portable-mode; then
  touch "$HOME/.config/hypr/portable.mode"
  record step:portable-mode
fi
[[ -e "$HOME/.cache/current-theme" ]] || printf 'catppuccin\n' > "$HOME/.cache/current-theme"
if [[ ! -e "$HOME/.cache/current-wallpaper-image" && ! -L "$HOME/.cache/current-wallpaper-image" ]]; then
  wallpaper="$(find "$HOME/.config/theme/current/backgrounds" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n 1)"
  if [[ -n "$wallpaper" ]]; then
    ln -s -- "$wallpaper" "$HOME/.cache/current-wallpaper-image"
    printf '%s\n' "$wallpaper" > "$HOME/.cache/current-wallpaper"
  fi
fi
# Derived from whichever theme is current, so reruns stay consistent with it.
mkdir -p "$HOME/.config/hypr/themes"
if [[ -f "$HOME/.config/theme/current/hyprland.lua" ]]; then
  cp -- "$HOME/.config/theme/current/hyprland.lua" "$HOME/.config/hypr/themes/current.lua"
fi
if [[ -f "$HOME/.config/theme/current/theme-env.conf" ]]; then
  cp -- "$HOME/.config/theme/current/theme-env.conf" "$HOME/.config/hypr/theme-env.conf"
fi
if command -v gtk-update-icon-cache >/dev/null; then
  gtk-update-icon-cache -f -t -q "$HOME/.local/share/icons/hicolor"
fi
update-desktop-database "$HOME/.local/share/applications"

if systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now nightlight-auto.timer
else
  printf 'No systemd user session is available (for example over su or a bare TTY).\n' >&2
  printf 'After first graphical login, run: systemctl --user enable --now nightlight-auto.timer\n' >&2
fi

if shell_setup_clear; then
  clone_once https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  clone_once https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  zsh_plugin_loader zsh-autosuggestions
  zsh_plugin_loader zsh-syntax-highlighting
  for name in "${shell_files[@]}"; do
    install_path "$repo_root/HOME_FILES/$name" "$HOME/$name"
  done
else
  printf 'Existing Zsh files found; skipped Oh My Zsh and shell file setup.\n' >&2
fi

sudo install -Dm644 "$repo_root/distro/network/20-ethernet.network" /etc/systemd/network/20-ethernet.network
sudo install -Dm644 "$repo_root/distro/network/20-wifi.network" /etc/systemd/network/20-wifi.network
if [[ ! -e /etc/resolv.conf && ! -L /etc/resolv.conf ]]; then
  sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
elif [[ ! -L /etc/resolv.conf ]]; then
  printf 'WARNING: /etc/resolv.conf is a regular file, so systemd-resolved DNS will not be used.\n' >&2
  printf 'Review it, then run: sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf\n' >&2
fi

sudo python3 "$HOME/.config/quickshell/lockscreen/scripts/install-login.py"
sudo usermod -s /usr/bin/zsh "$(id -un)"
sudo systemctl enable iwd systemd-networkd systemd-resolved bluetooth sddm
flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive --or-update GeForceNOW com.nvidia.geforcenow
printf '\nInstalled desktop files for %s. Reboot after reviewing network and SDDM setup.\n' "$USER"
printf 'Choose a theme in Walker after first login to generate the remaining app styles.\n'
printf 'Docker and cronie are installed but not enabled. Enable them only if needed:\n'
printf '  sudo systemctl enable --now docker.service cronie.service\n'
printf '  sudo usermod -aG docker %s   # docker group membership is root-equivalent\n' "$(id -un)"
