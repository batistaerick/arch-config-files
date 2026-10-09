import QtQuick
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 468
    property int maximumHeight: 1000
    implicitHeight: Math.min(maximumHeight, Math.max(300,
        content.implicitHeight + 64 + hero.height + 10 + tabs.height + 16 + footer.implicitHeight + 16 + 2))
    property var usage: ({providers: []})
    property var statistics: ({})
    property string selectedProvider: "Claude"
    property bool detailsExpanded: false
    readonly property var provider: (usage.providers || []).find(p => p.name === selectedProvider) || {name: selectedProvider, windows: []}
    readonly property var stats: statistics[selectedProvider] || {days: [], models: []}
    property bool freshReceived: false
    readonly property bool loading: query.running || statsQuery.running
    property string status: "Checking usage..."
    onSelectedProviderChanged: {
        detailsExpanded = false;
        contentViewport.contentY = 0;
    }
    function tokens(value) {
        if (value >= 1000000000) return (value / 1000000000).toFixed(1) + "B";
        if (value >= 1000000) return (value / 1000000).toFixed(1) + "M";
        if (value >= 1000) return (value / 1000).toFixed(1) + "K";
        return String(value || 0);
    }
    function peak(rows) { return Math.max(1, ...rows.map(r => Number(r.tokens))); }
    function refresh() {
        if (!loading) {
            status = "Updating...";
            query.running = true;
            if (!statsQuery.running) statsQuery.running = true;
        }
    }
    function resetLabel(timestamp) {
        var seconds = Math.max(0, Math.floor(timestamp - Date.now() / 1000));
        return "Resets " + Qt.formatDateTime(new Date(timestamp * 1000), "ddd MMM dd, HH:mm") + " · " + Math.floor(seconds / 3600) + "h " + Math.floor(seconds % 3600 / 60) + "m";
    }
    onOpenedChanged: if (opened) {
        detailsExpanded = false;
        contentViewport.contentY = 0;
        freshReceived = false;
        if (!cached.running) cached.running = true;
        refresh();
    }
    Timer { interval: 300000; repeat: true; running: menu.opened; onTriggered: menu.refresh() }
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
    Process {
        id: statsQuery
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/ai-local-stats.py"]
        stdout: StdioCollector { id: statsOutput }
        onExited: { try { menu.statistics = JSON.parse(statsOutput.text); } catch (e) {} }
    }
    Item {
        anchors.fill: parent
        anchors.margins: PanelStyle.padding
        Item {
            id: hero
            width: parent.width
            height: 40
            Item {
                width: 30
                height: 30
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    anchors.centerIn: parent
                    width: menu.selectedProvider === "Claude" ? 28 : 40
                    height: width
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    source: menu.selectedProvider === "Claude" ? "assets/ai/claude.svg"
                        : menu.foreground.r + menu.foreground.g + menu.foreground.b > 1.5
                            ? "assets/ai/OpenAI-white-monoblossom.svg"
                            : "assets/ai/OpenAI-black-monoblossom.svg"
                }
            }
            Column {
                x: 38
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text { text: menu.selectedProvider === "Claude" ? "Claude Code" : "Codex"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize; font.bold: true }
                Text { text: (menu.provider.plan || "Plan unavailable").toUpperCase(); color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
            }
            PanelButton {
                id: refreshButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "󰑓"; icon: true; height: 32
                loading: menu.loading
                foreground: menu.foreground
                onClicked: menu.refresh()
                HoverHandler { id: refreshHover }
                BarTooltip { target: refreshButton; hovered: refreshHover.hovered; text: menu.loading ? "Updating" : "Refresh"; foreground: menu.foreground; background: menu.background }
            }
        }
        Row {
            id: tabs
            anchors.top: hero.bottom
            anchors.topMargin: 10
            width: parent.width
            spacing: 6
            Repeater {
                model: ["Claude", "Codex"]
                PanelButton {
                    required property string modelData
                    width: (tabs.width - tabs.spacing) / 2
                    height: 32
                    radius: 4
                    text: modelData === "Claude" ? "Claude Code" : modelData
                    outlined: true
                    selected: menu.selectedProvider === modelData
                    foreground: menu.foreground
                    onClicked: menu.selectedProvider = modelData
                }
            }
        }
        Flickable {
            id: contentViewport
            anchors.top: tabs.bottom
            anchors.topMargin: 16
            anchors.bottom: footer.top
            anchors.bottomMargin: 16
            width: parent.width
            contentHeight: content.height
            interactive: contentHeight > height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: content
                width: parent.width
                spacing: 14
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12) }
                Text { text: "LIMITS"; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                Text { visible: !!menu.provider.error; width: parent.width; text: menu.provider.error || ""; wrapMode: Text.Wrap; color: menu.foreground; opacity: 0.7; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                Repeater {
                    model: menu.provider.windows || []
                    Column {
                        id: limit
                        required property var modelData
                        readonly property real used: Math.max(0, Math.min(100, Number(modelData.used)))
                        width: content.width
                        spacing: 7
                        Item {
                            width: parent.width; height: 17
                            Text { text: limit.modelData.label === "5h window" ? "Session" : limit.modelData.label; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize }
                            Text { anchors.right: parent.right; text: Math.round(limit.used) + "% used"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                        }
                        Rectangle {
                            width: parent.width; height: 6; radius: 3
                            color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12)
                            Rectangle { width: parent.width * limit.used / 100; height: 6; radius: 3; color: menu.foreground }
                        }
                        Text { visible: !!limit.modelData.reset; width: parent.width; elide: Text.ElideRight; text: limit.modelData.reset ? menu.resetLabel(limit.modelData.reset) : ""; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12) }
                Item {
                    width: parent.width; height: 28
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "TOKEN DETAILS"; color: menu.foreground; opacity: 0.6
                        font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize
                    }
                    PanelButton {
                        id: detailsButton
                        objectName: "toggleAiTokenDetails"
                        anchors.right: parent.right
                        width: 28; height: 28; icon: true
                        text: menu.detailsExpanded ? "󰅃" : "󰅀"
                        foreground: menu.foreground
                        onClicked: menu.detailsExpanded = !menu.detailsExpanded
                        HoverHandler { id: detailsHover }
                        BarTooltip { target: detailsButton; hovered: detailsHover.hovered; text: menu.detailsExpanded ? "Collapse token details" : "Expand token details"; foreground: menu.foreground; background: menu.background }
                    }
                }
                Column {
                    visible: menu.detailsExpanded
                    width: parent.width
                    spacing: 14
                Text { text: "TOKENS BY DAY"; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                Text { visible: statsQuery.running && menu.stats.days.length === 0; text: "Reading local sessions..."; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                Column {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: menu.stats.days
                        Item {
                            required property var modelData
                            width: content.width
                            height: 16
                            Text { width: 48; text: parent.modelData.date === Qt.formatDate(new Date(), "yyyy-MM-dd") ? "Today" : Qt.formatDate(new Date(parent.modelData.date + "T12:00:00"), "ddd"); color: menu.foreground; opacity: 0.7; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                            Rectangle {
                                x: 54; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 124; height: 4; radius: 2
                                color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12)
                                Rectangle { width: parent.width * parent.parent.modelData.tokens / menu.peak(menu.stats.days); height: 4; radius: 2; color: menu.foreground; opacity: 0.7 }
                            }
                            Text { anchors.right: parent.right; text: menu.tokens(parent.modelData.tokens); color: menu.foreground; opacity: 0.7; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                        }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12) }
                Text { text: "TOKENS BY MODEL"; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
                Text { visible: !statsQuery.running && menu.stats.models.length === 0; text: "No local token history"; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                Column {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: menu.stats.models
                        Rectangle {
                            required property var modelData
                            width: content.width
                            height: 28
                            radius: 4
                            clip: true
                            color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.04)
                            Rectangle { width: parent.width * parent.modelData.tokens / menu.peak(menu.stats.models); height: parent.height; radius: 4; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.14) }
                            Text { x: 8; width: parent.width - 88; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.name; elide: Text.ElideRight; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                            Text { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: menu.tokens(parent.modelData.tokens); color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
                        }
                    }
                }
                }
            }
        }
        Text { id: footer; anchors.bottom: parent.bottom; width: parent.width; elide: Text.ElideRight; text: menu.status; color: menu.foreground; opacity: 0.6; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
    }
}
