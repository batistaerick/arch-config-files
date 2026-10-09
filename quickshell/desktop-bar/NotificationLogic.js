.pragma library

function ignored(appName) {
    return /^(kitty|terminal)$/i.test(appName || "");
}

function popupDuration(notification) {
    if (notification.urgency === 2 || notification.expireTimeout === 0) return 0;
    return notification.expireTimeout > 0 ? notification.expireTimeout : 6500;
}

function grouped(notifications, timestamps) {
    var groups = {};
    notifications.filter(n => !n.transient).forEach(n => {
        var name = n.appName || "Application";
        if (!groups[name]) groups[name] = [];
        groups[name].push(n);
    });
    return Object.keys(groups).sort((a, b) => {
        var newest = name => Math.max.apply(null, groups[name].map(n => timestamps[n.id] || 0));
        return newest(b) - newest(a);
    }).map(name => ({name: name, notifications: groups[name].sort((a, b) => (timestamps[b.id] || 0) - (timestamps[a.id] || 0))}));
}
