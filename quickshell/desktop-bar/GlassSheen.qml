import QtQuick
import "GlassStyle.js" as GlassStyle

Rectangle {
    id: sheen
    required property real screenY
    required property real screenHeight
    property bool rim: true
    border.width: rim ? 1 : 0
    border.color: Qt.rgba(1, 1, 1, 0.32)
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, GlassStyle.highlightAlpha(screenY, screenHeight)) }
        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, GlassStyle.highlightAlpha(screenY + height, screenHeight)) }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        visible: sheen.rim
        radius: Math.max(0, sheen.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.09)
    }
}
