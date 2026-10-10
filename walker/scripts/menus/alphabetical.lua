-- Preserve fixed menu ordering while sorting dynamically generated labels.
local originalGetEntries = GetEntries
function GetEntries(...)
    local entries = originalGetEntries(...)
    table.sort(entries, function(a, b)
        local left, right = tostring(a.Text or ""):lower(), tostring(b.Text or ""):lower()
        if left == right then return tostring(a.Value or "") < tostring(b.Value or "") end
        return left < right
    end)
    return entries
end
