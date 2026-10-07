# Repository Conventions

This repository backs up a customized Arch Linux desktop. It is not an Omarchy
installation. Preserve the existing design and workflows rather than replacing
them with upstream defaults.

## Engineering Practices

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
- Walker system actions should open the same native panels as bar clicks. Use
  the existing `panels` IPC interface, including `call -- panels show <kind>`.
- Use `walker/bin/walker` for Walker launches. It carries an application-scoped
  GTK workaround required for compositor blur; do not bypass it casually.
- WiFi uses iwd, audio uses PipeWire, Bluetooth uses the native Quickshell service,
  and notifications use SwayNC. Do not substitute backends without agreement.
- The custom lockscreen and SDDM login themes have separate responsibilities.
  Keep the `hyprlock` PAM dependency and existing idle/suspend timings intact.

## Visual And Interaction Patterns

- Read `quickshell/desktop-bar/PanelStyle.js` and its README before styling panels.
  Use the shared font, text roles, padding, and corner radii. Utility headings are
  18 px, body/control text 14 px, and captions 12-13 px. Calendar dates, weather
  temperatures, and glyphs have intentional size exceptions.
- Panel backgrounds are opaque current-theme colors, not hardcoded black or a
  generic light/dark palette. Maintain both light and dark theme support.
- Use subtle foreground-colored dividers and existing `PanelButton`,
  `PanelSwitch`, `BarTooltip`, and `ThemedPopup` components where appropriate.
  Keep hover tooltips short and theme-aware; do not introduce bar hover fills.
- Keep rounded corners, centered icons, consistent gaps, and stable dimensions.
  Changing values must not shift bar items. Match icon sizes visually, not just
  by font size, since glyph shapes differ.
- The date/time stays exactly screen-centered regardless of neighboring items.
  The bar prefers HDMI when two monitors are connected and DP when used alone;
  preserve the existing screen-selection function rather than hardcoding new IDs.
- Hardware popups open top-left; calendar/weather open top-center; right-hand
  controls open top-right. Preserve the common offset below the bar and existing
  window-border alignment. Growing content must not move panels above the bar.
- Popups close on outside click or Escape, not merely when the pointer leaves.
  Prefer native popups over floating Hyprland windows for bar controls.
- Keep the right-side icon group hidden by default, with its manual toggle and
  no auto-close timer. Preserve the existing arrow direction and icon order.
- Keep calendar height fixed with six week rows. Weather city choices are
  session-only; the city close button restores the default geolocation.
- Media is hidden when no eligible player exists; meetings are excluded. Keep
  its compact controls and song-name tooltip on the animated equalizer.
- WiFi separates Connected, Known Networks, and Other Networks. Saved offline
  networks remain listed. Do not show fake signal percentages for offline rows.
- Workspace style examples must match the actual bar markers. Keep four default
  workspaces and the ability to create more; preserve the dual-monitor behavior.
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
