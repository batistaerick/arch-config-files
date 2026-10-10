Name = "lockscreen"
NamePretty = "Lockscreen"
Parent = "style"
Icon = "󰌾"
FixedOrder = true

local root = os.getenv("HOME") .. "/.config/quickshell/lockscreen/scripts/"
local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
    local entries = {}
    local current = "hyprlock"
    local state = io.open(os.getenv("HOME") .. "/.config/lockscreen/selected", "r")
    if state then current = state:read("*a"):match("^%s*(.-)%s*$"); state:close() end
    local list = io.popen("python3 " .. quote(root .. "settings.py") .. " list")
    if list then
        for line in list:lines() do
            local value, label = line:match("^(.-)\t(.*)$")
            if value then
                table.insert(entries, {
                    Text = label, Value = value,
                    Icon = value == current and "" or "󰌾",
                    State = value == current and {"current"} or {},
                    Preview = value ~= "hyprlock" and os.getenv("HOME") .. "/.config/quickshell/lockscreen/themes/" .. value .. "/preview.png" or "",
                    PreviewType = "file",
                    Actions = {
                        lockscreen_apply = "bash " .. quote(root .. "launch.sh") .. " select " .. quote(value),
                        lockscreen_preview = "bash " .. quote(root .. "preview.sh") .. " " .. quote(value),
                    },
                })
            end
        end
        list:close()
    end
    return entries
end

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
