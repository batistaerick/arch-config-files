# Desktop Bar

The desktop bar and its native popups follow the current theme.

Right-click a workspace to choose Numbers, Glyph, or Dots, or use Walker's
Style > Workspaces menu. Both selectors share the same saved preference.
The menu includes examples; the checkmark identifies the current selection.
The choice is saved in `workspace-style.json`. Selected workspace colors follow
the current theme's accent.

Calendar, Weather, and AI Usage use native Quickshell popups and dismiss on an
outside click or Escape, not pointer movement or focus loss. Calendar and Weather
stay top-center; AI Usage stays on the right. Calendar retains its fixed six-row
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
next controls respect the player's capabilities. Long titles scroll only while
hovered within a fixed-width strip and reset on pointer exit, without a title
tooltip. Clicking the title raises players
that support it. The animated bars indicate playback, not an audio spectrum.
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

SwayNC contains only the title/clear control and notifications. Its opaque
background follows the current theme, including light themes. The bar bell uses
SwayNC's native event subscription to update immediately when notifications are
added/cleared, with polling retained as a fallback if the subscription stops.

Click GPU, CPU, or RAM to open the shared hardware popup. It refreshes every
two seconds while visible and closes on an outside click or Escape. CPU load,
cores, frequency and temperature, GPU usage, VRAM and power, and RAM/swap totals
are read locally. GPU telemetry uses `nvidia-smi`; temperatures use `sensors`.
Missing optional telemetry is shown as unavailable. No terminal is launched.

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
