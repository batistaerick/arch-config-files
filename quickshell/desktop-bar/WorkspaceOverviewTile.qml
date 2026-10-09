import QtQuick
import Quickshell
import Quickshell.Wayland
import "PanelStyle.js" as PanelStyle
import "WorkspaceModel.js" as WorkspaceModel

Rectangle {
    id: tile
    required property var workspace
    required property color foreground
    required property color background
    required property color accent
    required property bool capturing
    property bool selected: false
    signal chosen(int workspaceId)
    radius: PanelStyle.cornerRadius
    color: background
    border.width: selected || hover.hovered ? 2 : 1
    border.color: selected || hover.hovered ? accent : Qt.alpha(foreground, 0.2)
    HoverHandler { id: hover }
    Row {
        x: 14; y: 10; spacing: 10
        Text { text: "Workspace " + tile.workspace.id; color: tile.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize; font.bold: true }
        Text { anchors.verticalCenter: parent.verticalCenter; text: tile.workspace.windows.length + " windows"; color: tile.foreground; opacity: 0.65; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize }
    }
    Item {
        id: desktop
        x: 14; y: 40; width: parent.width - 28; height: parent.height - 54
        clip: true
        readonly property var geometry: WorkspaceModel.bounds(tile.workspace.windows)
        readonly property real fit: Math.min(width / geometry.width, height / geometry.height)
        Repeater {
            model: tile.workspace.windows
            Rectangle {
                id: thumbnail
                required property var modelData
                readonly property var info: modelData.lastIpcObject || {}
                readonly property var at: info.at || [0, 0]
                readonly property var dimensions: info.size || [800, 600]
                x: (desktop.width - desktop.geometry.width * desktop.fit) / 2 + (at[0] - desktop.geometry.x) * desktop.fit
                y: (desktop.height - desktop.geometry.height * desktop.fit) / 2 + (at[1] - desktop.geometry.y) * desktop.fit
                width: Math.max(1, dimensions[0] * desktop.fit)
                height: Math.max(1, dimensions[1] * desktop.fit)
                color: Qt.alpha(tile.foreground, 0.08)
                border.width: 1; border.color: Qt.alpha(tile.foreground, 0.18)
                clip: true
                ScreencopyView {
                    id: preview
                    anchors.centerIn: parent
                    width: Math.min(parent.width, implicitWidth)
                    height: Math.min(parent.height, implicitHeight)
                    constraintSize: Qt.size(thumbnail.width, thumbnail.height)
                    captureSource: tile.capturing ? thumbnail.modelData.wayland : null
                    live: false
                    Timer {
                        interval: 1000; repeat: true
                        running: tile.capturing && thumbnail.modelData.wayland !== null
                        onTriggered: preview.captureFrame()
                    }
                }
                Text {
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - 12)
                    visible: !preview.hasContent
                    text: thumbnail.info.class || thumbnail.modelData.title || "Window"
                    color: tile.foreground
                    font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.captionSize
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.chosen(tile.workspace.id)
    }
}
