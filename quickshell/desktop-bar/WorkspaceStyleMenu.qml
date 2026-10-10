import QtQuick
import "PanelStyle.js" as PanelStyle

ThemedPopup {
    id: menu
    required property string currentStyle
    required property color selectedForeground
    signal selected(string style)

    implicitWidth: 296
    implicitHeight: 143
    leftAligned: true

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2
        Repeater {
            model: ["Numbers", "Glyph", "Dots"]
            Rectangle {
                id: choiceRow
                required property string modelData
                required property int index
                width: parent.width
                height: 33
                radius: PanelStyle.controlRadius
                color: mouse.containsMouse ? Qt.alpha(menu.accent, 0.18) : "transparent"
                Rectangle {
                    visible: choiceRow.index > 0
                    x: 8
                    y: -2
                    width: parent.width - 16
                    height: 1
                    color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha)
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    color: menu.foreground
                    font.family: PanelStyle.fontFamily
                    font.pixelSize: PanelStyle.controlSize
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: 5
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
                    font.family: PanelStyle.fontFamily
                    font.pixelSize: PanelStyle.controlSize
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        menu.selected(parent.modelData);
                        menu.opened = false;
                    }
                }
            }
        }
    }
}
