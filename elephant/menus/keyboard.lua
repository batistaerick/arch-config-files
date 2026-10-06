Name = "keyboard"
NamePretty = "Keyboard"
Parent = "system"
Icon = "󰌌"
FixedOrder = true

local script = os.getenv("HOME") .. "/.config/quickshell/desktop-bar/scripts/keyboard-layout.py"
local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
    local entries = {}
    local reader = io.popen("python3 " .. quote(script) .. " list")
    if reader then
        for line in reader:lines() do
            local index, label, active = line:match("^(%d+)\t(.-)\t([01])$")
            if index then
                table.insert(entries, {
                    Text = label, Value = index,
                    Icon = active == "1" and "" or "󰌌",
                    State = active == "1" and {"current"} or {},
                    Actions = {open = "python3 " .. quote(script) .. " select " .. index},
                })
            end
        end
        reader:close()
    end
    return entries
end
