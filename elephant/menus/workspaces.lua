Name = "workspaces"
NamePretty = "Workspaces"
Parent = "style"
Icon = "󰍹"
FixedOrder = true

local script = os.getenv("HOME") .. "/.config/quickshell/desktop-bar/scripts/workspace-style.py"
local quote = dofile(os.getenv("HOME") .. "/.config/elephant/shell-quote.lua")

function GetEntries()
    local current = "Numbers"
    local reader = io.popen("python3 " .. quote(script) .. " current")
    if reader then current = reader:read("*l") or current; reader:close() end
    local choices = {"Numbers", "Glyph", "Dots"}
    local entries = {}
    for _, choice in ipairs(choices) do
        local state = {"workspace-" .. choice:lower()}
        if choice == current then table.insert(state, "current") end
        table.insert(entries, {
            Text = choice, Value = choice,
            Icon = choice == current and "" or "󰍹",
            State = state,
            Actions = {open = "python3 " .. quote(script) .. " " .. quote(choice)},
        })
    end
    return entries
end

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
