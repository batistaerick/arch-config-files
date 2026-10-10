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
        // Replace the backing wallpaper while the old-image layer covers it.
        commit.running = true;
    }
    NumberAnimation {
        id: reveal
        target: root; property: "progress"
        from: 0; to: 1; duration: 650; easing.type: Easing.InOutCubic
        onFinished: handoff.start()
    }
    Process {
        id: commit
        command: ["python3", Quickshell.env("HOME") + "/.config/walker/scripts/actions/wallpaper/transition.py", "commit", root.next]
        onExited: function(exitCode) {
            if (exitCode === 0) reveal.start();
            else Qt.exit(1);
        }
    }
    // Keep the completed frame covering Hyprpaper until the compositor catches up.
    Timer { id: handoff; interval: 250; onTriggered: Qt.quit(); }
    Timer { interval: 10000; running: true; onTriggered: Qt.exit(1); }
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
