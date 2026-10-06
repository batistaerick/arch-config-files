import QtQuick

Item {
    id: marker
    required property string style
    required property string label
    required property bool active
    required property color accent
    required property color foreground
    required property color selectedForeground
    property int fontSize: 14
    property int textOffsetY: -1

    implicitWidth: 23
    implicitHeight: 20

    Rectangle {
        anchors.fill: parent
        visible: marker.style === "Numbers" && marker.active
        radius: 6
        color: marker.accent
    }

    Text {
        visible: marker.style !== "Dots"
        anchors.fill: parent
        y: marker.textOffsetY
        text: marker.style === "Glyph" ? (marker.active ? "✦" : "✧") : marker.label
        color: marker.active ? (marker.style === "Glyph" ? marker.accent : marker.selectedForeground) : marker.foreground
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: marker.style === "Glyph" ? 19 : marker.fontSize
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        visible: marker.style === "Dots"
        anchors.centerIn: parent
        width: marker.active ? 22 : 12
        height: 12
        radius: 6
        color: marker.active ? Qt.rgba(marker.accent.r, marker.accent.g, marker.accent.b, 0.16) : Qt.rgba(marker.foreground.r, marker.foreground.g, marker.foreground.b, 0.08)
        Rectangle {
            anchors.centerIn: parent
            width: marker.active ? 17 : 6
            height: 6
            radius: 3
            color: marker.active ? marker.accent : marker.foreground
            Behavior on width { NumberAnimation { duration: 140 } }
        }
        Behavior on width { NumberAnimation { duration: 140 } }
    }
}
