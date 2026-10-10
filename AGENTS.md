# Repository Conventions

This repository backs up a customized Arch Linux desktop. It is not an Omarchy
installation. Preserve the existing design and workflows rather than replacing
them with upstream defaults.

## Engineering Practices

- Keep folders and filenames organized and descriptive. Promote selected artwork
  out of concept folders and replace draft identifiers such as `05b-rune-liquid`
  with stable Eitr asset names. Store branding sources, vector masters, and sized
  exports in clearly separated directories; update every consumer when renaming.
  Keep export scripts with their assets so formats and sizes can be regenerated.

- Keep changes small and cohesive. Read neighboring code before adding a new
  component or helper; reuse existing patterns and shared style APIs.
- Avoid duplicated behavior and duplicated theme constants. Put reusable
  logic in one owner module and update its callers, but do not create an
  abstraction merely to eliminate a few clear lines.
- Prefer descriptive names, simple control flow, explicit errors, and data
  formats with real parsers. Avoid hidden side effects and hardcoded user paths.
- Keep generated files and their generators synchronized. Validate both the
  immediate result and what a later theme change or reboot will regenerate.
- Add focused tests for new behavior and regressions; run syntax/lint checks
  for every edited script. Do not claim untested hardware behavior as verified.
- Keep external packages and installers in `distro/` manifests rather than
  scattering installation commands across unrelated desktop scripts. Package
  lists should distinguish official, AUR, and hardware-specific dependencies.
- Fresh-install code must not assume a particular username, monitor, GPU,
  locale, account, or disk layout. Never bundle secrets or migrate live caches.
- Do not overwrite existing user configs or start/restart services during a
  repository audit. Installer actions belong on a new target system only.

## Working With Live Configs

- This is Erick's PERSONAL repository, owned by GitHub `batistaerick`. Never
  author or commit here as the work account `erickdoola` or with `erick@doola.com`.
  Use repo-local `user.name=Erick Prado` and
  `user.email=batista.erick@outlook.com`, and the `github-personal` SSH alias for
  `batistaerick/eitr`. Check BOTH author and committer identities before committing.
  Keep `core.hooksPath=.githooks` enabled in this checkout. Do not change global
  Git identity or switch the global GitHub CLI account: this PC also hosts work
  repos. For personal GitHub CLI writes, use an explicit per-command personal
  account token without printing it. Never bypass the identity guard.

- On the owner's machine, the active configuration is under `$HOME/.config`.
  Read the live files and repository versions before editing: either may contain
  newer user changes. Never restore the backup over live configs indiscriminately.
- For requested desktop changes, update the relevant live files, verify them,
  then sync the matching files into this repository. On other machines, do not
  assume this layout is installed or modify the desktop without authorization.
- Repository directories generally mirror `.config`. `HOME_FILES` contains files
  belonging elsewhere under `$HOME`; preserve relative symlinks and permissions.
- Keep unrelated user changes. Do not commit credentials, tokens, clipboard data,
  generated QR codes, logs, caches, or Python bytecode.
- The owner's standing preference is to sync, commit, and push completed changes.
  Review the diff and status first; report failures rather than claiming success.
  Never force-push or reset unrelated work.

## Desktop Architecture

- Hyprland configuration uses Lua in `hypr/hyprland.lua`; follow its existing APIs.
- The active bar and native popups are in `quickshell/desktop-bar`.
  Use local scripts from that directory, not legacy Waybar or Wofi helpers.
- Walker is the launcher; Elephant supplies its menus. Update all relevant
  shortcut and Learn/Shortcuts entry points when changing a workflow.
- SUPER+Space must keep the native desktopapplications provider and its existing
  pins/history/actions. Do not replace it with a custom menu to add another action.
  Existing desktops must not require distro snapshot setup just to update;
  fresh distro installs snapshot only the System Update workflow. Advanced
  Pacman/AUR updates intentionally do not create automatic snapshots.
- Keep Walker menus organized: group related setup/actions into named submenus
  and sort their labels alphabetically (case-insensitive). Main retains its
  custom order, and Apps retains its existing behavior.
  instead of crowding their parent. Set each submenu's parent to its actual
  location so Shift+Backspace returns correctly. Submenu rows use ">" subtext
  with the shared horizontal row layout (for example item_menus-system.xml),
  right-aligned beside the label, never underneath it. Add the matching
  item_menus-<name>.xml layout for new parent menus.
- Walker system actions should open the same native panels as bar clicks. Use
  the existing `panels` IPC interface, including `call -- panels show <kind>`.
- Use `walker/bin/walker` for Walker launches. It carries an application-scoped
  GTK workaround required for compositor blur; do not bypass it casually.
- WiFi uses iwd, audio uses PipeWire, Bluetooth uses the native Quickshell service,
  and Quickshell's NotificationServer handles notifications. Do not substitute
  backends without agreement. Notification cards and the center follow the same
  shared panel styles and the bar's current color/transparency setting.
- The custom lockscreen and SDDM login themes have separate responsibilities.
  Keep the `hyprlock` PAM dependency and existing idle/suspend timings intact.

## Visual And Interaction Patterns

- Read `quickshell/desktop-bar/PanelStyle.js` and its README before styling panels.
  Use the shared font, text roles, padding, and corner radii. Utility headings are
  18 px, body/control text 14 px, and captions 12-13 px. Calendar dates, weather
  temperatures, and glyphs have intentional size exceptions.
- Panel surfaces follow the bar's selected theme color or transparency with
  blur. Maintain both light and dark theme support; do not reintroduce the
  no-color appearance option.
