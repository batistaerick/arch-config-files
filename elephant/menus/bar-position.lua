Name = "bar-position"
NamePretty = "Position"
Parent = "bar"
Icon = "󰆾"
FixedOrder = true

local entries = dofile(os.getenv("HOME") .. "/.config/elephant/bar-settings-entries.lua")
function GetEntries()
    return entries("edge", {
        {"Top", "top", "󰁝"},
        {"Bottom", "bottom", "󰁅"},
        {"Left", "left", "󰁍"},
        {"Right", "right", "󰁔"},
    })
end
