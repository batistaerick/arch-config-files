Name = "projects-nvim"
NamePretty = "Neovim Projects"
Parent = "development"
Icon = ""
FixedOrder = true

local home = os.getenv("HOME")
local dev_dir = home .. "/Development"

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
    local entries = {
        {
            Text = "Open Development",
            Value = dev_dir,
            Icon = "",
            Actions = { open = "kitty --directory " .. shell_quote(dev_dir) .. " -e nvim ." },
        },
    }

    local cmd = "find '" .. dev_dir .. "' -mindepth 3 -maxdepth 3 -type d -name .git 2>/dev/null | sed 's|" .. dev_dir .. "/||; s|/.git||' | sort"
    local handle = io.popen(cmd)

    if handle then
        for project in handle:lines() do
            local path = dev_dir .. "/" .. project
            table.insert(entries, {
                Text = project,
                Value = path,
                Icon = "",
                Actions = { open = "kitty --directory " .. shell_quote(path) .. " -e nvim ." },
            })
        end
        handle:close()
    end

    return entries
end
