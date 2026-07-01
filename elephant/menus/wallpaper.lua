Name = "wallpaper"
NamePretty = "Wallpaper"
Parent = "style"
Icon = "🖻"
FixedOrder = true

local home = os.getenv("HOME")
local background_dir = home .. "/.config/theme/current/backgrounds"

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
    local entries = {}
    local cmd = "find '" .. background_dir .. "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%f\\n' 2>/dev/null | sort -V"
    local handle = io.popen(cmd)

    if handle then
        for file in handle:lines() do
            local path = background_dir .. "/" .. file
            table.insert(entries, {
                Text = file,
                Value = path,
                Icon = path,
                Preview = path,
                PreviewType = "file",
                Actions = {
                    open = home .. "/.config/walker/scripts/actions/wallpaper/apply.sh " .. shell_quote(path),
                },
            })
        end
        handle:close()
    end

    return entries
end
