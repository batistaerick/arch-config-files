Name = "packages-aur"
NamePretty = "Yay (AUR)"
Parent = "install"
Icon = "󰏖"
FixedOrder = true
PackageSource = "aur"
dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/package-menu.lua")
