import QtQuick
import "PanelStyle.js" as PanelStyle
import "BarGeometry.js" as Geometry
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: popup
    required property Item target
    required property color foreground
    required property color background
    required property color accent
    property bool centered: false
    property bool leftAligned: false
    property string barEdge: "top"
    property Item keyTarget: body
    default property alias panelContent: body.data
    visible: false
    color: "transparent"
    Behavior on implicitHeight {
        enabled: popup.visible
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    anchor.item: target
    anchor.rect.x: Geometry.popupX(barEdge, target.width, implicitWidth, centered ? "center" : leftAligned ? "left" : "right")
    anchor.rect.y: Geometry.popupY(barEdge, target.height, implicitHeight)
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
                clip: true
                focus: true
                Keys.onEscapePressed: popup.visible = false
            }
        }
    ]
}
