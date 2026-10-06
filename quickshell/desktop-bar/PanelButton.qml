import QtQuick

Rectangle {
    id: button
    required property color foreground
    required property string text
    property bool available: true
    property bool icon: false
    signal clicked()
    activeFocusOnTab: available
    Keys.onReturnPressed: if (available) clicked()
    Keys.onEnterPressed: if (available) clicked()
    Keys.onSpacePressed: if (available) clicked()
    width: icon ? 34 : 68
    height: 40
    radius: 7
    color: Qt.rgba(foreground.r, foreground.g, foreground.b, mouse.containsMouse ? 0.16 : 0.08)
    opacity: available ? 1 : 0.45
    Text {
        anchors.centerIn: parent
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: button.text
        color: button.foreground
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: button.icon ? 18 : 13
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
