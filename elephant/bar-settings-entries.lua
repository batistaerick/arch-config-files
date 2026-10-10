local script = os.getenv("HOME") .. "/.config/quickshell/desktop-bar/scripts/bar-settings.py"
local quote = dofile(os.getenv("HOME") .. "/.config/elephant/shell-quote.lua")

return function(key, choices)
    local current = ""
    local reader = io.popen("python3 " .. quote(script) .. " get " .. key)
    if reader then current = reader:read("*l") or ""; reader:close() end
    local entries = {}
    for _, choice in ipairs(choices) do
        local selected = current == choice[2]
        table.insert(entries, {
            Text = choice[1], Value = choice[2],
            Icon = selected and "" or choice[3],
            State = selected and {"current"} or {},
            Actions = {open = "python3 " .. quote(script) .. " set " .. key .. " " .. choice[2]},
        })
    end
    return entries
end
