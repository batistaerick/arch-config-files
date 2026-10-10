local helper = os.getenv("HOME") .. "/.config/walker/scripts/actions/install/software.py"
local quote = dofile(os.getenv("HOME") .. "/.config/elephant/shell-quote.lua")
function GetEntries()
    local handle = io.popen("python3 " .. quote(helper) .. " recipes " .. quote(SoftwareGroup))
    if not handle then return {} end
    local output = handle:read("*a"); handle:close()
    local entries = {}
    for _, row in ipairs(jsonDecode(output)) do
        if row.id then
            table.insert(entries, {Text = row.label, Value = row.id,
                Subtext = row.manager or (row.source == "aur" and "AUR · review before installing" or row.source),
                Icon = Icon, Actions = {open = "python3 " .. quote(helper) .. " recipe-launch " ..
                    quote(SoftwareGroup) .. " " .. quote(row.id)}})
        end
    end
    return entries
end
