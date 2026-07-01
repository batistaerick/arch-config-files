Name = "theme"
NamePretty = "Theme"
Parent = "style"
Icon = "󰸌"
FixedOrder = true

local home = os.getenv("HOME")
local themes_dir = home .. "/.config/themes"

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
    local entries = {}
    local handle = io.popen("find '" .. themes_dir .. "' -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null | sort")

    if handle then
        for theme in handle:lines() do
            table.insert(entries, {
                Text = theme,
                Value = theme,
                Icon = "󰸌",
                Preview = themes_dir .. "/" .. theme .. "/preview.png",
                PreviewType = "file",
                Actions = {
                    open = home .. "/.config/walker/scripts/actions/style/apply.sh " .. shell_quote(theme),
                },
            })
        end
        handle:close()
    end

    return entries
end
