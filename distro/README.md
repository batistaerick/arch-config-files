# Eitr

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
  explicit driver choice because older cards require a different driver. If a
  non-default kernel (for example `linux-lts` or `linux-zen`) is installed,
  `nvidia-open-dkms` and headers for every installed kernel replace `nvidia-open`.
- Steam, GameMode, Gamescope, MangoHud, 32-bit graphics libraries, and
  `lib32-systemd` for Steam networking with systemd-networkd.
- FFmpeg, Qt Multimedia's FFmpeg backend, and GStreamer with base/good/bad/
  ugly/libav plugins for common audio and video formats, including MP4.
- Repository config directories: Quickshell bar/lockscreen, Hyprland, Walker,
  Elephant, themes and wallpapers, Neovim/LazyVim, and app styles. Quickshell
  owns notifications.
- `HOME_FILES`: files installed elsewhere under `$HOME`: Zsh, Powerlevel10k and
  `LS_COLORS`; `~/.local/bin` launchers (the Walker wrapper link and streaming
  apps); desktop entries, app icons, and a D-Bus activation file. That file
  starts Quickshell for `org.freedesktop.Notifications`. It is deliberately
  named `org.erikreider.swaync.service` so it also shadows SwayNC's
  package file of the same name if SwayNC is ever installed.
  The installer does not copy credentials or account state.
- Yay is built from AUR if absent. AUR builds disable detached debug packages;
  SwayNC, CEF, and Walker/Mongosh debug packages are deliberately excluded.
  Quickshell owns notifications.
- Development languages, frameworks, JavaScript tools and AI CLIs are optional:
  Walker → Install → Development Languages / JavaScript Tools / AI CLIs.
  `software.json` records optional package recipes. Java uses SDKMAN
  with the latest available Temurin LTS and Maven; Node uses NVM's latest LTS.
  Python remains a system dependency for desktop helpers; uv-managed development
  Python is optional. Rust uses rustup; Ruby/Rails uses mise; PHP/Composer,
  Elixir/Erlang and .NET use Arch packages. No managers, development SDKs or AI
  CLIs are bootstrapped by default. Dependencies may still pull their own runtimes.
  Existing SDKs and account state on the owner's desktop are not uninstalled.
- Lazygit and Lazydocker are included from Arch's official repositories. Gaming
  includes Steam and the official NVIDIA GeForce NOW user Flatpak, installed
  from NVIDIA's signed remote. It requires a separate account and compatible
  hardware/network; it does not install NVIDIA GPU drivers on AMD/Intel systems.
- Snapper creates recovery points only through System Update on distro installs.
  Advanced Pacman/AUR updates intentionally do not request snapshots. Supported fresh installs require Btrfs
  root with `/usr`, `/etc`, and `/var/lib/pacman` inside that root subvolume.
  Boot/EFI archives are separate; see [recovery instructions](RECOVERY.md).
- Security offers password changes, fingerprint enrollment, FIDO2-key enrollment,
  and separately confirmed optional authentication policy. Password fallback is
  preserved. Hardware support and real authentication still require testing.
- Direct helper dependencies include `lm_sensors` for hardware temperatures,
  `qrencode` for Wi-Fi sharing, and `desktop-file-utils` for launcher registration.
- Bruno, ngrok, kubectl, Helm, Minikube, printing packages (CUPS, HPLIP and
  System Config Printer), and Wacom input support are excluded from defaults.
  Existing installations are not uninstalled by changes to these manifests.

## Install on a new machine

For Apple Silicon Macs, follow the [temporary VM testing guide](MAC-VM-TESTING.md).
It uses x86_64 emulation, not a supported ARM port. Remove that guide and this
link once installation and release testing is complete.

1. Install a supported x86_64 Arch system with a Btrfs root, a normal user and sudo access.
   Choose partitioning, encryption, boot loader, locale, timezone and user name
   during the normal Arch install. This repo does not make those decisions or
   format disks. Do not run the installer on an existing configured desktop.
2. Enable `[multilib]` in `/etc/pacman.conf` and refresh pacman. Steam and
   `lib32-*` packages require it.
3. Clone this repository, run `bash distro/install.sh --check`, then run
   `bash distro/install.sh` as the new **non-root** user. `--check` lists every
   existing config, `~/.local` file, systemd user unit, or theme path that differs
   from this repo and stops; move those aside first. It never overwrites them.
   Paths the installer created are recorded in `~/.local/state/eitr/installed-paths`,
   so after a partial failure you can fix the cause and rerun it: finished steps
   are skipped. Existing Zsh files skip only the Oh My Zsh setup. `--check` also
   verifies that every manifest entry exists in the enabled repositories (AUR
   names once `yay` is available). It does not copy browser, Wi-Fi, SSH, AI,
   or 1Password credentials. The installer downloads official packages,
   builds `yay` from AUR, installs AUR apps, configures Snapper and System Update protection,
   and installs GeForce NOW. Development SDKs and AI CLIs are selected later
   from Walker rather than installed automatically. Audit the manifests and
   upstream installers before running them.
   On a supported NVIDIA Turing-or-newer system, review the GPU model first and
   use `DISTRO_NVIDIA_DRIVER=open bash distro/install.sh --check` followed by
   `DISTRO_NVIDIA_DRIVER=open bash distro/install.sh`. On a hybrid machine where
   only the Intel/AMD GPU should be configured, use `DISTRO_NVIDIA_DRIVER=skip`.
   Older NVIDIA cards need manual driver selection; the installer intentionally
   stops instead of guessing. If no supported GPU is detected, it also stops.
