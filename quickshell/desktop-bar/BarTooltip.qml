import QtQuick
import Quickshell

PopupWindow {
    id: tip
    required property Item target
    required property bool hovered
    required property string text
    property bool ready: false

    visible: hovered && ready && text !== ""
    color: "transparent"
    implicitWidth: label.implicitWidth + 18
    implicitHeight: 28
    anchor.item: target
    anchor.rect.x: (target.width - implicitWidth) / 2
    anchor.rect.y: target.height + 6
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide

    onHoveredChanged: {
        ready = false;
        if (hovered) delay.restart();
        else delay.stop();
    }

    Timer {
        id: delay
        interval: 400
        onTriggered: tip.ready = true
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: "#181824"
        border.color: "#515162"
        Text {
            id: label
            anchors.centerIn: parent
            text: tip.text
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
    }
}
