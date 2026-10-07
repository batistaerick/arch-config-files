import QtQuick
import "PanelStyle.js" as PanelStyle

Rectangle {
    id: button
    required property color foreground
    required property string text
    property bool available: true
    property bool loading: false
    property bool icon: false
    property real iconOffsetX: 0
    property bool outlined: false
    property bool selected: false
    property string leadingIcon: ""
    property int textAlignment: Text.AlignHCenter
    signal clicked()
    activeFocusOnTab: true
    enabled: available && !loading
    Keys.onReturnPressed: if (enabled) clicked()
    Keys.onEnterPressed: if (enabled) clicked()
    Keys.onSpacePressed: if (enabled) clicked()
    width: icon ? 34 : 68
    height: 40
    radius: PanelStyle.controlRadius
    color: Qt.rgba(foreground.r, foreground.g, foreground.b, selected ? 0.18 : mouse.containsMouse ? 0.16 : outlined ? 0 : 0.08)
    border.width: outlined ? 1 : 0
    border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.3)
    opacity: available && !loading ? 1 : 0.45
    Text {
        visible: !button.loading
        x: button.icon ? button.iconOffsetX : button.leadingIcon !== "" ? 34 : 8
        width: button.icon ? parent.width : parent.width - x - 8
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: button.textAlignment
        elide: Text.ElideRight
        text: button.text
        color: button.foreground
        font.family: PanelStyle.fontFamily
        font.pixelSize: button.icon ? 18 : PanelStyle.controlSize
    }
    Text {
        visible: button.leadingIcon !== "" && !button.loading
        x: 8
        width: 18
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: button.leadingIcon
        color: button.foreground
        font.family: PanelStyle.fontFamily
        font.pixelSize: 16
    }
    Text {
        anchors.centerIn: parent
        visible: button.loading
        text: "󰑐"
        color: button.foreground
        font.family: PanelStyle.fontFamily
        font.pixelSize: 18
        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: button.visible && button.loading
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: button.available && !button.loading
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            button.forceActiveFocus();
            button.clicked();
        }
    }
}
