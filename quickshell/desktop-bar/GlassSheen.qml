import QtQuick
import "GlassStyle.js" as GlassStyle

Rectangle {
    required property real screenY
    required property real screenHeight
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, GlassStyle.highlightAlpha(screenY, screenHeight)) }
        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, GlassStyle.highlightAlpha(screenY + height, screenHeight)) }
    }
}
