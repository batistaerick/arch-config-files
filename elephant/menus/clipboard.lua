Name = "clipboard"
NamePretty = "Clipboard History"
Icon = "edit-paste"
FixedOrder = true

local helper = os.getenv("HOME") .. "/.config/walker/scripts/menus/clipboard.py"
local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
    local handle = io.popen("python3 " .. quote(helper))
    if not handle then return {} end
    local output = handle:read("*a")
    handle:close()
    local entries = {}
    for _, row in ipairs(jsonDecode(output)) do
        table.insert(entries, {
            Text = row.label,
            Value = row.id,
            Icon = row.preview ~= "" and "image-x-generic" or "edit-paste",
            Preview = row.preview,
            PreviewType = row.preview ~= "" and "file" or "",
            Actions = {
                clipboard_paste = "python3 " .. quote(helper) .. " paste " .. quote(row.id),
                clipboard_delete = "python3 " .. quote(helper) .. " delete " .. quote(row.id),
            },
        })
    end
    return entries
end
