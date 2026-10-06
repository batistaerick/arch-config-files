import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: menu
    required property Item target
    required property color accent
    required property color foreground
    required property color background
    property var layouts: []
    property int activeLayout: -1
    property string error: ""

    function refresh() {
        if (!query.running && !select.running) query.running = true;
    }

    visible: false
    color: "transparent"
    implicitWidth: 300
    implicitHeight: Math.max(1, layouts.length) * 35 + 12
    anchor.item: target
    anchor.rect.x: target.width - implicitWidth
    anchor.rect.y: target.height + 8
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    onVisibleChanged: {
        if (visible) {
            error = "";
            refresh();
            grabDelay.restart();
        } else {
            grabDelay.stop();
            grab.active = false;
        }
    }

    Timer { id: grabDelay; interval: 100; onTriggered: if (menu.visible) grab.active = true }
    Timer { interval: 1000; running: menu.visible; repeat: true; onTriggered: menu.refresh() }
    HyprlandFocusGrab { id: grab; windows: [menu]; onCleared: menu.visible = false }

    Process {
        id: query
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/keyboard-layout.py"]
        stdout: StdioCollector { id: output }
        onExited: function(code) {
            try {
                if (code !== 0) throw new Error("query failed");
                var data = JSON.parse(output.text);
                menu.layouts = data.layouts;
                menu.activeLayout = data.active;
                menu.error = "";
            } catch (e) { menu.error = "Layouts unavailable"; }
        }
    }
    Process {
        id: select
        onExited: function(code) {
            if (code === 0) menu.visible = false;
            else menu.error = "Could not switch layout";
        }
    }

    Rectangle {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: menu.visible = false
        radius: 6
        color: menu.background
        border.color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.18)
        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            Repeater {
                model: menu.layouts
                Rectangle {
                    required property var modelData
                    width: 288
                    height: 33
                    radius: 4
                    color: mouse.containsMouse ? Qt.rgba(menu.accent.r, menu.accent.g, menu.accent.b, 0.18) : "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.index === menu.activeLayout ? "" : ""
                        color: menu.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        elide: Text.ElideRight
                        color: menu.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !select.running
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            select.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/keyboard-layout.py", "select", String(parent.modelData.index)];
                            select.running = true;
                        }
                    }
                }
            }
        }
        Text {
            visible: menu.error !== "" || menu.layouts.length === 0
            anchors.centerIn: parent
            text: menu.error || "Loading..."
            color: menu.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
    }
}
