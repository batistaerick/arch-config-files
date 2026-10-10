Name = "languages"
NamePretty = "Languages & Frameworks"
Parent = "install"
Icon = "󰅩"
FixedOrder = true
SoftwareGroup = "languages"
dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/software-menu.lua")

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
