local home = os.getenv("HOME")
local themes_dir = home .. "/.config/themes"

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function current_theme()
    local file = io.open(home .. "/.cache/current-theme", "r")
    if not file then return "" end
    local name = file:read("*a"):match("^%s*(.-)%s*$")
    file:close()
    return name
end

local function display_name(name)
    return (name:gsub("[-_]", " "):gsub("(%a)([%w]*)", function(first, rest)
        return first:upper() .. rest
    end))
end

return function(category)
    return function()
        local entries = {}
        local current = current_theme()
        local handle = io.popen("find " .. shell_quote(themes_dir) .. " -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null | sort")
        if not handle then return entries end

        for theme in handle:lines() do
            local theme_dir = themes_dir .. "/" .. theme
            local marker = io.open(theme_dir .. "/light.mode", "r")
            local is_light = marker ~= nil
            if marker then marker:close() end
            if (category == "light") == is_light then
                table.insert(entries, {
                    Text = display_name(theme),
                    Value = theme,
                    Icon = theme == current and "" or "󰸌",
                    State = theme == current and { "current" } or {},
                    Preview = theme_dir .. "/preview.png",
                    PreviewType = "file",
                    Actions = {
                        theme_apply = home .. "/.config/walker/scripts/actions/style/apply.sh " .. shell_quote(theme),
                        theme_preview = home .. "/.config/walker/scripts/actions/style/preview.sh " .. shell_quote(theme),
                    },
                })
            end
        end
        handle:close()
        return entries
    end
end
