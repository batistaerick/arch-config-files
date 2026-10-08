# Arch desktop distribution scaffold

This repository contains the complete desktop configuration and a first-pass
installation recipe. It is not yet a tested, self-contained distribution.
`build-iso.sh` creates an Arch **installer** ISO from the stock `releng` profile;
the graphical desktop and AUR packages are installed on the target system by
`install.sh`. The live ISO is not a preinstalled graphical session.

## What is included

- `packages.txt`: official Arch packages for Hyprland, Quickshell, Walker's
  dependencies, theme switching, audio, networking, capture tools, fonts,
  LazyVim, AWS CLI, Docker, and the terminal.
- `apps.txt`: the remaining general applications from the current installation.
  It includes Steam and other optional apps on purpose, for later review.
- `aur-packages.txt` and `aur-apps.txt`: AUR desktop and application packages,
  including Walker, Elephant, VS Code, 1Password, and Chrome.
- `hardware/`: detects CPU vendor and PCI display-controller IDs, then installs
  matching CPU microcode and 64-/32-bit GPU drivers. AMD and Intel use Mesa and
  their Vulkan drivers. Virtual GPUs use software Vulkan. NVIDIA needs an
  explicit driver choice because older cards require a different driver.
- Steam, GameMode, Gamescope, MangoHud, 32-bit graphics libraries, and
  `lib32-systemd` for Steam networking with systemd-networkd.
- FFmpeg, Qt Multimedia's FFmpeg backend, and GStreamer with base/good/bad/
  ugly/libav plugins for common audio and video formats, including MP4.
- Repository config directories: Quickshell bar/lockscreen, Hyprland, Walker,
  Elephant, themes and wallpapers, Neovim/LazyVim, notifications, and app styles.
- `HOME_FILES`: Zsh, Powerlevel10k, terminal colors and the Walker launcher link.
  The installer does not copy credentials or account state.

## Install on a new machine

1. Install a supported x86_64 Arch system with a normal user and sudo access.
   Choose partitioning, encryption, boot loader, locale, timezone and user name
   during the normal Arch install. This repo does not make those decisions or
   format disks. Do not run the installer on an existing configured desktop.
2. Enable `[multilib]` in `/etc/pacman.conf` and refresh pacman. Steam and
   `lib32-*` packages require it.
3. Clone this repository, run `bash distro/install.sh --check`, then run
   `bash distro/install.sh` as the new **non-root** user. It refuses to replace
   config paths that already exist, and does not copy browser, Wi-Fi, SSH, AI,
   or 1Password credentials. The installer downloads official packages,
   builds `yay` from AUR, installs AUR apps, installs Claude Code through its
   official installer, and installs Codex CLI via npm. Audit the manifests and
   upstream installers before running them.
   On a supported NVIDIA Turing-or-newer system, review the GPU model first and
   use `DISTRO_NVIDIA_DRIVER=open bash distro/install.sh --check` followed by
   `DISTRO_NVIDIA_DRIVER=open bash distro/install.sh`. On a hybrid machine where
   only the Intel/AMD GPU should be configured, use `DISTRO_NVIDIA_DRIVER=skip`.
   Older NVIDIA cards need manual driver selection; the installer intentionally
   stops instead of guessing. If no supported GPU is detected, it also stops.
4. Review `/etc/systemd/network` and `/etc/resolv.conf`, then reboot. The
   installer enables iwd, networkd, resolved, Bluetooth, and SDDM for next
   boot; it does not restart those system services in the current session. The
   user nightlight timer is enabled immediately. It configures
   Zsh as the login shell and installs the selected root-owned SDDM design.
5. Sign into apps yourself. Open Walker and apply a theme once to generate
   all application-specific styles. LazyVim installs plugins at first Neovim
   launch. Check the SDDM theme on a spare/test system before using it as your
   only login path; the lockscreen README has recovery instructions.

The desktop includes a generic monitor mode marker (`hypr/portable.mode`) on
new installs. It uses `preferred,auto` rather than the original machine's
output names and resolutions. The backup's original monitor layout remains
unchanged unless this marker is present.

## Build installer ISO

Install `archiso` on an Arch build machine, then run `bash distro/build-iso.sh`.
The ISO lands in `distro/out/`; temporary profile/work files stay under
`distro/build/`. The script refuses to reuse an existing build directory to
avoid deleting mounted work trees. It copies this repository into
`/opt/desktop-config` on the live image, excluding Git history and build output.
Boot the image, install Arch as usual, then run the included installer on the
new system. Keep the image off public mirrors until it has been tested in a VM
and licensing for bundled wallpaper/lockscreen assets has been reviewed.

## Before calling it a distro

- Test the ISO boot and post-install flow on UEFI and BIOS VMs, then on real
  AMD, Intel and NVIDIA systems; verify networking and graphics separately.
- Add guided encryption/partitioning and a branded live desktop only after the
  base install is repeatable. AUR packages need a maintained package repository
  to be included directly in the live ISO.
- Audit asset licenses, package updates, security defaults, and the first-run
  experience. Never bundle tokens, logins, saved networks or device identifiers.

Working name ideas: **Vela** (navigation), **Mica** (layered visual system), or
**Luma** (light and color). No name or branding is baked into the scripts yet.

References: [Archiso](https://wiki.archlinux.org/title/Archiso),
[GPU drivers](https://wiki.archlinux.org/title/Graphics_processing_unit),
[Steam](https://wiki.archlinux.org/title/Steam),
[GStreamer](https://wiki.archlinux.org/title/GStreamer),
[NVIDIA](https://wiki.archlinux.org/title/NVIDIA),
[Hyprland monitor rules](https://wiki.hypr.land/configuring/core/monitors/),
[Claude Code setup](https://code.claude.com/docs/en/setup),
[Codex CLI](https://developers.openai.com/codex/cli/).
