import QtQuick
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 300
    implicitHeight: content.implicitHeight + 32
    property string status: ""
    function run(action) {
        if (command.running) return;
        status = "Working...";
        command.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", action];
        command.running = true;
    }
    Process {
        id: command
        stdout: StdioCollector { id: output }
        onExited: menu.status = output.text.trim()
    }
    Column {
        id: content
        x: 16; y: 16; width: parent.width - 32
        spacing: 8
        Text { text: "OBS Studio"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.bold: true }
        Repeater {
            model: [
                {label: "Open OBS", action: "open"},
                {label: "Start recording", action: "record"},
                {label: "Stop recording", action: "stop"},
                {label: "Pause recording", action: "pause"},
                {label: "Resume recording", action: "resume"},
                {label: "Start streaming", action: "stream"},
                {label: "Stop streaming", action: "stop-stream"}
            ]
            PanelButton {
                required property var modelData
                width: content.width
                text: modelData.label
                foreground: menu.foreground
                available: !command.running
                onClicked: menu.run(modelData.action)
            }
        }
        Text { width: content.width; visible: text !== ""; text: menu.status; wrapMode: Text.Wrap; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
    }
}
