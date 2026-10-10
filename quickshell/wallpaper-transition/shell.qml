import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    property real progress: 0
    property bool started: false
    readonly property string previous: Quickshell.env("EITR_PREVIOUS_WALLPAPER")
    readonly property string next: Quickshell.env("EITR_NEXT_WALLPAPER")
    function start() {
        if (started) return;
        if (windows.instances.some(window => !window.ready)) return;
        started = true;
        reveal.start();
    }
    NumberAnimation {
        id: reveal
        target: root; property: "progress"
        from: 0; to: 1; duration: 650; easing.type: Easing.InOutCubic
        onFinished: commit.running = true
    }
    Process {
        id: commit
        command: ["python3", Quickshell.env("HOME") + "/.config/walker/scripts/actions/wallpaper/transition.py", "commit", root.next]
        onExited: function(exitCode) { Qt.quit(); }
    }
    Timer { interval: 10000; running: true; onTriggered: Qt.quit(); }
    Variants {
        id: windows
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property var modelData
            readonly property bool ready: newImage.status === Image.Ready && (oldImage.status === Image.Ready || root.previous === "")
            onReadyChanged: root.start()
            Component.onCompleted: Qt.callLater(root.start)
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "eitr-wallpaper-transition"
            WlrLayershell.layer: WlrLayer.Bottom
            mask: Region {}
            color: "transparent"
            Image {
                id: oldImage
                anchors.fill: parent
                source: root.previous
                fillMode: Image.PreserveAspectCrop
            }
            Item {
                width: parent.width * root.progress
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true
                Image {
                    id: newImage
                    width: window.width; height: window.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: root.next
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }
    }
}
