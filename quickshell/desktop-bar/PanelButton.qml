import QtQuick
import "PanelStyle.js" as PanelStyle

Rectangle {
    id: button
    required property color foreground
    required property string text
    property bool available: true
    property bool icon: false
    property bool outlined: false
    property bool selected: false
    signal clicked()
    activeFocusOnTab: true
    enabled: available
    Keys.onReturnPressed: if (available) clicked()
    Keys.onEnterPressed: if (available) clicked()
    Keys.onSpacePressed: if (available) clicked()
    width: icon ? 34 : 68
    height: 40
    radius: PanelStyle.controlRadius
    color: Qt.rgba(foreground.r, foreground.g, foreground.b, selected ? 0.18 : mouse.containsMouse ? 0.16 : outlined ? 0 : 0.08)
    border.width: outlined ? 1 : 0
    border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.3)
    opacity: available ? 1 : 0.45
    Text {
        anchors.centerIn: parent
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: button.text
        color: button.foreground
        font.family: PanelStyle.fontFamily
        font.pixelSize: button.icon ? 18 : PanelStyle.controlSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: button.available
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            button.forceActiveFocus();
            button.clicked();
        }
    }
}
