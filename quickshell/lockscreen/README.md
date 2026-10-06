# Desktop Lockscreen

Local Quickshell lockscreen configuration with selectable designs derived from
[qylock](https://github.com/Darkkal44/qylock). Original designs and compatibility
components retain their GPL-3.0 license (see `LICENSE`). No external checkout or
upstream installation script is needed at runtime.
Imported from upstream revision `f6561e2ceae33f26e5e660742a5df2f725cbe514`.

## Use

- Walker: Style > Lockscreen. Enter selects a design for future locks.
- Ctrl+P previews without locking; Escape returns to the selector.
- Super+M locks with the selected design. Hyprlock remains the safety fallback.
- Preferences: `~/.config/lockscreen/selected`.

Dependencies: `quickshell`, `qt6-declarative`, `qt6-5compat`, `hyprlock`, and
`python`. Animated video designs also need `qt6-multimedia` and
`qt6-multimedia-ffmpeg`. Keep Hyprlock installed: its PAM configuration is used
for password authentication and it remains the safety fallback, but is not
listed in the design selector.

Real locks use Wayland's session-lock protocol on every monitor, not an overlay.
Previews are explicitly separate overlays: authentication and power actions
are disabled. The adapter accepts the current user's password only, never
switches users/sessions, and never kills existing lockers. Multi-prompt PAM/MFA
flows are not supported; select Hyprlock for those configurations.

The screens can be edited under `themes/`. The authentication/session-lock core
lives in `AuthAdapter.qml` and `shell.qml`, separately from the presentation.
`scripts/settings.py` discovers designs by `Main.qml` and reads their INI config.

## Login Screen

Run once (and again after editing or adding designs):

```sh
sudo python3 ~/.config/quickshell/lockscreen/scripts/install-login.py
```

The installer copies the designs to root-owned `desktop-lockscreen-*` directories
under `/usr/share/sddm/themes`. Sources stay here for backups. No external checkout
is needed. SDDM uses its native authentication, user model, and session selector;
the Quickshell authentication adapter is not installed into SDDM.

Walker selections then update both screens. A root-owned helper validates the
requested design against its installed manifest before atomically updating
`/etc/sddm.conf.d/90-desktop-lockscreen.conf`. Its sudo rule permits only this
selector, not arbitrary commands or file copying. If login selection fails,
the lockscreen selection stays unchanged. Previews never update either selection.
SDDM is never restarted; changes appear at the next login.

To restore the previous SDDM theme without changing your lockscreen, remove
`/etc/sddm.conf.d/90-desktop-lockscreen.conf` with sudo. To disconnect automatic
login selection, also remove `/etc/sudoers.d/desktop-login-select` and
`/usr/local/bin/desktop-login-select`.

### Recovery

Greeter test mode checks startup/rendering, not real password authentication.
If the login screen fails, press Ctrl+Alt+F3 and log in at the text console, then:

```sh
sudo mv /etc/sddm.conf.d/90-desktop-lockscreen.conf /etc/sddm.conf.d/90-desktop-lockscreen.conf.disabled
sudo systemctl restart sddm
```

This restores the previously configured SDDM theme. Restarting SDDM closes any
graphical session; use it only after saving your work or from a failed login.
