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
  A system battery (`BAT*`) or laptop DMI chassis adds `laptop.txt`
  (`power-profiles-daemon`); the installer enables it only when installed.
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
- `bootloader/`: optional Snapper snapshot boot entries. `setup.sh` detects
  GRUB (`grub-btrfs`) or Limine (AUR `limine-snapper-sync`), installs that
  loader's manifest and runs `eitr-system snapshots-boot-setup` only after typed
  confirmation. systemd-boot cannot boot snapshots and is refused.
- Security offers password changes, fingerprint enrollment, FIDO2-key enrollment,
  and separately confirmed optional authentication policy. Password fallback is
  preserved. Each policy change backs up the PAM files and can be undone with
  `eitr-system auth-restore`; see [recovery instructions](RECOVERY.md). Hardware support and real authentication still require testing.
  Security → TPM Disk Unlock adds (or removes) a PCR 7 TPM2 slot on a LUKS2
  root after a typed confirmation, offering a recovery key first and keeping the
  passphrase. It refuses the busybox `encrypt` initramfs hook and never runs
  from the installer.
  Secure Boot is documentation only: [SECURE-BOOT.md](SECURE-BOOT.md) (sbctl,
  Option ROM risks, GRUB/Limine snapshot entries, undo), linked from Security.
- Laptops: Walker → System → Battery Charge Limit runs
  `eitr-system battery-limit <60-100|off>`, which writes
  `charge_control_end_threshold` and installs `eitr-battery-limit.service` to
  restore it at boot and after resume. Desktops have no threshold and are refused.
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
   during the normal Arch install, or let the ISO's
   [guided install](#guided-install) erase one disk with Eitr's encrypted layout
   (it then offers steps 2 and 3 at first login). `install.sh` itself never
   formats disks. Do not run the installer on an existing configured desktop.
2. Enable `[multilib]` in `/etc/pacman.conf` and refresh pacman. Steam and
   `lib32-*` packages require it.
3. Install the preflight prerequisites with
   `sudo pacman -Syu --needed git base-devel python`. Clone this repository,
   run `bash distro/install.sh --check`, then run
   `bash distro/install.sh` as the new **non-root** user. `--check` lists every
   existing config, `~/.local` file, systemd user unit, or theme path that differs
   from this repo and stops; move those aside first. It never overwrites them.
   Paths the installer created are recorded in `~/.local/state/eitr/installed-paths`,
   so after a partial failure you can fix the cause and rerun it: finished steps
   are skipped. Existing Zsh files skip only the Oh My Zsh setup. `--check` also
   verifies that every manifest entry exists in the enabled repositories (AUR
   names once `yay` is available). It does not copy browser, Wi-Fi, SSH, AI,
   or 1Password credentials. The installer downloads official packages,
   builds `yay` from AUR, installs AUR apps, builds and installs the
   `eitr-desktop` package (see [Desktop package](#desktop-package-and-config-updates))
   and seeds your home from it with `eitr-config seed`, configures Snapper and System Update protection,
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

### Monitors and machine-local overrides

The shared Hyprland config is generic: it reads each connected display's
preferred EDID mode (resolution and refresh rate) at login and positions outputs
automatically, rather than copying the original machine's output names and
resolutions. `preferred` is the safe default, not a guarantee of the highest
advertised Hz; the Display panel reports the active mode. The bar starts on the
largest active display until you pick another one in the Display panel.

Machine-specific settings live in two optional, Git-ignored files:

- `~/.config/hypr/local.lua`: a Lua chunk that runs after `hyprland.lua` and
  uses the same `hl.*` calls (`hl.monitor`, `hl.workspace_rule`, `hl.device`,
  `hl.env`, `hl.config`, ...). Its calls apply only if the whole file runs
  without error; otherwise the generic layout stays and a notification shows
  the error.
- `~/.config/hypr/preferred-outputs`: output names, one per line, that the bar
  prefers before the largest display. A choice saved from the Display panel
  (`~/.config/hypr/primary-display`) still wins.

`hypr/local.lua.example` and `hypr/preferred-outputs.example` hold the original
machine's layout (fixed modes, HDR, positions, workspace-to-monitor rules,
mouse tuning, and the HDMI-A-1/DP-3 bar preference).

**Owner machine migration:** older checkouts applied that layout unless
`hypr/portable.mode` existed; the marker is no longer read. On the original
machine, restore the layout once with:

```sh
cp hypr/local.lua.example ~/.config/hypr/local.lua
cp hypr/preferred-outputs.example ~/.config/hypr/preferred-outputs
hyprctl reload
```

A leftover `~/.config/hypr/portable.mode` on other machines is harmless and can
be deleted.

## Desktop package and config updates

`pkg/eitr-desktop/PKGBUILD` packages the desktop from this tree. A Git checkout
contributes only its committed `HEAD` (via `git archive`), so uncommitted and
ignored machine-local files never ship; the version is `0.r<commits>.g<hash>`.
It installs:

- default configs under `/usr/share/eitr/config/` (the directories in
  `user-defaults.json`) and `HOME_FILES` defaults under `/usr/share/eitr/home/`;
- `software.json`, `installers.json`, `RECOVERY.md` and
  `system-update-policy.conf` in `/usr/share/eitr/`;
- the root helper as `/usr/lib/eitr/eitr-system` (earlier manual installs used
  `/usr/local/lib/eitr/eitr-system`, which callers still accept as a fallback);
- `eitr-config` in `/usr/bin` and the systemd user units in `/usr/lib/systemd/user`.

Its dependencies are the official `packages.txt` entries except `base`,
`base-devel`, `linux` and `linux-firmware`, which stay system choices (so
`linux-lts`/`linux-zen` systems are valid). `apps.txt`, hardware drivers and AUR
packages are not hard dependencies; the AUR desktop packages appear as optional
dependencies and `install.sh` installs them with `yay`. Build and install it as
your normal user from an up-to-date system:

```sh
cd distro/pkg/eitr-desktop
makepkg --nodeps --clean   # pacman -U below resolves the official dependencies
sudo pacman -U eitr-desktop-*.pkg.tar.zst
```

Packages only update files under `/usr`; your home is changed by `eitr-config`,
run as the desktop user:

- `eitr-config status` lists defaults that are new, outdated (unchanged by you),
  in conflict (changed by you and upstream), or differ without ever being seeded.
  `--all` also lists matching and locally modified files.
- `eitr-config seed` copies missing defaults and never overwrites anything.
  It records each copied file's checksum in
  `${XDG_STATE_HOME:-~/.local/state}/eitr/user-defaults-state.json`.
- `eitr-config update` seeds new defaults, replaces files you never edited, and
  writes `<file>.eitr-new` beside files you edited (like pacman's `.pacnew`).
  After merging one, `eitr-config resolve <file>` accepts it and removes the
  `.eitr-new` copy. Files you deleted stay deleted. `theme/current` is only
  seeded, because theme switches rewrite it. Both commands accept `--dry-run`.

`eitr-config` honours `XDG_CONFIG_HOME` and `XDG_STATE_HOME`. With
`--repo <checkout>` it compares against a checkout instead of the package.

## Build installer ISO

Install `archiso` on an Arch build machine, then run `bash distro/build-iso.sh`.
The ISO lands in `distro/out/`; temporary profile/work files stay under
`distro/build/`. The script refuses to reuse an existing build directory to
avoid deleting mounted work trees. It exports the committed `HEAD` (via
`git archive`) into `/opt/desktop-config` on the live image, so uncommitted,
untracked, and ignored machine-local files are excluded. The export also gets a
`distro/pkg/eitr-desktop/source-version` stamp so the target can build the
package without Git history, and `profiledef.sh` entries that restore the
executable bits `mkarchiso` would otherwise drop. Keep the image off public
mirrors until it has been tested in a VM and licensing for bundled
wallpaper/lockscreen assets has been reviewed.

### Guided install

Boot the ISO in **UEFI** mode, connect to the internet (Ethernet is automatic;
use `iwctl` for Wi-Fi) and run `eitr-guided-install` as root. It:

1. Lists whole, writable disks of at least 64 GiB (never the boot medium),
   shows the chosen disk's current contents and requires typing its path
   before anything is erased. No disk name is assumed.
2. Prompts twice for the LUKS2 passphrase and hands it to archinstall through a
   pipe; it is never written to a file or command line.
3. Runs archinstall with [`archinstall/user_configuration.json`](archinstall/user_configuration.json):
   a 2 GiB FAT32 ESP at `/boot` and a LUKS2 Btrfs root with subvolumes `@` (`/`),
   `@home`, `@log` (`/var/log`) and `@pkg` (`/var/cache/pacman/pkg`), so `/usr`,
   `/etc` and `/var/lib/pacman` stay in the root snapshot that
   `eitr-system snapshots-check` requires. `/.snapshots` is not a separate
   subvolume because `snapshots-setup` lets Snapper create it. It also selects
   Limine (kernels on the FAT `/boot`, compatible with bootable snapshot entries),
   linux, zram, PipeWire, Bluetooth, `[multilib]`, iwd with systemd-networkd and
   resolved (no NetworkManager), and the Minimal profile: Eitr provides the
   desktop. In archinstall's menu you choose the locale, keyboard, timezone and
   hostname, and create your user with sudo rights; leave the disk layout and
   encryption unchanged.
4. Before any reboot, copies this repository to `~/eitr` for that user, runs the
   same `snapshots-check` inside the new system, installs the Eitr network files
   and the resolved stub link, and adds a marked block to `~/.bash_profile`.

After rebooting, unlock the disk and log in on the first console. The block runs
`distro/archinstall/first-login.sh`, which checks connectivity (printing `iwctl`
steps if offline) and, once you confirm, runs `install.sh --check` and
`install.sh`. It is offered on each console login until the install completes;
NVIDIA systems pass their driver choice as described above, for example
`DISTRO_NVIDIA_DRIVER=open bash ~/eitr/distro/archinstall/first-login.sh`.
BIOS boot, other layouts and dual-boot partitioning are not handled by the guided
install; use a manual Arch install meeting the requirements above instead.

## Before calling it a distro

- Test the ISO boot and post-install flow on UEFI and BIOS VMs, then on real
  AMD, Intel and NVIDIA systems; verify networking and graphics separately.
- The development bootstrap has mock tests, not a completed fresh-machine
  installation test. This recipe is not a byte-for-byte system clone: fan-control
  services and other hardware-specific tuning still need target-specific review.
- Test the guided install (LUKS2, Limine, first-login hand-off) in UEFI VMs and
  on real hardware; add a branded live desktop only after the base install is
  repeatable. AUR packages need a maintained package repository to be included
  directly in the live ISO.
- Audit asset licenses, package updates, security defaults, and the first-run
  experience. Never bundle tokens, logins, saved networks or device identifiers.

The official project name is **Eitr**; the GitHub repository is
[`batistaerick/eitr`](https://github.com/batistaerick/eitr).
Installer paths remain generic. The Eitr logo is in `branding/`;
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
sudo pacman -S --needed snapper fprintd pam-u2f flatpak lazygit lazydocker pacman-contrib
(cd distro/pkg/eitr-desktop && makepkg --nodeps --clean)
sudo pacman -U distro/pkg/eitr-desktop/eitr-desktop-*.pkg.tar.zst
sudo /usr/lib/eitr/eitr-system snapshots-setup
sudo install -Dm644 /usr/share/eitr/system-update-policy.conf /etc/eitr/system-update-policy.conf
```

The [package](#desktop-package-and-config-updates) installs the root helper,
the data files read by the Install submenus, development installers and
Snapshots → Recovery Instructions and Security → Secure Boot Guide, and
`eitr-config`. Rebuild and reinstall it
after pulling changes; there is no manual copy step. Installing the package does
not touch `~/.config`: run `eitr-config status` to compare the live files with
the shipped defaults before deciding on `eitr-config update` (it never
overwrites edited files). Copies in `~/.local/share/eitr/` take precedence over
`/usr/share/eitr/`, so remove stale ones from earlier manual installs, and remove
an old `/usr/local/lib/eitr/eitr-system` once the packaged helper is installed.

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
