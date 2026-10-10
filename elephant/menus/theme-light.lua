Name = "theme-light"
NamePretty = "Light"
Parent = "theme"
Icon = "󰖙"
FixedOrder = true

GetEntries = dofile(os.getenv("HOME") .. "/.config/elephant/theme-entries.lua")("light")

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
