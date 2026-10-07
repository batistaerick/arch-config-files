import QtQuick
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 300
    implicitHeight: content.implicitHeight + PanelStyle.padding * 2
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
        x: PanelStyle.padding; y: PanelStyle.padding; width: parent.width - PanelStyle.padding * 2
        spacing: 8
        Text { text: "OBS Studio"; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.headingSize; font.bold: true }
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
        Text { width: content.width; visible: text !== ""; text: menu.status; wrapMode: Text.Wrap; color: menu.foreground; font.family: PanelStyle.fontFamily; font.pixelSize: PanelStyle.secondarySize }
    }
}