- Use subtle foreground-colored dividers and existing `PanelButton`,
  `PanelSwitch`, `BarTooltip`, and `ThemedPopup` components where appropriate.
  Keep hover tooltips short and theme-aware; do not introduce bar hover fills.
- Keep rounded corners, centered icons, consistent gaps, and stable dimensions.
  Changing values must not shift bar items. Match icon sizes visually, not just
  by font size, since glyph shapes differ.
- The date/time stays exactly screen-centered regardless of neighboring items.
  The Display panel's connected rows select the bar's primary screen and save
  it in the machine-local `hypr/primary-display` file. If the chosen display is
  disconnected, fall back to an available one. Until a choice is saved, use the
  first connected output in the machine-local `hypr/preferred-outputs`, else the
  largest active display. Do not commit primary-display or preferred-outputs.
- Shared `hypr/hyprland.lua` stays generic: automatic monitor layout and no
  connector names, input device names, or other machine-specific settings.
  Those belong in the Git-ignored `~/.config/hypr/local.lua`, loaded last and
  error-guarded; the owner's layout is kept in `hypr/local.lua.example` and
  `hypr/preferred-outputs.example`. Update the examples, not the shared file,
  when the owner's hardware changes.
- Hardware and AI Usage icons sit after the workspaces and open on the left;
  calendar/weather open centered; other controls open on the right. Panels
  share the bar's Wayland surface and attach directly to its actual edge with
  inward-curved corners and continuous blur. Unfold them inward on opening and
  fold them back on dismissal. Keep content padded inside the curved surface.
  Hardware uses one icon, with CPU/GPU/RAM and only the root-drive Storage data
  inside the popup. Growing content must stay within the usable screen.
- Empty-bar double-left-click toggles transparency, double-right-click toggles
  one/three sections, and left drag changes the screen edge. These settings
  persist in `bar-settings.json` and also appear under Style > Desktop Bar.
  Split sections touch the screen edge with rounded exposed corners; only the
  middle section gets extra gesture padding. Gaps must pass clicks through.
- Panels close on outside click or Escape, not merely when the pointer leaves.
  Use the shared DockPanel and PanelSurface components for bar controls.
- Keep the right-side icon group hidden by default, with its manual toggle and
  no auto-close timer. Preserve the existing arrow direction and icon order.
- Keep calendar height fixed with six week rows. Weather city choices are
  session-only; the city close button restores the default geolocation.
- Media is hidden when no eligible player exists; meetings are excluded. Keep
  its compact controls and song-name tooltip on the animated equalizer.
- WiFi separates Connected, Known Networks, and Other Networks. Saved offline
  networks remain listed. Do not show fake signal percentages for offline rows.
- Workspace style examples must match the actual bar markers. Start with five
  numbered workspaces; expand sequentially through the current or highest occupied
  workspace, capped at ten. Remove extra empty markers after leaving them.
  Preserve dual-monitor assignments. The Overview icon precedes
  the workspace markers and shows only occupied numbered workspaces, using
  in-memory previews with no saved screenshots. Keep equal left-group spacing
  and centered icon/marker alignment on all bar edges. Right-side controls use
  the same icon-slot dimensions and spacing as the left group.
  Overview always uses a theme-tinted blurred background, independent of bar
  appearance. Stagger preview entrances in workspace order, finishing within
  one second; all Overview dismissal paths must be instant, with no closing effect.
- Wallpaper/theme changes should not emit success notifications. Preserve both
  Walker selection and the desktop carousel workflows.
- Theme-generator changes must accompany edits to generated styles so the next
  theme switch does not undo the fix. Use portable names and `$HOME` paths, not
  personal names or upstream branding for new components.

## Safety And Verification

- Never test by disconnecting WiFi/Bluetooth, changing audio devices or levels,
  starting/stopping recordings or streams, locking, suspending, or logging out.
  Use read-only queries and mocks; ask before exercising disruptive actions.
- Never restart SDDM during a session. Ask before restarting Elephant or another
  service that could disrupt the user's work, unless permission was given for
  the current task. Prefer Quickshell auto-reload and config-only Hyprland reload.
- Boot, disk, LUKS/TPM, Secure Boot and PAM changes stay explicit `eitr-system`
  actions behind typed confirmation, with backups or a documented undo. The
  installer may only offer them (`distro/bootloader/setup.sh --offer`); never
  automate sbctl key enrollment, initramfs `HOOKS` edits or `limine-update`.
  systemd-boot snapshot booting is unsupported. Laptop-only features (power
  profiles, battery limit) must stay hidden or refused without a system battery.
- Do not uninstall packages, delete configs, or weaken credential permissions
  without explicit authorization. Keep WiFi QR secrets out of files and argv.
- Inspect screenshots for clipping, alignment, and theme consistency without
  publishing private screen content. Close any test menus afterward.
- Run focused checks appropriate to the change, for example:

```sh
/usr/lib/qt6/bin/qmllint --silent quickshell/desktop-bar/ChangedComponent.qml
python3 -m unittest discover -s quickshell/desktop-bar/tests
python3 -m unittest discover -s walker/tests
node quickshell/desktop-bar/tests/test_media_model.js
luac -p hypr/hyprland.lua
bash -n path/to/changed-script.sh
hyprctl configerrors
git diff --check
```

`hyprctl` checks require the live session. Use the Qt 6 linter, not the older
`qmllint` on PATH. Do not claim unperformed tests or end with a push still running.
