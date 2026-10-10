Name = "projects-vscode"
NamePretty = "VS Code Projects"
Parent = "development"
Icon = ""
FixedOrder = true

local project_entries = dofile(os.getenv("HOME") .. "/.config/elephant/project-entries.lua")

GetEntries = project_entries({ root = "", project = "" }, function(path)
    return "code " .. path
end)

dofile(os.getenv("HOME") .. "/.config/walker/scripts/menus/alphabetical.lua")
