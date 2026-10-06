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
    required property color selectedForeground
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
                    id: choiceRow
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
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: 4
                            WorkspaceMarker {
                                required property int index
                                width: 23
                                height: 20
                                style: choiceRow.modelData
                                label: String(index + 1)
                                active: index === 1
                                accent: menu.accent
                                foreground: menu.foreground
                                selectedForeground: menu.selectedForeground
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
