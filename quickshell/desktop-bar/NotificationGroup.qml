import QtQuick
import "PanelStyle.js" as PanelStyle

Column {
    id: group
    required property var notifications
    required property color foreground
    required property color accent
    property color background: "transparent"
    function stackColor(tint) {
        return Qt.rgba(background.r * (1 - tint) + foreground.r * tint,
                       background.g * (1 - tint) + foreground.g * tint,
                       background.b * (1 - tint) + foreground.b * tint, 1);
    }
    property bool expanded: false
    readonly property bool multiple: notifications.length > 1
    readonly property int stackDepth: Math.min(3, notifications.length)
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
    Item {
        objectName: "collapsedNotificationStack"
        width: group.width
        visible: !group.expanded && group.notifications.length > 0
        implicitHeight: visible ? frontCard.implicitHeight + Math.max(0, group.stackDepth - 1) * 7 : 0
        height: implicitHeight
        Repeater {
            model: Math.max(0, group.stackDepth - 1)
            Rectangle {
                required property int index
                readonly property int depth: index + 1
                objectName: "notificationStackLayer" + depth
                x: depth * 8; y: depth * 7
                width: parent.width - depth * 16
                height: frontCard.implicitHeight
                z: 3 - depth
                radius: PanelStyle.cornerRadius
                color: group.stackColor(0.055 + depth * 0.025)
                border.width: 1
                border.color: Qt.alpha(group.foreground, 0.12)
            }
        }
        NotificationCard {
            id: frontCard
            z: 3
            width: parent.width
            notification: group.notifications.length ? group.notifications[0] : null
            compact: group.multiple
            color: group.multiple ? group.stackColor(0.055) : Qt.alpha(group.foreground, 0.055)
            foreground: group.foreground; accent: group.accent
        }
    }
    Column {
        width: group.width
        visible: group.expanded
        spacing: 8
        Repeater {
            model: group.expanded ? group.notifications : []
            NotificationCard {
                required property var modelData
                width: group.width
                notification: modelData
                foreground: group.foreground; accent: group.accent
            }
        }
    }
}
