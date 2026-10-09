import QtQuick
import Quickshell
import Quickshell.Wayland
import "PanelStyle.js" as PanelStyle

PanelWindow {
    id: window
    required property var service
    required property color foreground
    required property color background
    required property color accent
    property string barEdge: "top"
    visible: service.popups.length > 0 && !service.centerOpen
    color: "transparent"
    implicitWidth: 428
    implicitHeight: cards.implicitHeight
    anchors { top: barEdge !== "bottom"; bottom: barEdge === "bottom"; right: barEdge !== "left"; left: barEdge === "left" }
    margins { top: barEdge === "top" ? 42 : 12; bottom: 42; left: barEdge === "left" ? 80 : 12; right: barEdge === "right" ? 80 : 12 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "desktop-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    Column {
        id: cards
        width: parent.width; spacing: 10
        Repeater {
            model: window.service.popups
            Rectangle {
                required property var modelData
                width: cards.width
                height: notificationCard.implicitHeight + 20
                radius: PanelStyle.cornerRadius
                color: window.background
                border.color: modelData && modelData.urgency === 2 ? window.accent : Qt.alpha(window.foreground, 0.18)
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                HoverHandler {
                    onHoveredChanged: if (parent.modelData) window.service.pausePopup(parent.modelData.id, hovered)
                }
                NotificationCard {
                    id: notificationCard
                    x: 10; y: 10; width: parent.width - 20
                    notification: parent.modelData
                    compact: true
                    filled: false
                    foreground: window.foreground
                    accent: window.accent
                    onActivated: function(notificationId) { window.service.hidePopup(notificationId); }
                }
            }
        }
    }
}
