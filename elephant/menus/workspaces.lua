Name = "workspaces"
NamePretty = "Workspaces"
Parent = "style"
Icon = "󰍹"
FixedOrder = true

local script = os.getenv("HOME") .. "/.config/quickshell/desktop-bar/scripts/workspace-style.py"
local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
    local current = "Numbers"
    local reader = io.popen("python3 " .. quote(script) .. " current")
    if reader then current = reader:read("*l") or current; reader:close() end
    local choices = {
        {"Numbers", "1 2 3 4"},
        {"Glyph", "✦ ✧ · ·"},
        {"Dots", "● ● ● ▰"},
    }
    local entries = {}
    for _, choice in ipairs(choices) do
        table.insert(entries, {
            Text = choice[1], Subtext = choice[2], Value = choice[1],
            Icon = choice[1] == current and "" or "󰍹",
            State = choice[1] == current and {"current"} or {},
            Actions = {open = "python3 " .. quote(script) .. " " .. quote(choice[1])},
        })
    end
    return entries
end
