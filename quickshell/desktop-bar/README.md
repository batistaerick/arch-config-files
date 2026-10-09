# Desktop Bar

The desktop bar and its native popups follow the current theme.

Configuration reload errors use a native, padded popup with the bar's live
Theme Color or Blur appearance. Error details are selectable and scroll within
the screen; dismiss with the close button or Escape while focused. Successful
reloads stay quiet. The previous working configuration remains active after a
failed reload. A failure before any configuration loads still uses Quickshell's
built-in fallback, since the custom popup cannot run yet.

OBS controls share compact icon backgrounds and show loading until actions and
the resulting status refresh finish. Starting capture first prepares OBS in
the background, then closes the panel before recording or streaming starts.
The recording dot has its own tooltip and Pause/Resume + Stop popup.
Recording options persist in `obs-recording.json`; audio and microphone
switches affect OBS inputs, not system volume. Webcam requires a configured
OBS camera source. The active scene must include visible full-screen monitor
capture. OBS's saved Wayland capture permission still determines the monitor;
changing the primary display may require selecting it again in OBS.

Double-left-click empty bar space to switch between the current transparent
background and opaque theme color. Double-right-click empty space to switch
between one bar and three sections. Split sections touch the screen edge with
rounded exposed corners; only the middle section has extra gesture padding.
Gaps between sections pass clicks through to the desktop.
Drag empty bar space toward top, bottom, left, or right to change its edge; a
preview highlights the destination. The choices persist in `bar-settings.json`.
Walker exposes the same settings under Style > Desktop Bar > Appearance,
Layout, and Position. Appearance offers Blur and Theme Color.
Learn > Mouse Gestures also lists these gestures and
the desktop wallpaper/theme double clicks. Left/right bars use upright compact
controls, with the time/date centered and popups opening inward.
Hardware and AI Usage sit together after the workspaces; right-hand controls
retain their manual show/hide toggle. Both side groups share 24 px icon slots
and 4 px spacing, with centered alignment on every bar edge.

The Overview icon precedes the workspace markers on every bar edge. It opens a
screen-centered overview of occupied workspaces only, across monitors, numbered
1–10. Window captures stay in memory and refresh once per second while open;
they are never saved to disk. The workspace layout updates without switching
through desktops. Unsupported captures fall back to application labels. Click
a tile or press 1–9/0 to switch; arrows select a tile and Enter switches to it.
Tiles preserve the workspace monitor's aspect ratio and show its number in the
top-left corner. The current workspace has an accent border around its number;
keyboard selection uses a neutral foreground outline, independent of that marker.
There are no window-count headings. Escape or clicking outside the
tiles dismisses it. Walker > System > Workspace Overview opens the same view.
SUPER+Tab toggles Overview and is listed in Learn > Shortcuts. The overlay has
no navigation-tip footer; the shortcuts remain available in Learn and this guide.
The overlay always uses the theme-tinted Blur background, even with a Theme
Color bar. Workspace previews enter in order with a 55 ms stagger and a 260 ms
fade/scale/slide; even ten previews finish in about 755 ms. The blurred background
appears before previews. All dismissal paths instantly remove the entire overlay:
workspace selection, Escape, and outside click.
Capture uses Quickshell's
[ScreencopyView](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/ScreencopyView/)
and the compositor's window-export protocol, without additional screenshot tools.

The bar starts with workspaces 1–5. Visiting a higher workspace expands the
sequence through that number, capped at 10: visiting 7 shows 1, 2, 3, 4, 5, 6, 7.
Extra markers disappear when leaving an empty higher workspace: the sequence
ends at the current workspace or highest occupied workspace, with 1–5 always
present. The compositor's existing SUPER+1–9/0 bindings and
monitor assignments remain unchanged. Named/special workspaces are not included
in the numbered overview; external compositor commands can still create them.

Right-click a workspace to choose Numbers, Glyph, or Dots, or use Walker's
Style > Workspaces menu. Both selectors share the same saved preference.
The menu includes examples; the checkmark identifies the current selection.
The choice is saved in `workspace-style.json`. Selected workspace colors follow
the current theme's accent.

