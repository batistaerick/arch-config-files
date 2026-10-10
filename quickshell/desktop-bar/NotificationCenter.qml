import QtQuick
import "PanelStyle.js" as PanelStyle

ThemedPopup {
    id: center
    required property var service
    property var expandedApps: ({})
    function toggleGroup(name) {
        var updated = Object.assign({}, expandedApps);
        updated[name] = !updated[name];
        expandedApps = updated;
    }
    property int maximumHeight: 900
    implicitWidth: 468
    implicitHeight: Math.min(maximumHeight, 740)
    onOpenedChanged: service.centerOpen = opened
    Item {
        anchors.fill: parent
        anchors.margins: PanelStyle.padding
        Row {
            id: header
            width: parent.width; spacing: 8
            Text {
                width: parent.width - 84; height: 34
                text: "Notifications"
                color: center.foreground
                font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            PanelButton {
                id: dndButton
                width: 34; height: 34; icon: true
                text: center.service.doNotDisturb ? "󰂛" : "󰂚"
                selected: center.service.doNotDisturb
                foreground: center.foreground
                onClicked: center.service.toggleDnd()
                HoverHandler { id: dndHover }
                BarTooltip { target: dndButton; hovered: dndHover.hovered; text: "Do Not Disturb"; foreground: center.foreground; background: center.background }
            }
            PanelButton {
                id: clearButton
                width: 34; height: 34; icon: true; text: "󰃢"
                available: center.service.count > 0
                foreground: center.foreground
                onClicked: center.service.clear()
                HoverHandler { id: clearHover }
                BarTooltip { target: clearButton; hovered: clearHover.hovered; text: "Clear all"; foreground: center.foreground; background: center.background }
            }
        }
        Rectangle { y: header.height + 12; width: parent.width; height: 1; color: Qt.alpha(center.foreground, PanelStyle.dividerAlpha) }
        Text {
            anchors.centerIn: parent
            visible: center.service.count === 0
            text: center.service.doNotDisturb ? "󰂛  Do Not Disturb\n\nNo notifications" : "󰂚  No notifications"
            horizontalAlignment: Text.AlignHCenter
            color: center.foreground; opacity: 0.65
            font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.bodySize
        }
        Flickable {
            anchors { top: header.bottom; topMargin: 26; left: parent.left; right: parent.right; bottom: parent.bottom }
            contentHeight: groups.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: groups
                width: parent.width; spacing: 18
                Repeater {
                    model: center.service.groups
                    NotificationGroup {
                        required property var modelData
                        width: groups.width
                        notifications: modelData.notifications
                        background: center.background
                        expanded: !!center.expandedApps[modelData.name]
                        foreground: center.foreground
                        accent: center.accent
                        onToggleRequested: center.toggleGroup(modelData.name)
                        onClearRequested: center.service.clearApp(modelData.name)
                        onActivated: center.opened = false
                    }
                }
            }
        }
    }
}
