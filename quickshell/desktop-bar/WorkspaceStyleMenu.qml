import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: menu
    required property Item target
    required property string currentStyle
    required property color accent
    required property color foreground
    required property color background
    signal selected(string style)

    visible: false
    color: "transparent"
    implicitWidth: 240
    implicitHeight: 115
    anchor.item: target
    anchor.rect.y: target.height + 8
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    onVisibleChanged: {
        if (visible) grabDelay.restart();
        else {
            grabDelay.stop();
            grab.active = false;
        }
    }
    Timer {
        id: grabDelay
        interval: 100
        onTriggered: if (menu.visible) grab.active = true
    }

    HyprlandFocusGrab {
        id: grab
        windows: [menu]
        onCleared: menu.visible = false
    }

    Rectangle {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: menu.visible = false
        radius: 6
        color: menu.background
        border.color: Qt.alpha(menu.foreground, 0.18)
        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            Repeater {
                model: ["Numbers", "Glyph", "Dots"]
                Rectangle {
                    required property string modelData
                    width: 228
                    height: 33
                    radius: 4
                    color: mouse.containsMouse ? Qt.alpha(menu.accent, 0.18) : "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: menu.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData !== "Dots"
                        text: {
                            if (modelData === "Numbers") return "1 2 3 4";
                            if (modelData === "Glyph") return "✦ ✧ · ·";
                            return "━ · · ·";
                        }
                        color: menu.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Row {
                        visible: parent.modelData === "Dots"
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                width: index === 3 ? 17 : 6
                                height: 6
                                radius: 3
                                color: menu.accent
                                opacity: index === 3 ? 1 : 0.65
                            }
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData === menu.currentStyle ? "" : ""
                        color: menu.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            menu.selected(parent.modelData);
                            menu.visible = false;
                        }
                    }
                }
            }
        }
    }
}
