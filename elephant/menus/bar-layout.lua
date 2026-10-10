Name = "bar-layout"
NamePretty = "Layout"
Parent = "bar"
Icon = "󰕰"
FixedOrder = true

local entries = dofile(os.getenv("HOME") .. "/.config/elephant/bar-settings-entries.lua")
function GetEntries()
    return entries("layout", {
        {"One Bar", "unified", "󰍜"},
        {"Three Sections", "split", "󰕰"},
    })
end

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
