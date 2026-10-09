import QtQuick
import "PanelStyle.js" as PanelStyle

Column {
    id: controls
    required property bool idleEnabled
    required property bool busy
    required property color foreground
    required property color accent
    signal toggleRequested()
    signal lockRequested()
    spacing: 14
    Text {
        text: "Idle Lock"
        color: controls.foreground
        font.family: PanelStyle.fontFamily
        font.pixelSize: PanelStyle.headingSize
        font.bold: true
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
    Text {
        width: parent.width
        text: controls.idleEnabled ? "Locks automatically when you are away." : "Automatic idle lock is disabled. You can still lock manually."
        wrapMode: Text.Wrap
        color: controls.foreground
        opacity: 0.65
        font.family: PanelStyle.fontFamily
        font.pixelSize: PanelStyle.secondarySize
    }
    PanelButton {
        objectName: "lockNowButton"
        width: parent.width
        text: "Lock now"
        leadingIcon: "󰌾"
        foreground: controls.foreground
        available: !controls.busy
        onClicked: controls.lockRequested()
    }
}
