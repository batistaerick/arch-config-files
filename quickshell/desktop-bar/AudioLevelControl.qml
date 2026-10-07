import QtQuick
import "PanelStyle.js" as PanelStyle
import QtQuick.Controls.Basic as Controls
import Quickshell.Services.Pipewire

Column {
    id: control
    property PwNode node: null
    required property color accent
    required property color foreground
    required property color background
    property bool microphone: false
    property bool showName: true
    property string name: node ? (node.properties["application.name"] || node.description || node.nickname || node.name) : "No device available"
    spacing: 6
    PwObjectTracker { objects: [control.node] }

    Text {
        visible: control.showName
        width: parent.width
        text: control.name
        elide: Text.ElideRight
        color: control.foreground
        font.family: PanelStyle.fontFamily
        font.pixelSize: PanelStyle.bodySize
    }
    Row {
        width: parent.width
        spacing: 10
        Rectangle {
            width: 30
            height: 30
            radius: 4
            color: muteMouse.containsMouse ? Qt.rgba(control.foreground.r, control.foreground.g, control.foreground.b, 0.1) : "transparent"
            Text {
                anchors.centerIn: parent
                text: control.microphone ? (control.node && control.node.audio.muted ? "󰍭" : "󰍬") : (control.node && control.node.audio.muted ? "󰖁" : "")
                font.family: PanelStyle.fontFamily
                font.pixelSize: 18
                color: control.foreground
            }
            MouseArea {
                id: muteMouse
                anchors.fill: parent
                enabled: control.node !== null && control.node.ready
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: control.node.audio.muted = !control.node.audio.muted
            }
            BarTooltip {
                target: parent
                hovered: muteMouse.containsMouse
                text: control.node && control.node.audio.muted ? "Unmute" : "Mute"
                background: control.background
                foreground: control.foreground
            }
        }
        Controls.Slider {
            id: slider
            width: control.width - 100
            height: 30
            from: 0
            to: 1
            stepSize: 0.01
            enabled: control.node !== null && control.node.ready
            Binding {
                target: slider
                property: "value"
                value: control.node ? control.node.audio.volume : 0
                when: !slider.pressed
            }
            onMoved: {
                if (control.node) control.node.audio.volume = value;
            }
            background: Rectangle {
                x: slider.leftPadding
                y: (slider.height - height) / 2
                width: slider.availableWidth
                height: 5
                radius: 3
                color: Qt.rgba(control.foreground.r, control.foreground.g, control.foreground.b, 0.16)
                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 3
                    color: control.accent
                }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: (slider.height - height) / 2
                width: 12
                height: 12
                radius: 6
                color: control.foreground
            }
        }
        Text {
            width: 50
            height: 30
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: control.node ? Math.round(control.node.audio.volume * 100) + "%" : "--"
            color: control.foreground
            font.family: PanelStyle.fontFamily
            font.pixelSize: PanelStyle.bodySize
        }
    }
}
