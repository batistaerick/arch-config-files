Name = "packages-pacman"
NamePretty = "Pacman"
Parent = "install"
Icon = "󰏖"
FixedOrder = true
PackageSource = "pacman"
dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/package-menu.lua")
