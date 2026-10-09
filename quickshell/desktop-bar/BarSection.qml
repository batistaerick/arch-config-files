import QtQuick

Rectangle {
    required property string edge
    required property color background
    radius: 6
    topLeftRadius: edge === "top" || edge === "left" ? 0 : 6
    topRightRadius: edge === "top" || edge === "right" ? 0 : 6
    bottomLeftRadius: edge === "bottom" || edge === "left" ? 0 : 6
    bottomRightRadius: edge === "bottom" || edge === "right" ? 0 : 6
    color: background
}
