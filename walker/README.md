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

Main → Install → Pacman / Yay opens a terminal package picker. Type to search
package names, press Tab to select/unselect multiple packages, then Enter to install
the selection in that terminal. Escape cancels without installing. Pacman uses
the local repository databases; AUR downloads its package-name index when opened.
Ctrl+B opens official metadata or the AUR build repository without
executing it; review PKGBUILD, .install files and patches before accepting Yay's
build prompts. Selection lasts only for that picker session.

SUPER+Space uses Elephant's native desktopapplications provider, preserving
existing pins, pin/unpin actions, history and Enter-to-launch. SUPER+F opens Main.
Main → Apps is the separate custom menu with Enter-to-launch and back navigation.
In that custom menu, Delete opens a themed
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
are reused with --needed. Official-package installs first run `checkupdates`;
if system updates are pending they stop and point to System Update, so upgrades
never happen outside its recovery snapshots (Arch does not support partial
upgrades). Managed tool installers use official endpoints recorded in
`distro/installers.json` and never edit shell profiles; `HOME_FILES/.zshrc`
already adds their PATH entries. The runtime catalog is installed under
`~/.local/share/eitr/`; a missing catalog is shown as an error row in the menu.

System → Security separates password changes, fingerprint enrollment and FIDO2
security-key enrollment. Enrolling does not automatically change PAM; enabling
authentication is a separate confirmed operation through the root-owned helper.
Password fallback remains. Fingerprint is added to the hyprlock, SDDM and sudo
PAM stacks so "password only" also applies to the lockscreen; pam_fprintd may
delay the password prompt for up to 10 seconds. A FIDO2 biometric key is not a laptop fingerprint reader.
Touch ID on the host Mac is not passed through as a normal Linux fingerprint reader.
System → Snapshots requires the reviewed privileged integration described
in [the distro guide](../distro/README.md). Update works normally on existing
desktops. System Update upgrades official and AUR packages, with pre/post
snapshots enabled only on distro installs. Advanced offers Pacman, Pacman + Yay,
and Yay (AUR-only), without automatic snapshots.
No PAM or snapshot setup runs at login.
System → Battery Charge Limit sets 60/80/90% or removes the limit after a typed
`yes`, through `eitr-system battery-limit`. It needs a laptop battery whose
firmware exposes `charge_control_end_threshold`; elsewhere it explains that no
control exists. The limit is restored at boot and after resume.

Gaming offers Steam and NVIDIA's official GeForce NOW Flatpak. NVIDIA's cloud
service is not restricted to local NVIDIA GPUs; no AMD-branded equivalent is
invented. Accounts, subscriptions and VM/cloud-client compatibility are separate.

Wallpaper and theme selections use the same 650 ms center-out reveal behind
application windows, without an input grab. Hyprpaper remains the persistent
wallpaper backend; if the transition cannot run, the static wallpaper still applies.

Development > Cloud lists AWS profiles from `aws configure list-profiles`. To show
friendly labels or pin a default region, copy
`scripts/menus/cloud/cloud.env.example` to `~/.config/eitr/cloud.env`; that file
is machine-local and never committed.
