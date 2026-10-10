local helper = os.getenv("HOME") .. "/.config/walker/scripts/actions/install/software.py"
local function quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end
function Toggle(value)
    if value == "" then return end
    local selected = state()
    local next = {}
    local found = false
    for _, name in ipairs(selected) do
        if name == value then found = true else table.insert(next, name) end
    end
    if not found then table.insert(next, value) end
    setState(next)
end
function Install(value)
    local selected = state()
    if #selected == 0 and value ~= "" then selected = {value} end
    if #selected == 0 then return end
    local command = "python3 " .. quote(helper) .. " launch " .. quote(PackageSource)
    for _, name in ipairs(selected) do command = command .. " " .. quote(name) end
    local result = os.execute(command)
    if result == 0 or result == true then setState({}) end
end
function GetEntries(query)
    local handle = io.popen("python3 " .. quote(helper) .. " search " .. quote(PackageSource) .. " " .. quote(query or ""))
    if not handle then return {} end
    local output = handle:read("*a"); handle:close()
    local entries, selected = {}, state()
    local marked = {}
    for _, name in ipairs(selected) do marked[name] = true end
    for _, row in ipairs(jsonDecode(output)) do
        local actions = {}
        if row.name ~= "" then
            actions = {package_toggle = "lua:Toggle", package_install = "lua:Install",
                package_review = "python3 " .. quote(helper) .. " review " .. quote(PackageSource) .. " " .. quote(row.name)}
        end
        table.insert(entries, {Text = row.name ~= "" and row.name or "Search packages",
            Subtext = row.description .. " · " .. #selected .. " selected",
            Value = row.name, Icon = marked[row.name] and "" or "󰏖",
            State = marked[row.name] and {"selected"} or {}, Actions = actions})
    end
    return entries
end
