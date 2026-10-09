import QtQuick

Rectangle {
    required property string edge
    required property color background
    property bool glass: false
    property bool glassRim: true
    property real screenY: 0
    property real screenHeight: 1
    radius: 6
    topLeftRadius: edge === "top" || edge === "left" ? 0 : 6
    topRightRadius: edge === "top" || edge === "right" ? 0 : 6
    bottomLeftRadius: edge === "bottom" || edge === "left" ? 0 : 6
    bottomRightRadius: edge === "bottom" || edge === "right" ? 0 : 6
    color: background
    GlassSheen {
        anchors.fill: parent
        visible: parent.glass
        rim: parent.glassRim
        screenY: parent.screenY
        screenHeight: parent.screenHeight
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: parent.bottomLeftRadius
        bottomRightRadius: parent.bottomRightRadius
    }
}
