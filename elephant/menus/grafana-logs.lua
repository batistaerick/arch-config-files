Name = "grafana-logs"
NamePretty = "Grafana Logs"
Parent = "development"
Icon = "󰨇"
FixedOrder = true

GetEntries = dofile(os.getenv("HOME") .. "/.config/elephant/aws-profile-entries.lua")("grafana.sh", "󰨇")

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
