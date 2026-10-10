-- One entry per AWS profile, as listed by the cloud menus' shared helper
-- (EITR_AWS_PROFILES in ~/.config/eitr/cloud.env, else `aws configure list-profiles`).
local home = os.getenv("HOME")
local shell_quote = dofile(home .. "/.config/elephant/shell-quote.lua")
local aws_dir = home .. "/.config/walker/scripts/menus/cloud/aws"

-- script: file in aws_dir run with the profile; icon: entry icon.
return function(script, icon)
    return function()
        local entries = {}
        local handle = io.popen(shell_quote(aws_dir .. "/menu.sh") .. " --list-profiles 2>/dev/null")
        if not handle then return entries end

        for line in handle:lines() do
            local label, profile = line:match("^([^\t]+)\t(.+)$")
            if label then
                table.insert(entries, {
                    Text = label,
                    Subtext = label ~= profile and profile or nil,
                    Value = profile,
                    Icon = icon,
                    Actions = { open = shell_quote(aws_dir .. "/" .. script) .. " " .. shell_quote(profile) },
                })
            end
        end
        handle:close()
        return entries
    end
end
