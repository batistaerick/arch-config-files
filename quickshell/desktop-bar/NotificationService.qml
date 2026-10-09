import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "NotificationLogic.js" as Logic

Item {
    id: service
    property bool doNotDisturb: false
    property bool centerOpen: false
    property var timestamps: ({})
    property var popupDeadlines: ({})
    property var popupIds: []
    property var pausedPopupIds: []
    signal toggleRequested()
    readonly property var all: server.trackedNotifications.values
    readonly property var history: all.filter(n => !n.transient)
    readonly property var groups: Logic.grouped(all, timestamps)
    readonly property int count: history.length
    readonly property var popups: all.filter(n => popupIds.indexOf(n.id) !== -1).slice(-4).reverse()

    // Senders such as Satty delete their thumbnail file on exit. Keep the decoded
    // image alive immediately, even when popups are hidden or DND is enabled.
    // Cards use the identical source/size so they share Qt's in-memory image cache.
    Repeater {
        model: service.all
        Image {
            required property var modelData
            visible: false
            source: Logic.imageSource(modelData)
            asynchronous: false
            cache: true
        }
    }

    function hidePopup(id) {
        popupIds = popupIds.filter(value => value !== id);
    }
    function pausePopup(id, paused) {
        pausedPopupIds = pausedPopupIds.filter(value => value !== id);
        if (paused) pausedPopupIds = pausedPopupIds.concat([id]);
        else if (popupDeadlines[id]) {
            var deadlines = Object.assign({}, popupDeadlines);
            deadlines[id] = Math.max(deadlines[id], Date.now() + 1500);
            popupDeadlines = deadlines;
        }
    }
    function clear() {
        all.slice().forEach(n => n.dismiss());
        popupIds = [];
    }
    function clearApp(appName) {
        all.slice().filter(n => (n.appName || "Application") === appName).forEach(n => n.dismiss());
    }
    function toggleDnd() {
        doNotDisturb = !doNotDisturb;
        settings.setText(JSON.stringify({doNotDisturb: doNotDisturb}) + "\n");
        return doNotDisturb;
    }
    onDoNotDisturbChanged: if (doNotDisturb) popupIds = []
    onCenterOpenChanged: if (centerOpen) popupIds = []
    onAllChanged: {
        var ids = all.map(n => n.id);
        popupIds = popupIds.filter(id => ids.indexOf(id) !== -1);
        pausedPopupIds = pausedPopupIds.filter(id => ids.indexOf(id) !== -1);
        var times = {}, deadlines = {};
        ids.forEach(id => {
            if (timestamps[id] !== undefined) times[id] = timestamps[id];
            if (popupDeadlines[id] !== undefined) deadlines[id] = popupDeadlines[id];
        });
        timestamps = times;
        popupDeadlines = deadlines;
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { service.toggleRequested(); }
        function clear(): void { service.clear(); }
        function clearApp(appName: string): void { service.clearApp(appName); }
        function dnd(): bool { return service.toggleDnd(); }
        function status(): string { return JSON.stringify({count: service.count, doNotDisturb: service.doNotDisturb, popups: service.popups.length}); }
    }

    FileView {
        id: settings
        path: Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/notification-settings.json"
        atomicWrites: true
        printErrors: false
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) settings.setText('{"doNotDisturb":false}\n');
            else console.warn("Could not read notification settings:", error);
        }
        onLoaded: {
            try { service.doNotDisturb = JSON.parse(text()).doNotDisturb === true; }
            catch (error) { console.warn("Invalid notification settings:", error); }
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        inlineReplySupported: true
        onNotification: function(notification) {
            if (Logic.ignored(notification.appName)) return;
            notification.tracked = true;
            var times = Object.assign({}, service.timestamps);
            times[notification.id] = Date.now();
            service.timestamps = times;
            if (!notification.lastGeneration && !service.doNotDisturb && !service.centerOpen) {
                var duration = Logic.popupDuration(notification);
                var deadlines = Object.assign({}, service.popupDeadlines);
                deadlines[notification.id] = duration ? Date.now() + duration : 0;
                service.popupDeadlines = deadlines;
                service.popupIds = service.popupIds.filter(id => id !== notification.id).concat([notification.id]);
            } else if (notification.transient) {
                notification.expire();
            }
        }
    }

    Timer {
        interval: 250
        running: service.popupIds.length > 0
        repeat: true
        onTriggered: {
            var now = Date.now();
            service.all.slice().forEach(n => {
                var deadline = service.popupDeadlines[n.id];
                if (deadline && deadline <= now && service.popupIds.indexOf(n.id) !== -1 && service.pausedPopupIds.indexOf(n.id) === -1) {
                    service.hidePopup(n.id);
                    if (n.transient) n.expire();
                }
            });
        }
    }
    Timer {
        interval: 60000
        running: service.all.length > 100
        repeat: true
        onTriggered: service.all.slice(0, service.all.length - 100).forEach(n => n.dismiss())
    }
}
