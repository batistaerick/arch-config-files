# Eitr

<p align="center">
  <img src="branding/png/eitr-logo-green-512.png" alt="Eitr logo" width="200">
</p>

An Arch-based desktop project built around Hyprland, Quickshell, and a consistent,
theme-aware experience. Eitr combines a custom shell with dotfiles and a
fresh-install recipe for an everyday Linux workstation.

**Status:** actively developed. This is not yet a tested, standalone distribution.
The ISO recipe builds an Arch installer image, not a preinstalled graphical live
desktop. Review the installation guide before using it on a new machine.

## Desktop

- A custom Quickshell bar with joined, animated panels and Blur/Theme Color modes.
- Native notifications with grouped stacks, history, and Do Not Disturb.
- An occupied-workspace Overview with in-memory previews and keyboard navigation.
- Dark/light theme and wallpaper carousels, with coordinated application colors.
- Walker menus and Elephant providers for applications, system actions, and Learn.
- Native hardware, audio, network, calendar, weather, and other desktop controls.
- A themed Fastfetch About page featuring Eitr's rune logo.
- Kitty, Zsh, Neovim/LazyVim, Lazygit and Lazydocker; optional development menus
  install languages/frameworks and AI CLIs. NVM manages Node.js and SDKMAN
  manages Java/Maven when selected. Yay supplies the required AUR packages.
- Package installation with multi-selection/build review, confirmed app removal,
  security enrollment, and snapshot-protected package updates on Btrfs.

## Getting started

For pre-release Apple Silicon testing, see the
[temporary Mac VM guide](distro/MAC-VM-TESTING.md). Remove that guide and this link
after installation and release validation is complete.

Read [the installation guide](distro/README.md), including its hardware caveats
and current limitations. The installer is intended for a **new Arch installation**,
with Btrfs root, as a normal user with sudo access, not an existing configured desktop. It refuses
to overwrite existing configuration paths and can be rerun after a partial failure. Enable Arch's multilib repository as
described in the guide before proceeding.

```sh
git clone https://github.com/batistaerick/eitr.git
cd eitr
bash distro/install.sh --check
# Only after reviewing the guide, package manifests, and installer:
bash distro/install.sh
```

Package defaults are recorded in [distro/](distro/README.md); review all four
official/AUR manifests before installation. Credentials and account state are
not part of the installation.

## Everyday shortcuts

- `Super + Space`: search applications.
- `Super + F`: open the main menu.
- `Super + Tab`: toggle Workspace Overview.
- `Super + N`: open the notification center.
- `Super + /`: open Learn's shortcut list.
- `Super + Ctrl + Shift + N`: open the theme carousel.

Inside Overview, arrows select, Enter switches, numbers jump, and Escape closes.

## Repository layout

Most top-level directories mirror `~/.config`. `HOME_FILES/` holds files installed
elsewhere in the user's home directory. `distro/` owns package manifests, hardware
detection, installation scripts, and the ISO recipe. `branding/` holds the logo.

The shared Hyprland config uses a generic, automatic monitor layout. Settings for
one machine (monitor modes, workspace rules, input devices) go in an optional,
Git-ignored `~/.config/hypr/local.lua`; see
[monitors and machine-local overrides](distro/README.md#monitors-and-machine-local-overrides).
On the original desktop, copy `hypr/local.lua.example` to
`~/.config/hypr/local.lua` and `hypr/preferred-outputs.example` to
`~/.config/hypr/preferred-outputs`.

More details: [desktop shell](quickshell/desktop-bar/README.md),
[lockscreen and login](quickshell/lockscreen/README.md),
[Walker](walker/README.md), [About](fastfetch/README.md),
and [branding](branding/README.md).

## Development

Keep changes focused, preserve existing workflows, and follow [AGENTS.md](AGENTS.md).
Run the tests relevant to your change; do not test disruptive hardware actions
on an active session. Fresh-machine installation and ISO testing are still needed.
Bundled artwork and third-party assets require a license review before public ISO
distribution; inclusion here does not grant blanket redistribution rights.
Read [PUBLISHING.md](PUBLISHING.md) before making the repository public or
distributing an ISO.

## Checks

`tools/check.sh` runs every repository check: Python and Node test suites,
`bash -n`/`py_compile`/`luac -p` syntax checks, ShellCheck (warnings and errors),
Qt 6 qmllint, whitespace, and JSON/TOML parsing. Files are discovered with
`git ls-files`, so new tests and scripts are picked up automatically. CI runs the
same script in an Arch Linux container (`.github/workflows/ci.yml`).

```sh
bash tools/check.sh                  # all stages; run as a normal user
bash tools/check.sh shellcheck qml   # selected stages (see --list)
```

On a non-Arch host, run it from a regular clone in a throwaway Arch container.
The checkout is mounted read-only and copied, so its file ownership is untouched:

```sh
docker run --rm --platform linux/amd64 -v "$PWD":/repo:ro archlinux:latest bash -c 'sed -i "/^\[options\]/a DisableSandbox" /etc/pacman.conf && pacman -Syu --noconfirm --needed bash git python python-pillow python-gobject nodejs shellcheck lua qt6-declarative jq util-linux xkeyboard-config >/dev/null && useradd -m tester && cp -a /repo /home/tester/eitr && chown -R tester: /home/tester/eitr && su tester -c "cd ~/eitr && bash tools/check.sh"'
```
