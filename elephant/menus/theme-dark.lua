Name = "theme-dark"
NamePretty = "Dark"
Parent = "theme"
Icon = "󰖔"
FixedOrder = true

GetEntries = dofile(os.getenv("HOME") .. "/.config/elephant/theme-entries.lua")("dark")
