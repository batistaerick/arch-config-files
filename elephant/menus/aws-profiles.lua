Name = "aws-profiles"
NamePretty = "AWS"
Parent = "cloud"
Icon = ""
FixedOrder = true

GetEntries = dofile(os.getenv("HOME") .. "/.config/elephant/aws-profile-entries.lua")("menu.sh", "")

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