4. Review `/etc/systemd/network` and `/etc/resolv.conf`, then reboot. The
   installer enables iwd, networkd, resolved, Bluetooth, and SDDM for next
   boot; it does not restart those system services in the current session. If
   `/etc/resolv.conf` is a regular file, it warns instead of replacing it. The
   user nightlight timer is enabled immediately when a systemd user session
   exists; otherwise the installer prints the command to run after login. It
   configures Zsh as the login shell and installs the selected root-owned SDDM
   design. Docker and cronie are installed but not enabled; the installer prints
   the commands to enable them. Joining the `docker` group is root-equivalent.
5. Sign into apps yourself. Open Walker and apply a theme once to generate
   all application-specific styles. LazyVim installs plugins at first Neovim
   launch. Check the SDDM theme on a spare/test system before using it as your
   only login path; the lockscreen README has recovery instructions.

The desktop includes a generic monitor mode marker (`hypr/portable.mode`) on
new installs. Hyprland reads each connected display's preferred EDID mode
(resolution and refresh rate) at login and positions outputs automatically,
rather than copying the original machine's output names and resolutions.
`preferred` is the safe default, not a guarantee of the highest advertised Hz;
the Display panel reports the active mode. The backup's original monitor layout
remains unchanged unless this marker is present.

## Build installer ISO

Install `archiso` on an Arch build machine, then run `bash distro/build-iso.sh`.
The ISO lands in `distro/out/`; temporary profile/work files stay under
`distro/build/`. The script refuses to reuse an existing build directory to
avoid deleting mounted work trees. It exports the committed `HEAD` (via
`git archive`) into `/opt/desktop-config` on the live image, so uncommitted,
untracked, and ignored machine-local files are excluded. Boot the image and
install Arch as usual. Before rebooting, copy the repo into the new user's home,
for example `cp -a /opt/desktop-config /mnt/home/<user>/eitr` followed by
`arch-chroot /mnt chown -R <user>: /home/<user>/eitr`. Then log in as that user on
the new system and run `bash ~/eitr/distro/install.sh --check`. Keep the image off public mirrors until it has been tested in a VM
and licensing for bundled wallpaper/lockscreen assets has been reviewed.

## Before calling it a distro

- Test the ISO boot and post-install flow on UEFI and BIOS VMs, then on real
  AMD, Intel and NVIDIA systems; verify networking and graphics separately.
- The development bootstrap has mock tests, not a completed fresh-machine
  installation test. This recipe is not a byte-for-byte system clone: fan-control
  services and other hardware-specific tuning still need target-specific review.
- Add guided encryption/partitioning and a branded live desktop only after the
  base install is repeatable. AUR packages need a maintained package repository
  to be included directly in the live ISO.
- Audit asset licenses, package updates, security defaults, and the first-run
  experience. Never bundle tokens, logins, saved networks or device identifiers.

The official project name is **Eitr**; the GitHub repository is
[`batistaerick/eitr`](https://github.com/batistaerick/eitr).
Installer paths remain generic. The selected Rune Liquid logo is in `branding/`;
release branding and fresh-install validation remain in progress.

References: [Archiso](https://wiki.archlinux.org/title/Archiso),
[GPU drivers](https://wiki.archlinux.org/title/Graphics_processing_unit),
[Steam](https://wiki.archlinux.org/title/Steam),
[GStreamer](https://wiki.archlinux.org/title/GStreamer),
[NVIDIA](https://wiki.archlinux.org/title/NVIDIA),
[Hyprland monitor rules](https://wiki.hypr.land/configuring/core/monitors/),
[Claude Code setup](https://code.claude.com/docs/en/setup),
[Codex CLI](https://developers.openai.com/codex/cli/).
Development bootstrap references: [NVM](https://github.com/nvm-sh/nvm),
[SDKMAN installation and CI options](https://sdkman.io/install/).

## Existing desktop: privileged integration

Config/menu changes do not automatically install packages, change PAM, or
configure root snapshots on the owner's running desktop. To enable the root
integration on a reviewed supported Btrfs installation, install the dependencies
and root-owned helper and System Update policy deliberately:

```sh
sudo pacman -S --needed snapper fprintd pam-u2f flatpak lazygit lazydocker
sudo install -Dm755 distro/system/eitr-system.py /usr/local/lib/eitr/eitr-system
sudo /usr/local/lib/eitr/eitr-system snapshots-setup
sudo install -Dm644 distro/system-update-policy.conf /etc/eitr/system-update-policy.conf
```

Run from this repo, as the normal desktop user. If setup rejects the layout,
stop; do not bypass its protection. The initial dependency bootstrap above is
not protected before that policy is enabled. Thereafter, System Update requires
successful snapshot creation before upgrading. Advanced updates are unprotected.
Existing desktops without the policy still update normally.
If you installed the old Eitr hooks manually, remove only
`/etc/pacman.d/hooks/05-eitr-snapshot-pre.hook` and
`/etc/pacman.d/hooks/95-eitr-snapshot-post.hook` to adopt this new policy.
Never sudo a helper under a user-writable config path.
Do not restart SDDM or test authentication without a recovery console available.
