-- Detect whether this session is running on the laptop panel or the desktop monitors.
-- DRM status files contain "connected" or "disconnected"; match whole lines only.
local function drm_output_connected(output_glob)
	local handle = io.popen("cat /sys/class/drm/card*-" .. output_glob .. "/status 2>/dev/null")
	if not handle then
		return false
	end

	local status = handle:read("*a") or ""
	handle:close()

	return ("\n" .. status):match("\nconnected") ~= nil
end

local is_laptop = drm_output_connected("eDP-*")
local has_hdmi = drm_output_connected("HDMI-A-1")
local portable_config = io.open(os.getenv("HOME") .. "/.config/hypr/portable.mode", "r")
local portable_mode = portable_config ~= nil
if portable_config then
	portable_config:close()
end

-------------
-- Themes --
-------------

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

local active_border_color = "rgba(33ccffee)"
local palette_file = io.open(os.getenv("HOME") .. "/.config/theme/current/colors.toml", "r")
if palette_file then
	for line in palette_file:lines() do
		local accent = line:match('^%s*accent%s*=%s*"#(%x%x%x%x%x%x)"')
		if accent then
			active_border_color = "rgba(" .. accent .. "ee)"
			break
		end
	end
	palette_file:close()
end

--------------
-- Monitors --
--------------

if portable_mode then
	hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
elseif is_laptop then
	hl.monitor({
		output = "eDP-1",
		mode = "1920x1080@60",
		position = "0x0",
		scale = 1,
	})
else
	hl.monitor({
		output = "DP-3",
		mode = "2560x1080@144",
		position = "0x0",
		scale = 1,
		bitdepth = 10,
		supports_wide_color = 1,
		supports_hdr = 1,
	})

	if has_hdmi then
		hl.monitor({
			output = "HDMI-A-1",
			mode = "1920x1080@144",
			position = "320x1080",
			scale = 1,
			bitdepth = 10,
			supports_wide_color = 1,
			supports_hdr = 1,
		})
	end
end

--------------
-- Commands --
--------------

local terminal = "kitty"
local fileManager = "dolphin"
local mainMod = "SUPER"

local scriptsDir = "~/.config/walker/scripts"
local menusDir = scriptsDir .. "/menus"
local actionsDir = scriptsDir .. "/actions"
local hyprScriptsDir = "~/.config/hypr/scripts"

---------------
-- Autostart --
---------------

hl.on("hyprland.start", function()
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("quickshell -n -c desktop-bar --daemonize")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("hyprsunset")
	hl.exec_cmd("~/.config/walker/scripts/actions/toggle/nightlight-auto.sh")
	hl.exec_cmd("swayosd-server --style ~/.config/swayosd/style.css")
	hl.exec_cmd("rm -f ~/.cache/cliphist/db")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-----------------
-- Environment --
-----------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-------------------
-- Look And Feel --
-------------------

hl.config({
	render = {
		cm_enabled = true,
		send_content_type = true,
		cm_auto_hdr = 1,
		direct_scanout = 2,
		use_fp16 = 2,
	},
	quirks = {
		prefer_hdr = 2,
	},
	general = {
		gaps_in = 6,
		gaps_out = 12,
		border_size = 2,
		col = {
			active_border = {
				colors = {
					active_border_color,
				},
				angle = 45,
			},
			inactive_border = "rgba(595959aa)",
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},
	decoration = {
		rounding = 4,
		rounding_power = 4,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 2,
			vibrancy = 0.2,
		},
	},
	animations = {
		enabled = true,
	},
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = false, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = false, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

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
		focus_on_activate = true,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = -1,
	},
})

-----------
-- Input --
-----------

local keyboard_ok, keyboard_layouts = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/keyboard-layouts.lua")
if not keyboard_ok or type(keyboard_layouts) ~= "table" then
	keyboard_layouts = { layout = "us,us", variant = ",intl" }
end