Calendar, Weather, and AI Usage use native Quickshell popups and dismiss on an
outside click or Escape, not pointer movement or focus loss. Calendar and Weather
stay centered on horizontal bars; AI Usage opens beside its left-hand icon.
Panels open above bottom bars and inward from vertical bars. Start-group panels
sit flush against the left screen edge (top for vertical bars); end-group panels
sit flush against the right edge (bottom for vertical bars), without a curved
gap at the screen boundary. Calendar and Weather remain screen-centered along
the bar's axis in all four positions.
Panels render inside the bar's Wayland surface, joining it with inward-curved
corners and continuous blur. They unfold over 320 ms from the selected edge
and fold back on outside click, Escape, or icon toggle.
Switching controls finishes the current panel's closing animation before opening
the next panel; rapid clicks select the latest requested panel without overlap.
Content-driven width and height changes use the same 320 ms cubic animation:
AI provider changes, OBS editing, keyboard additions, schedule editing, and
other dynamic panels grow or shrink while staying attached to the bar. Hidden
panels update immediately so resizing does not compete with opening/closing.
Their surface follows the bar's current appearance, including live changes
between the solid theme color and transparency with blur.
Calendar retains its fixed six-row
grid, bottom navigation, year progress, and Left/Right/Up/Down/bracket/T keys.
AI Usage retains the existing backend/cache, refresh-on-open, manual refresh,
and five-minute updates while open. Claude and Codex have separate provider tabs;
limit percentages show usage consumed. Local CLI transcripts provide seven days
of token totals and all-time model totals, including cached input tokens.
These charts describe this computer's session history, not account-wide billing.
Only model names, dates, and counts are cached in `~/.cache/desktop-ai-local-stats`;
conversation content is not copied into the cache. Streamed/repeated usage events
are deduplicated, and unchanged files reuse their cached summaries.
The popup grows to fit its content up to the available screen height.
Weather retains the 15-minute refresh,
debounced city search, country-based units, and smaller alternate temperature.
City overrides last only until the popup closes; the bar's default is unchanged.
Escape cancels city search first, then closes Weather. Buttons support Tab/Enter.

Bar tooltips follow the current theme's background and foreground colors.

A compact media strip sits left of the clock without moving the clock's center.
It uses native MPRIS players (excluding the duplicate playerctld proxy), prefers
a playing player, and retains a paused player's title.
Meeting apps and recognized meeting-page URLs/titles are excluded, including
Google Meet, Zoom, Teams, and Webex. Previous, play/pause, and
next controls respect the player's capabilities. The animated indicator shows
the song title on hover and raises players that support it when clicked.
The animated bars indicate playback, not an audio spectrum.
No media daemon or audio capture is started. The strip hides without an eligible
player or when there is insufficient space beside the hardware indicators.

WiFi and Bluetooth open themed native popups on the right. Outside clicks,
Escape, or hiding the status icons dismiss them; pointer movement does not.
Inactive workspace tooltips list their open applications by display name, with
duplicates omitted. Current and empty workspaces show no tooltip.
Walker System entries use show-panel.sh to open these same bar popups, including
audio, microphone, keyboard, calendar, weather, hardware, and AI usage. Hidden
status icons remain hidden; their popups anchor beside the notification icon.
Keyboard's Add Layout searches the installed XKB languages and variants. Added
layouts persist in hypr/keyboard-layouts.lua and retain Alt+Shift switching.
Up to four layouts can be configured; duplicate and unknown layouts are rejected.
WiFi retains the existing iwd service and uses its D-Bus API for adapter power,
scanning, connection, and disconnection. The compact panel separates remembered
networks from other networks and shows latency, packet loss, live transfer rates,
interface transfer totals, IP/gateway, and the current WiFi band. Transfer totals
cover the interface's lifetime since boot, not a billing period. Ping probes use
two packets to 1.1.1.1 on opening and every 15 seconds while visible.
Band selection remains managed by iwd; no unsupported band controls are shown.
Passwords are passed through stdin,
not command-line arguments. Enterprise network configuration uses the existing
iwd tools, such as impala. Bluetooth uses Quickshell's BlueZ service
for power, discovery, pairing, connecting, and forgetting devices (with confirmation).
Bluetooth groups connected, known, and scanned devices separately; row actions
stay beside the device, with power and Scan in the panel header. The adapter's
machine name is not displayed. The existing Blueman agent handles any pairing-code confirmation dialogs.
Discovery started by the popup stops after 20 seconds or when it closes.
These popups do not change network services or require new packages.

