local function get_hostname()
  local handle = io.popen("hostname 2>/dev/null")
  if not handle then return "" end
  local hostname = handle:read("*l") or ""
  handle:close()
  return hostname
end

local hostname = get_hostname()
local is_laptop = hostname == "laptop"

----------------
--- THEMES ---
----------------

local function trim(value)
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function load_theme_env(path)
  local file = io.open(path, "r")
  if not file then
    return
  end

  for line in file:lines() do
    local cleaned = trim(line:gsub("#.*$", ""))

    local key, value = cleaned:match("^env%s*=%s*([^,]+)%s*,%s*(.+)$")

    if key and value then
      hl.env(trim(key), trim(value))
    end
  end

  file:close()
end

load_theme_env(os.getenv("HOME") .. "/.config/hypr/theme-env.conf")

----------------
--- MONITORS ---
----------------

if is_laptop then
  hl.monitor({
    output =   "eDP-1",
    mode =     "1920x1080@60",
    position = "0x0",
    scale =    1,
  })
else
  hl.monitor({
    output =   "DP-3",
    mode =     "2560x1080@144",
    position = "0x0",
    scale =    1,
  })

  hl.monitor({
    output =   "HDMI-A-1",
    mode =     "1920x1080@144",
    position = "320x1080",
    scale =    1,
  })
end

-------------------
--- MY PROGRAMS ---
-------------------

local terminal = "kitty"
local fileManager = "dolphin"
local menu = "wofi --show drun"

-----------------
--- AUTOSTART ---
-----------------

hl.on("hyprland.start", function()
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("swayosd-server")
  hl.exec_cmd("rm -f ~/.cache/cliphist/db")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-------------------------------
--- ENVIRONMENT VARIABLES -----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

---------------------
--- LOOK AND FEEL ---
---------------------

hl.config({
  general = {
    gaps_in =          4,
    gaps_out =         8,
    border_size =      2,
    col = {
      active_border = {
        colors = {
          "rgba(33ccffee)",
          "rgba(00ff99ee)",
        },
        angle = 45
      },
      inactive_border = "rgba(595959aa)",
    },
    resize_on_border = false,
    allow_tearing =    false,
    layout =           "dwindle",
  },
  decoration = {
    rounding =         5,
    rounding_power =   5,
    active_opacity =   1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled =      true,
      range =        4,
      render_power = 3,
      color =        "rgba(1a1a1aee)",
    },
    blur = {
      enabled =  true,
      size =     3,
      passes =   2,
      vibrancy = 0.2,
    },
  },
  animations = {
    enabled = true,
  },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

hl.config({
  dwindle = {
    preserve_split = true,
  },
  master = {
    new_status = "master",
  },
  scrolling = {
    fullscreen_on_one_column = true,
  },
  misc = {
    focus_on_activate =       true,
    disable_hyprland_logo =   true,
    force_default_wallpaper = -1,
  },
})

-------------
--- INPUT ---
-------------

hl.config({
  input = {
    sensitivity =  0,
    follow_mouse = 1,
    kb_model =     "",
    kb_rules =     "",
    kb_layout =    "us,us",
    kb_variant =   ",intl",
    kb_options =   "grp:alt_shift_toggle",
    touchpad = {
      natural_scroll = false,
    },
  },
})

-- Your original 3-finger horizontal workspace gesture.
hl.gesture({
  fingers =   3,
  direction = "horizontal",
  action =    "workspace",
})

-- hl.gesture({
--   fingers = 4,
--   direction = "horizontal",
--   action = "scroll_move",
--   scale = 1.0,
-- })

hl.device({
  name =        "epic-mouse-v1",
  sensitivity = -0.5,
})

-------------------
--- KEYBINDINGS ---
-------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager .. " --new-window"))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.window.pin())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + A", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.layout("rotatesplit"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu --width 1000 | cliphist decode | wl-copy && wtype -M ctrl v -m ctrl"))

-- Move focus with mainMod + vim-style keys
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + i", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))

