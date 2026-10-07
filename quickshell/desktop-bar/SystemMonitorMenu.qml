import QtQuick
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: menu
    required property Item target
    required property color accent
    required property color foreground
    required property color background
    property var sections: []
    property string error: ""

    function refresh() {
        if (!query.running) query.running = true;
    }

    visible: false
    color: "transparent"
    implicitWidth: 440
    implicitHeight: content.implicitHeight + PanelStyle.padding * 2
    anchor.item: target
    anchor.rect.x: 0
    anchor.rect.y: target.height + 8
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    onVisibleChanged: {
        if (visible) {
            refresh();
            grabDelay.restart();
        } else {
            grabDelay.stop();
            grab.active = false;
        }
    }
    Timer { id: grabDelay; interval: 100; onTriggered: if (menu.visible) grab.active = true }
    Timer { interval: 2000; repeat: true; running: menu.visible; onTriggered: menu.refresh() }
    HyprlandFocusGrab { id: grab; windows: [menu]; onCleared: menu.visible = false }
    Process {
        id: query
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/system-details.py"]
        stdout: StdioCollector { id: output }
        onExited: function(code) {
            try {
                if (code !== 0) throw new Error("query failed");
                menu.sections = JSON.parse(output.text).sections;
                menu.error = "";
            } catch (e) { menu.error = "Hardware information unavailable"; }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: PanelStyle.cornerRadius
        color: menu.background
        border.color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.18)
        focus: true
        Keys.onEscapePressed: menu.visible = false
        Column {
            id: content
            x: PanelStyle.padding
            y: PanelStyle.padding
            width: parent.width - PanelStyle.padding * 2
            spacing: 14
            Text {
                visible: menu.sections.length === 0 || menu.error !== ""
                text: menu.error || "Loading..."
                color: menu.foreground
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.controlSize
            }
            Repeater {
                model: menu.sections
                Column {
                    id: section
                    required property var modelData
                    required property int index
                    width: content.width
                    spacing: 7
                    Rectangle {
                        visible: section.index > 0
                        width: parent.width
                        height: 1
                        color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12)
                    }
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - 70
                            text: section.modelData.title
                            color: menu.foreground
                            font.family: PanelStyle.fontFamily
                            font.pixelSize: PanelStyle.headingSize
                            font.bold: true
                        }
                        Text {
                            width: 70
                            horizontalAlignment: Text.AlignRight
                            text: section.modelData.usage === null ? "--" : section.modelData.usage + "%"
                            color: menu.foreground
                            font.family: PanelStyle.fontFamily
                            font.pixelSize: PanelStyle.controlSize
                        }
                    }
                    Text {
                        width: parent.width
                        text: section.modelData.name
                        elide: Text.ElideRight
                        color: menu.foreground
                        opacity: 0.72
                        font.family: PanelStyle.fontFamily
                        font.pixelSize: PanelStyle.bodySize
                    }
                    Rectangle {
                        width: parent.width
                        height: 5
                        radius: 3
                        color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12)
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(100, section.modelData.usage || 0)) / 100
                            height: parent.height
                            radius: 3
                            color: menu.foreground
                        }
                    }
                    Repeater {
                        model: section.modelData.rows
                        Row {
                            required property var modelData
                            width: section.width
                            Text {
                                width: parent.width * 0.5
                                text: parent.modelData[0]
                                color: menu.foreground
                                opacity: 0.65
                                font.family: PanelStyle.fontFamily
                                font.pixelSize: PanelStyle.secondarySize
                            }
                            Text {
                                width: parent.width * 0.5
                                horizontalAlignment: Text.AlignRight
                                text: parent.modelData[1]
                                elide: Text.ElideRight
                                color: menu.foreground
                                font.family: PanelStyle.fontFamily
                                font.pixelSize: PanelStyle.secondarySize
                            }
                        }
                    }
                }
            }
        }
    }
}
