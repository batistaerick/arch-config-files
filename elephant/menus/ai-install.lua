Name = "ai-install"
NamePretty = "Install AI CLIs"
Parent = "ai-tools"
Icon = "󱜙"
FixedOrder = true
SoftwareGroup = "ai"
dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/software-menu.lua")

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