-- Resize active window
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.resize({ x = -15, y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.resize({ x = 0,   y = 15, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + i", hl.dsp.window.resize({ x = 0,   y = -15, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.resize({ x = 15,  y = 0,  relative = true }), { repeating = true })

-- Move active window
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + CTRL + i", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ direction = "r" }))

-- Switch / move to workspaces 1-10
for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + CTRL + S", hl.dsp.window.move({ workspace = 1 }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Scripts
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("~/.config/wofi/scripts/actions/screenshot-selection.sh"))
hl.bind("PRINT", hl.dsp.exec_cmd("~/.config/wofi/scripts/actions/screenshot-full.sh"))
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.exec_cmd("~/.config/wofi/scripts/actions/toggle-waybar.sh"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/wofi/scripts/actions/next-wallpaper.sh"))
hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.exec_cmd("~/.config/wofi/scripts/menus/wallpaper.sh"))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("~/.config/wofi/scripts/menus/main.sh"))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("~/.config/wofi/scripts/menus/search.sh"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("~/.config/wofi/scripts/actions/google-search.sh"))

-- hyprpicker
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("hyprpicker -a"))

-- hyprlock
hl.bind(mainMod .. " + m", hl.dsp.exec_cmd("hyprlock"))

-- Characters
hl.bind(mainMod .. " + SEMICOLON", hl.dsp.exec_cmd("gnome-characters"))

-- Media keys
hl.bind("F8", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("F9", hl.dsp.exec_cmd("playerctl next"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume=2 --max-volume=100"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume=-2 --max-volume=100"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume=mute-toggle --max-volume=100"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +2"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -2"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-------------------------------
--- WINDOWS AND WORKSPACES ----
-------------------------------

if is_laptop then
  for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" })
  end
else
  -- DP-3 main gets 1, 3, 5
  hl.workspace_rule({ workspace = "1", monitor = "DP-3" })
  hl.workspace_rule({ workspace = "3", monitor = "DP-3" })
  hl.workspace_rule({ workspace = "5", monitor = "DP-3" })

  -- HDMI-A-1 secondary gets 2, 4, 6
  hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
  hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1" })
  hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1" })
end

-- Optional test workspace for the new scrolling layout + scroll_move gesture.
-- Uncomment this together with the 4-finger scroll_move gesture above.
-- hl.workspace_rule({ workspace = "7", layout = "scrolling" })

-- Calendar Manager
hl.window_rule({
  name = "calendar-manager-float",
  match = { class = "^(org.gnome.Calendar)$" },
  float = true,
  center = true,
  size = { 700, 700 },
})

-- Bluetooth Manager
hl.window_rule({
  name = "blueman-manager-float",
  match = { class = "^(blueman-manager)$" },
  float = true,
  center = true,
  size = { 700, 500 },
})

-- Pavucontrol
hl.window_rule({
  name = "pavucontrol-float",
  match = { class = "^(org.pulseaudio.pavucontrol)$" },
  float = true,
  center = true,
  size = { 1000, 500 },
})

-- GNOME Calculator
hl.window_rule({
  name = "gnome-calculator-float",
  match = { class = "^(org.gnome.Calculator)$" },
  float = true,
  center = true,
  size = { 420, 560 },
})

-- GNOME Characters
hl.window_rule({
  name = "gnome-characters-float",
  match = { class = "^(org.gnome.Characters)$" },
  float = true,
  center = true,
  size = { 700, 500 },
})

-- App opacity
hl.window_rule({ name = "set-dolphin-transparency", match = { class = "^(org.kde.dolphin)$" }, opacity = "1 0.94" })
hl.window_rule({ name = "set-google-chrome-transparency", match = { class = "^(google-chrome)$" }, opacity = "1 0.96" })
hl.window_rule({ name = "set-vscode-transparency", match = { class = "^(code)$" }, opacity = "1 0.94" })
hl.window_rule({ name = "set-intellij-transparency", match = { class = "^(jetbrains-.*)$" }, opacity = "1 0.94" })

-- Focus behavior
hl.window_rule({
  name = "jetbrains-no-focus-steal",
  match = { class = "^(jetbrains-.*)$" },
  no_initial_focus = true,
})

hl.window_rule({
  name = "zoom-no-focus-steal",
  match = { class = "^(zoom)$" },
  no_initial_focus = true,
})

-- Ignore maximize requests from all apps
hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
  name = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move = { "20", "monitor_h-120" },
  float = true,
})

-- Layer rules
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "wofi" }, blur = true })
hl.layer_rule({ match = { namespace = "wofi" }, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "swayosd" }, blur = true })
hl.layer_rule({ match = { namespace = "swayosd" }, ignore_alpha = 0.3 })
