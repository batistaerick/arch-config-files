Name = "apps"
NamePretty = "Apps"
Parent = "main"
Icon = "󰣇"
FixedOrder = false
SearchName = true

local home = os.getenv("HOME")
local app_dirs = {
    home .. "/.local/share/applications",
    "/usr/local/share/applications",
    "/usr/share/applications",
}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function basename(path)
    return path:match("([^/]+)$") or path
end

local function desktop_id(path)
    return basename(path)
end

local function parse_desktop_file(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local entry = {}
    local in_desktop_entry = false

    for line in file:lines() do
        if line == "[Desktop Entry]" then
            in_desktop_entry = true
        elseif line:match("^%[") then
            in_desktop_entry = false
        elseif in_desktop_entry then
            local key, value = line:match("^([%w%-]+)%s*=%s*(.*)$")
            if key and value then
                entry[key] = value
            end
        end
    end

    file:close()
    return entry
end

local function is_visible_app(entry)
    if not entry then
        return false
    end

    if entry.Type ~= "Application" then
        return false
    end

    if not entry.Name or entry.Name == "" then
        return false
    end

    if not entry.Exec or entry.Exec == "" then
        return false
    end

    if entry.NoDisplay == "true" or entry.Hidden == "true" then
        return false
    end

    return true
end

function GetEntries()
    local entries = {}
    local seen = {}

    for _, dir in ipairs(app_dirs) do
        local handle = io.popen("find " .. shell_quote(dir) .. " -maxdepth 1 -type f -name '*.desktop' 2>/dev/null | sort")

        if handle then
            for path in handle:lines() do
                local id = desktop_id(path)

                if not seen[id] then
                    local app = parse_desktop_file(path)

                    if is_visible_app(app) then
                        seen[id] = true

                        local keywords = {}
                        if app.Keywords then
                            for keyword in app.Keywords:gmatch("[^;]+") do
                                table.insert(keywords, keyword)
                            end
                        end

                        if app.GenericName then
                            table.insert(keywords, app.GenericName)
                        end

                        table.insert(entries, {
                            Text = app.Name,
                            Subtext = app.GenericName or app.Comment or id,
                            Value = id,
                            Icon = app.Icon or "application-x-executable",
                            Keywords = keywords,
                            Actions = {
                                open = "gtk-launch " .. shell_quote(id),
                            },
                        })
                    end
                end
            end

            handle:close()
        end
    end

    table.sort(entries, function(a, b)
        return a.Text:lower() < b.Text:lower()
    end)

    return entries
end
