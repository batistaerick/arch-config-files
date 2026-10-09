import QtQuick
import Quickshell

Item {
    id: panel
    property Item attachmentTarget
    property string attachmentEdge: "top"
    property string alignment: "right"
    property bool opened: false
    readonly property int transitionDuration: 320
    property real revealProgress: opened ? 1 : 0
    visible: opened || revealProgress > 0
    Behavior on revealProgress {
        NumberAnimation {
            duration: panel.transitionDuration
            easing.type: panel.opened ? Easing.OutCubic : Easing.InCubic
        }
    }
    readonly property var hostWindow: attachmentTarget ? attachmentTarget.QsWindow.window : null
    readonly property Item strip: hostWindow ? hostWindow.stripItem : null
    property point targetPoint: Qt.point(0, 0)
    function updateTargetPoint() {
        if (attachmentTarget && parent) targetPoint = attachmentTarget.mapToItem(parent, 0, 0);
    }
    Timer {
        interval: 16
        running: panel.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: panel.updateTargetPoint()
    }
    parent: hostWindow ? hostWindow.contentItem : null
    z: 100
    width: implicitWidth
    height: implicitHeight
    PanelSizeBehavior on width { ownerPanel: panel }
    PanelSizeBehavior on height { ownerPanel: panel }
    x: {
        if (!strip || !parent || !attachmentTarget) return 0;
        if (attachmentEdge === "left") return strip.x + strip.width;
        if (attachmentEdge === "right") return strip.x - width;
        var desired = alignment === "left" ? 0 : alignment === "right" ? parent.width - width : (parent.width - width) / 2;
        return Math.max(0, Math.min(parent.width - width, desired));
    }
    y: {
        if (!strip || !parent || !attachmentTarget) return 0;
        if (attachmentEdge === "top") return strip.y + strip.height;
        if (attachmentEdge === "bottom") return strip.y - height;
        var desired = alignment === "left" ? 0 : alignment === "right" ? parent.height - height : (parent.height - height) / 2;
        return Math.max(0, Math.min(parent.height - height, desired));
    }
}
