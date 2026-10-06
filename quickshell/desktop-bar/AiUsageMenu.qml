import QtQuick
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 560
    implicitHeight: 680
    property var usage: ({providers: []})
    property bool freshReceived: false
    property string status: "Checking usage..."
    function refresh() {
        if (!query.running) {
            status = "Updating...";
            query.running = true;
        }
    }
    function resetLabel(timestamp) {
        var seconds = Math.max(0, Math.floor(timestamp - Date.now() / 1000));
        return "Resets " + Qt.formatDateTime(new Date(timestamp * 1000), "ddd MMM dd, HH:mm") + " · " + Math.floor(seconds / 3600) + "h " + Math.floor(seconds % 3600 / 60) + "m";
    }
    onVisibleChanged: if (visible) {
        freshReceived = false;
        if (!cached.running) cached.running = true;
        refresh();
    }
    Timer { interval: 300000; repeat: true; running: menu.visible; onTriggered: menu.refresh() }
    Process {
        id: cached
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/ai-popup.py", "cached"]
        stdout: StdioCollector { id: cachedOutput }
        onExited: {
            try {
                var data = JSON.parse(cachedOutput.text);
                if (data.providers && !menu.freshReceived) menu.usage = data;
            } catch (e) {}
        }
    }
    Process {
        id: query
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/ai-popup.py"]
        stdout: StdioCollector { id: output }
        onExited: function(code) {
            try {
                if (code !== 0) throw new Error("query failed");
                menu.usage = JSON.parse(output.text);
                menu.freshReceived = true;
                menu.status = "Last checked " + Qt.formatDateTime(new Date(menu.usage.updated * 1000), "HH:mm");
            } catch (e) { menu.status = "Could not update usage. Try refreshing."; }
        }
    }
    Item {
        anchors.fill: parent
        anchors.margins: 24
        Text {
            text: "AI usage"
            color: menu.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            font.bold: true
        }
        PanelButton {
            id: refreshButton
            anchors.right: parent.right
            text: "󰑓"
            icon: true
            height: 34
            available: !query.running
            foreground: menu.foreground
            onClicked: menu.refresh()
            BarTooltip { target: refreshButton; hovered: refreshHover.hovered; text: "Refresh"; foreground: menu.foreground; background: menu.background }
            HoverHandler { id: refreshHover }
        }
        Flickable {
            y: 54
            width: parent.width
            height: parent.height - 84
            contentHeight: providers.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: providers
                width: parent.width
                spacing: 0
                Repeater {
                    model: menu.usage.providers || []
                    Column {
                        id: provider
                        required property var modelData
                        required property int index
                        width: providers.width
                        spacing: 10
                        Item {
                            visible: provider.index > 0
                            width: parent.width
                            height: 49
                            Rectangle { y: 24; width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08) }
                        }
                        Row {
                            spacing: 10
                            height: 24
                            Text { height: 24; verticalAlignment: Text.AlignVCenter; text: provider.modelData.name === "Codex" ? "" : "󰚩"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 19 }
                            Text { height: 24; verticalAlignment: Text.AlignVCenter; text: provider.modelData.name; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17; font.bold: true }
                        }
                        Text {
                            visible: !!provider.modelData.error
                            width: parent.width
                            text: provider.modelData.error || ""
                            wrapMode: Text.Wrap
                            color: menu.foreground
                            opacity: 0.72
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                        Repeater {
                            model: provider.modelData.windows
                            Column {
                                id: limit
                                required property var modelData
                                readonly property real used: Math.max(0, Math.min(100, Number(modelData.used)))
                                width: provider.width
                                spacing: 10
                                Item {
                                    width: parent.width
                                    height: 20
                                    Text { text: limit.modelData.label; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                                    Text { anchors.right: parent.right; text: Math.round(100 - limit.used) + "% left"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                                }
                                Rectangle {
                                    id: usageTrack
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12)
                                    Rectangle { width: parent.width * limit.used / 100; height: 6; radius: 3; color: menu.foreground }
                                    HoverHandler { id: meterHover }
                                    BarTooltip { target: usageTrack; hovered: meterHover.hovered; text: limit.used + "% used"; foreground: menu.foreground; background: menu.background }
                                }
                                Text {
                                    visible: !!limit.modelData.reset
                                    text: limit.modelData.reset ? menu.resetLabel(limit.modelData.reset) : ""
                                    color: menu.foreground
                                    opacity: 0.72
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }
        }
        Text {
            anchors.bottom: parent.bottom
            text: menu.status
            color: menu.foreground
            opacity: 0.72
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
    }
}
