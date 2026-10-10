# Walker

The launcher uses the current theme and Hyprland's blur settings.
`bin/walker` disables GTK's background-effects protocol only for Walker, allowing
the compositor's layer blur rule to apply. Other GTK applications are unchanged.

Install the launcher shim with:

```sh
mkdir -p ~/.local/bin
ln -s ../../.config/walker/bin/walker ~/.local/bin/walker
```

Keep `~/.local/bin` ahead of `/usr/bin` in PATH. The backup repository includes
the corresponding symlink under `HOME_FILES/.local/bin/walker`.

## Software and system menus

Main → Install offers Pacman and Yay/AUR search. Type at least two characters,
press Tab to select/unselect multiple packages, then Enter to install the selection
in a terminal. Ctrl+B opens official metadata or the AUR build repository without
executing it; review PKGBUILD, .install files and patches before accepting Yay's
build prompts. Selection is separate for each source and clears after launch.

SUPER+Space and Main → Apps use the same application menu. Delete opens a themed
Cancel/Confirm prompt, then a terminal for package-manager authorization. The
whole owning package is removed, not just one launcher; dependencies are never
force-removed and personal application data is not deleted. Locally created
launchers without an identifiable package are rejected, not silently deleted.
Clipboard History (SUPER+Ctrl+V) Delete removes only the selected stored entry
and its private preview; it does not clear the active system clipboard.

Install → Development Languages, JavaScript Tools, and AI CLIs install optional
tools explicitly. Lazygit and Lazydocker are mandatory distro defaults, not a
Developer Tools submenu. Install → Browsers
offers Firefox, Tor Browser Launcher, Edge, Chromium and Chrome. Existing packages
are reused with --needed; the terminal still shows any update/dependency prompts.
Managed tool installers use official endpoints recorded in `distro/installers.json`;
the runtime catalog is installed under `~/.local/share/eitr/`.

System → Security separates password changes, fingerprint enrollment and FIDO2
security-key enrollment. Enrolling does not automatically change PAM; enabling
authentication is a separate confirmed operation through the root-owned helper.
Password fallback remains. A FIDO2 biometric key is not a laptop fingerprint reader.
Touch ID on the host Mac is not passed through as a normal Linux fingerprint reader.
System → Snapshots and Update require the reviewed privileged integration described
in [the distro guide](../distro/README.md). No PAM or snapshot setup runs at login.

Gaming offers Steam and NVIDIA's official GeForce NOW Flatpak. NVIDIA's cloud
service is not restricted to local NVIDIA GPUs; no AMD-branded equivalent is
invented. Accounts, subscriptions and VM/cloud-client compatibility are separate.

Wallpaper and theme selections use the same 650 ms center-out reveal behind
application windows, without an input grab. Hyprpaper remains the persistent
wallpaper backend; if the transition cannot run, the static wallpaper still applies.