Quickshell owns the desktop notification server. The bell and SUPER+N open its
grouped notification center using the same DockPanel and PanelSurface as the
other controls. Cards use the notification image as their 28 px header icon,
falling back to the app icon (then a bell) if it is absent or cannot load.
Screenshot tools (including Satty) show a body preview instead, keeping the app
icon in the header. Other non-chat apps use body previews for non-square images;
chat/browser images remain header avatars. Previews preserve native size up to
160×120 px in the center or 128×96 px in popups. Image roles are inferred because
apps do not consistently label avatars versus attachments.
Images are never duplicated, and the app name is not repeated. Each
app group shows its count and starts with its newest notification over a visual
stack of up to three cards (one front card and two backing layers). The arrow
reveals the full group and collapses it back to the stack; the three-card limit
does not discard notification history. Single
notifications remain fully readable. Expansion choices persist while the shell
is running, including when new notifications arrive.
Right-clicking the bell toggles Do Not Disturb; the center also
offers Do Not Disturb and Clear All buttons. Popups and the center follow the
bar's live theme-color or transparent/blur appearance. Notifications include
image/app icons, action buttons, and inline replies when supplied by
the application. Clicking anywhere on a card invokes the application's default
action, such as opening the corresponding chat message, and closes the center
or hides the popup. Apps without a default action still expose any supplied
action buttons; the shell does not guess an action. Dismiss and reply controls
remain independent. Terminal notifications remain filtered out.
Hiding the desktop bar leaves the notification service and popups running;
opening the center while the bar is hidden shows its attached surface temporarily.

Popup timeout hides ordinary notifications while retaining them in history;
transient notifications expire without entering history. Critical notifications
and explicit no-timeout notifications remain until dismissed. Hovering pauses
popup expiry. Do Not Disturb suppresses popups while retaining history.
History stays in memory and survives Quickshell configuration reloads, but not
process restarts; notification contents are never written to a log. Only Do Not
Disturb is persisted in machine-local `notification-settings.json`. The center
retains up to 100 notifications, with periodic pruning. `notifications` IPC
provides `toggle`, `dnd`, `clear`, `clearApp`, and `status`. The old SwayNC files are retained
as an inactive rollback reference; neither theme changes nor startup invoke it.

Click the Hardware icon to open the shared CPU/GPU/RAM/Storage popup. It refreshes every
two seconds while visible and closes on an outside click or Escape. CPU load,
cores, frequency and temperature, GPU usage, VRAM and power, and RAM/swap totals
are read locally. Storage identifies only the drive backing `/`, including
encrypted device stacks, and shows installation used/free space. Other drives
are omitted, and Btrfs subvolume mounts are not counted repeatedly.
GPU telemetry uses `nvidia-smi`; temperatures use `sensors`.
Missing optional telemetry is shown as unavailable. No terminal is launched.

Display opens a themed native panel with brightness, Nightlight, and active
monitor names, resolutions, and refresh rates. Clicking a display makes it the
bar's primary screen; the choice persists in `~/.config/hypr/primary-display`.
If that display is unplugged, the bar uses an available screen until it returns.
Existing installations retain the HDMI preference until a choice is saved;
fresh portable installs default to the largest active screen. Display modes
remain read-only so this selection cannot disturb the Hyprland monitor layout.
The Nightlight editor saves valid time changes automatically; its Auto switch
enables or disables the schedule, while the main switch remains a manual override.
Brightness uses the laptop backlight when present and the first DDC monitor
otherwise. The SwayOSD overlay for volume and
brightness is generated from the current theme when styles change.
For an Arch installation image, include `brightnessctl` for direct laptop
backlight control and `ddcutil` for external monitors. The control chooses a
usable native backlight before DDC; chassis type is not used to select it.

Volume and Mic open themed native PipeWire popups with live volume/gain sliders,
mute controls, and default output/input device selection. Volume also lists
playback applications with individual sliders and mute controls. Sliders adjust
up to 100% without changing existing higher values until moved. Moving the mouse
away does not dismiss either popup; outside clicks, Escape, or hiding the status
icons do. Long lists scroll within the available screen height. No settings
application is launched, and opening Mic does not start audio capture.

The keyboard icon and Walker's System > Keyboard menu share the configured
layout selector and follow changes made with Alt+Shift. Weather keeps the city's local temperature unit
as the main reading, with a smaller equivalent in the other unit alongside it.

Install Quickshell:

```sh
sudo pacman -S quickshell
```

Run the preview:

```sh
quickshell -c desktop-bar --daemonize
```

Toggle the bar:

```sh
~/.config/walker/scripts/actions/toggle/desktop-bar.sh
```

Stop the bar:

```sh
quickshell kill -c desktop-bar
```

## Panel Style

`PanelStyle.js` defines the shared font family, utility heading (18 px),
body/control text (14 px), captions (12-13 px), padding, and corner radii.
Calendar dates, weather temperatures, and glyphs retain purpose-specific sizes.
Compact selectors retain their smaller padding; full panels use 18 px.
Notification CSS uses the same font family, with larger text for message content.