hl.config({
	input = {
		sensitivity = 0,
		follow_mouse = 1,
		kb_model = "",
		kb_rules = "",
		kb_layout = keyboard_layouts.layout,
		kb_variant = keyboard_layouts.variant,
		kb_options = "grp:alt_shift_toggle",
		touchpad = {
			natural_scroll = false,
		},
	},
})

-- Your original 3-finger horizontal workspace gesture.
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- hl.gesture({
--   fingers = 4,
--   direction = "horizontal",
--   action = "scroll_move",
--   scale = 1.0,
-- })

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-----------------
-- Keybindings --
-----------------

-- Launchers and app helpers
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + CTRL + return", hl.dsp.exec_cmd("kitty -e tmux new-session -A -s main"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager .. " --new-window"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("kitty --class fif-terminal -e zsh -c 'source ~/.zshrc; fif; kill -9 $$'"))
hl.bind(
	mainMod .. " + CTRL + P",
	hl.dsp.exec_cmd([[kitty --class fifs-terminal -e zsh -c 'source ~/.zshrc; fifs; exit 0']])
)
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("sleep 0.08; wtype -M ctrl c -m ctrl"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("sleep 0.08; wtype -M ctrl x -m ctrl"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("sleep 0.08; wtype -M ctrl v -m ctrl"))
hl.bind(
	mainMod .. " + CTRL + V",
	hl.dsp.exec_cmd(
		"$HOME/.config/walker/bin/walker --provider menus:clipboard --width 850"
	)
)

-- Window state and layout
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.window.pin())
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + A", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.layout("rotatesplit"))

-- Focus with vim-style keys
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))

