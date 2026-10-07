import QtQuick
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: popup
    required property Item target
    required property color foreground
    required property color background
    required property color accent
    property bool centered: false
    property Item keyTarget: body
    default property alias panelContent: body.data
    visible: false
    color: "transparent"
    anchor.item: target
    anchor.rect.x: centered ? (target.width - implicitWidth) / 2 : target.width - implicitWidth
    anchor.rect.y: target.height + 8
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    onVisibleChanged: {
        if (visible) grabDelay.restart();
        else {
            grabDelay.stop();
            grab.active = false;
        }
    }
    data: [
        Timer {
            id: grabDelay
            interval: 100
            onTriggered: if (popup.visible) {
                popup.keyTarget.forceActiveFocus();
                grab.active = true;
            }
        },
        HyprlandFocusGrab { id: grab; windows: [popup]; onCleared: popup.visible = false },
        Rectangle {
            anchors.fill: parent
            color: popup.background
            radius: PanelStyle.cornerRadius
            border.color: Qt.rgba(popup.foreground.r, popup.foreground.g, popup.foreground.b, 0.18)
            Item {
                id: body
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: popup.visible = false
            }
        }
    ]
}
