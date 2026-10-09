.pragma library

function ceiling(workspaces, focusedId) {
    var highest = Math.max(5, Number(focusedId) || 0);
    for (var workspace of workspaces) highest = Math.max(highest, Number(workspace.id) || 0);
    return Math.min(10, highest);
}

function occupied(toplevels) {
    var groups = {};
    for (var window of toplevels) {
        var id = window.workspace ? window.workspace.id : 0;
        var info = window.lastIpcObject || {};
        if (!Number.isInteger(id) || id < 1 || id > 10 || info.mapped === false || info.hidden === true) continue;
        if (!groups[id]) groups[id] = {id: id, windows: [], monitorName: window.monitor ? window.monitor.name : ""};
        groups[id].windows.push(window);
    }
    return Object.keys(groups).map(key => groups[key]).sort((a, b) => a.id - b.id);
}

// Normalize each workspace's window geometry without changing compositor state.
function bounds(windows) {
    var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    for (var window of windows) {
        var info = window.lastIpcObject || {};
        var at = info.at || [0, 0], size = info.size || [800, 600];
        minX = Math.min(minX, at[0]); minY = Math.min(minY, at[1]);
        maxX = Math.max(maxX, at[0] + Math.max(1, size[0]));
        maxY = Math.max(maxY, at[1] + Math.max(1, size[1]));
    }
    return {x: isFinite(minX) ? minX : 0, y: isFinite(minY) ? minY : 0,
        width: Math.max(1, isFinite(maxX - minX) ? maxX - minX : 1),
        height: Math.max(1, isFinite(maxY - minY) ? maxY - minY : 1)};
}
