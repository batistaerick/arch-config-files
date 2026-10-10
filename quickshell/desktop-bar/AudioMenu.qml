import QtQuick
// Audio controls and the live input meter share this panel's lifecycle.
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Services.Pipewire

ThemedPopup {
    id: menu
    property bool microphone: false
    property int maximumHeight: 700
    readonly property PwNode currentNode: microphone ? Pipewire.defaultAudioSource : Pipewire.defaultAudioSink
    readonly property var devices: Pipewire.nodes.values.filter(node => node.audio && !node.isStream && node.isSink !== microphone)
    readonly property var streams: microphone ? [] : Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioOutStream)
    PwNodePeakMonitor {
        id: inputPeak
        node: menu.microphone ? menu.currentNode : null
        enabled: menu.opened && menu.microphone && menu.currentNode !== null
    }

    implicitWidth: 428
    implicitHeight: Math.min(content.implicitHeight + PanelStyle.padding * 2 + PanelStyle.surfaceInset * 2, maximumHeight)

    Flickable {
        anchors.fill: parent
        anchors.margins: PanelStyle.padding
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: content
            width: parent.width
            spacing: 12
            Text {
                text: menu.microphone ? "Microphone" : "Volume"
                color: menu.foreground
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.headingSize
                font.bold: true
            }
            AudioLevelControl {
                width: parent.width
                node: menu.currentNode
                microphone: menu.microphone
                name: node ? (node.description || node.nickname || node.name) : "No device available"
                accent: menu.accent
                foreground: menu.foreground
                background: menu.background
            }
            MicrophoneMeter {
                visible: menu.microphone
                width: parent.width
                peak: inputPeak.peak
                muted: !menu.currentNode || !menu.currentNode.audio || menu.currentNode.audio.muted
                foreground: menu.foreground
                accent: menu.accent
            }
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha)
            }
            Text {
                text: menu.microphone ? "Input device" : "Output device"
                color: menu.foreground
                opacity: 0.65
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.secondarySize
            }
            Column {
                width: parent.width
                spacing: 2
                Repeater {
                    model: menu.devices
                    Rectangle {
                        id: device
                        required property PwNode modelData
                        width: content.width
                        height: 34
                        radius: PanelStyle.controlRadius
                        color: deviceMouse.containsMouse ? Qt.rgba(menu.accent.r, menu.accent.g, menu.accent.b, 0.16) : "transparent"
                        Text {
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: menu.currentNode === device.modelData ? "" : ""
                            color: menu.accent
                            font.family: PanelStyle.fontFamily
                            font.pixelSize: PanelStyle.controlSize
                        }
                        Text {
                            x: 28
                            width: parent.width - 36
                            anchors.verticalCenter: parent.verticalCenter
                            text: device.modelData.description || device.modelData.nickname || device.modelData.name
                            elide: Text.ElideRight
                            color: menu.foreground
                            font.family: PanelStyle.fontFamily
                            font.pixelSize: PanelStyle.bodySize
                        }
                        MouseArea {
                            id: deviceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (menu.microphone) Pipewire.preferredDefaultAudioSource = device.modelData;
                                else Pipewire.preferredDefaultAudioSink = device.modelData;
                            }
                        }
                    }
                }
                Text {
                    visible: menu.devices.length === 0
                    text: "No devices available"
                    color: menu.foreground
                    font.family: PanelStyle.fontFamily
                    font.pixelSize: PanelStyle.bodySize
                }
            }
            Rectangle {
                visible: !menu.microphone
                width: parent.width
                height: 1
                color: Qt.alpha(menu.foreground, PanelStyle.dividerAlpha)
            }
            Text {
                visible: !menu.microphone
                text: "Applications"
                color: menu.foreground
                opacity: 0.65
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.secondarySize
            }
            Repeater {
                model: menu.streams
                AudioLevelControl {
                    required property PwNode modelData
                    width: content.width
                    node: modelData
                    accent: menu.accent
                    foreground: menu.foreground
                    background: menu.background
                }
            }
            Text {
                visible: !menu.microphone && menu.streams.length === 0
                text: "No playback applications"
                color: menu.foreground
                opacity: 0.65
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.bodySize
            }
        }
    }
}
