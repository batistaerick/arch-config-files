import QtQuick
import "PanelStyle.js" as PanelStyle

Column {
    id: group
    required property var notifications
    required property color foreground
    required property color accent
    property bool expanded: false
    readonly property bool multiple: notifications.length > 1
    readonly property var displayedNotifications: expanded ? notifications : notifications.slice(0, 1)
    signal toggleRequested()
    signal clearRequested()
    spacing: 8
    Row {
        width: parent.width; spacing: 8
        Text {
            width: parent.width - 34 - (group.multiple ? 36 : 0)
            height: 28
            text: group.notifications.length + (group.multiple ? " notifications" : " notification")
            color: group.foreground; opacity: 0.65
            font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        PanelButton {
            objectName: "toggleNotificationGroup"
            visible: group.multiple
            width: 28; height: 28; icon: true
            text: group.expanded ? "󰅃" : "󰅀"
            foreground: group.foreground
            onClicked: group.toggleRequested()
        }
        PanelButton {
            objectName: "clearNotificationGroup"
            width: 26; height: 28; icon: true
            text: "󰅖"; compactIconBackground: true
            foreground: group.foreground
            onClicked: group.clearRequested()
        }
    }
    Repeater {
        model: group.displayedNotifications
        NotificationCard {
            required property var modelData
            width: group.width
            notification: modelData
            compact: group.multiple && !group.expanded
            foreground: group.foreground
            accent: group.accent
        }
    }
}
