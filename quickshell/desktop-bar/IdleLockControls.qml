import QtQuick
import "PanelStyle.js" as PanelStyle

Column {
    id: controls
    required property bool idleEnabled
    required property bool busy
    required property color foreground
    required property color accent
    readonly property alias lockTarget: lockButton
    readonly property bool lockHovered: lockHover.hovered
    signal toggleRequested()
    signal lockRequested()
    spacing: 14
    Item {
        width: parent.width
        height: 34
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Idle Lock"
            color: controls.foreground
            font.family: PanelStyle.fontFamily
            font.pixelSize: PanelStyle.headingSize
            font.bold: true
        }
        PanelButton {
            id: lockButton
            objectName: "lockNowButton"
            anchors.right: parent.right
            width: 34; height: 34
            text: "󰌾"; icon: true
            foreground: controls.foreground
            available: !controls.busy
            onClicked: controls.lockRequested()
            HoverHandler { id: lockHover }
        }
    }
    Row {
        width: parent.width
        Text {
            width: parent.width - idleSwitch.width
            height: idleSwitch.height
            verticalAlignment: Text.AlignVCenter
            text: "Automatic idle lock"
            color: controls.foreground
            font.family: PanelStyle.fontFamily
            font.pixelSize: PanelStyle.bodySize
        }
        PanelSwitch {
            id: idleSwitch
            objectName: "idleLockSwitch"
            checked: controls.idleEnabled
            enabled: !controls.busy
            foreground: controls.foreground
            accent: controls.accent
            onToggled: controls.toggleRequested()
        }
    }
}