-- Resize active window
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.resize({ x = -15, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.resize({ x = 0, y = 15, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.resize({ x = 0, y = -15, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.resize({ x = 15, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + u", hl.dsp.exec_cmd(hyprScriptsDir .. "/window-quarter-size.sh"))

-- Move active window
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ direction = "r" }))

-- Workspaces 1-10. The bar starts at 1-5 and expands sequentially on demand.
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("quickshell ipc -c desktop-bar call -- panels show overview"))
for i = 1, 10 do
	local key = tostring(i % 10)
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + CTRL + S", hl.dsp.window.move({ workspace = 1 }))

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + ALT + h", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + ALT + l", hl.dsp.focus({ workspace = "e+1" }))

-- Walker menus and scripts
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menusDir .. "/search.sh"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(menusDir .. "/shortcuts.sh"))
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.exec_cmd(menusDir .. "/vim.sh"))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("$HOME/.config/walker/bin/walker --provider menus:main"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("bash $HOME/.config/quickshell/desktop-bar/scripts/appearance-picker.sh wallpaper"))
hl.bind(mainMod .. " + CTRL + SHIFT + N", hl.dsp.exec_cmd("bash $HOME/.config/quickshell/desktop-bar/scripts/appearance-picker.sh theme"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(actionsDir .. "/search/google.sh"))

hl.bind("PRINT", hl.dsp.exec_cmd(actionsDir .. "/capture/screenshot-full.sh"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(actionsDir .. "/capture/screenshot-selection.sh"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd(actionsDir .. "/capture/screenshot.sh window edit"))
hl.bind(mainMod .. " + CTRL + PRINT", hl.dsp.exec_cmd(actionsDir .. "/capture/text.sh"))
hl.bind(mainMod .. " + ALT + PRINT", hl.dsp.exec_cmd(actionsDir .. "/capture/qr.sh"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(actionsDir .. "/wallpaper/next.sh"))
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.exec_cmd(actionsDir .. "/toggle/desktop-bar.sh"))

-- Desktop utilities
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("quickshell ipc -c desktop-bar call -- notifications toggle"))
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + m", hl.dsp.exec_cmd(hyprScriptsDir .. "/manual-lock.sh"))
hl.bind(mainMod .. " + SEMICOLON", hl.dsp.exec_cmd(actionsDir .. "/emoji-picker.sh"))

-- Media keys
hl.bind("F8", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("F9", hl.dsp.exec_cmd("playerctl next"))

-- Hardware keys
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume=2 --max-volume=100"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume=-2 --max-volume=100"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("swayosd-client --output-volume=mute-toggle --max-volume=100"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +2"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -2"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Mouse window manipulation
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

----------------------------
-- Windows And Workspaces --
----------------------------

if not portable_mode then
	if is_laptop then
		for i = 1, 4 do
			hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" })
		end
	elseif has_hdmi then
		-- Main monitor
		hl.workspace_rule({ workspace = "1", monitor = "DP-3" })
		hl.workspace_rule({ workspace = "2", monitor = "DP-3" })

		-- Secondary monitor
		hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })
		hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1" })
	else
		for i = 1, 4 do
			hl.workspace_rule({ workspace = tostring(i), monitor = "DP-3" })
		end
	end
end

-- Optional test workspace for the new scrolling layout + scroll_move gesture.
-- Uncomment this together with the 4-finger scroll_move gesture above.
-- hl.workspace_rule({ workspace = "7", layout = "scrolling" })

local function floating_window_rule(name, class, size, move)
	local rule = {
		name = name,
		match = { class = class },
		float = true,
		size = size,
	}

	if move == "top-right" then
		rule.move = { "monitor_w-" .. tostring(size[1]) .. "-10", "40" }
	elseif move == "top-center" then
		rule.move = { "monitor_w*0.5-" .. tostring(size[1] / 2), "40" }
	elseif move == "top-left" then
		rule.move = { "10", "40" }
	elseif move then
		rule.move = move
	else
		rule.center = true
	end

	hl.window_rule(rule)
end

local function opacity_rule(name, class, opacity)
	hl.window_rule({
		name = name,
		match = { class = class },
		opacity = opacity,
	})
end

local function blurred_layer(namespace, ignore_alpha)
	hl.layer_rule({ match = { namespace = namespace }, blur = true })
	hl.layer_rule({ match = { namespace = namespace }, ignore_alpha = ignore_alpha })
end

-- Floating utility windows
local topRightPanelPosition = "top-right"

floating_window_rule("blueman-manager-float", "^(blueman-manager)$", { 700, 480 }, topRightPanelPosition)
floating_window_rule("setup-wifi-float", "^(setup-wifi)$", { 700, 480 }, topRightPanelPosition)
floating_window_rule("gnome-calculator-float", "^(org.gnome.Calculator)$", { 420, 560 })
floating_window_rule("gnome-characters-float", "^(org.gnome.Characters)$", { 700, 500 })
floating_window_rule("imv-float", "^(imv)$", { 1400, 850 })
floating_window_rule("screenshot-editor-float", "^(dev.local.ScreenshotEditor)$", { 1100, 720 })
floating_window_rule("fif-terminal-float", "^(fif-terminal)$", { 1000, 650 })
floating_window_rule("fifs-terminal-float", "^(fifs-terminal)$", { 1500, 800 })
floating_window_rule("cloud-terminal-float", "^(cloud-terminal)$", { 1700, 950 })
floating_window_rule("about-terminal-float", "^(about-terminal)$", { 1000, 490 })

-- App opacity
opacity_rule("set-dolphin-transparency", "^(org.kde.dolphin)$", "1 0.94")
opacity_rule("set-google-chrome-transparency", "^(google-chrome)$", "1 0.96")
opacity_rule("set-vscode-transparency", "^(code)$", "1 0.94")

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

-- Hyprland-run launcher position
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = { "20", "monitor_h-120" },
	float = true,
})

-- Layer rules
blurred_layer("desktop-bar", 0.2)
hl.layer_rule({ match = { namespace = "desktop-bar" }, blur_popups = true })
hl.layer_rule({
	name = "walker-blur",
	match = { namespace = "walker" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.8,
})
blurred_layer("desktop-notifications", 0.2)
blurred_layer("desktop-reload-error", 0.2)
blurred_layer("desktop-overview", 0.2)
-- The overview owns its preview animation; keep its blur and workspace jumps instant.
hl.layer_rule({ match = { namespace = "desktop-overview" }, no_anim = true })
blurred_layer("swayosd", 0.3)
