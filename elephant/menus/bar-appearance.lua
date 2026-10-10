Name = "bar-appearance"
NamePretty = "Appearance"
Parent = "bar"
Icon = "󰏘"
FixedOrder = true

local entries = dofile(os.getenv("HOME") .. "/.config/elephant/bar-settings-entries.lua")
function GetEntries()
    return entries("appearance", {
        {"Blur", "transparent", "󰐾"},
        {"Theme Color", "solid", "󰏘"},
    })
end

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
