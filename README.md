# Eitr

<p align="center">
  <img src="branding/png/eitr-logo-green-512.png" alt="Eitr Rune Liquid logo" width="200">
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
- A themed Fastfetch About page featuring Eitr's Rune Liquid logo.
- Kitty, Zsh, Neovim/LazyVim, and development tools; NVM manages Node.js and SDKMAN
  manages Java/Maven. Yay supplies the required AUR packages.

## Getting started

Read [the installation guide](distro/README.md), including its hardware caveats
and current limitations. The installer is intended for a **new Arch installation**,
as a normal user with sudo access, not an existing configured desktop. It refuses
to overwrite existing configuration paths. Enable Arch's multilib repository as
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
