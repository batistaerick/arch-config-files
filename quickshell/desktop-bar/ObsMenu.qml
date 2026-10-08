import QtQuick
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 300
    implicitHeight: content.implicitHeight + PanelStyle.padding * 2
    property string status: ""
    property var obsState: ({ready: false, recording: false, paused: false, streaming: false})
    readonly property bool controlsReady: obsState.ready && !actionProcess.running

    function refresh() {
        if (visible && !query.running && !actionProcess.running) query.running = true;
    }
    function run(action) {
        if (actionProcess.running) return;
        status = "";
        actionProcess.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", action];
        actionProcess.running = true;
        query.running = false;
    }
    onVisibleChanged: if (visible) refresh()
    Timer { interval: 2000; repeat: true; running: menu.visible; onTriggered: menu.refresh() }
    Process {
        id: query
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", "status"]
        stdout: StdioCollector { id: stateOutput }
        onExited: function(code) {
            if (actionProcess.running) return;
            try {
                if (code !== 0) throw new Error("query failed");
                menu.obsState = JSON.parse(stateOutput.text);
                menu.status = menu.obsState.error || "";
            } catch (error) {
                menu.obsState = {ready: false, recording: false, paused: false, streaming: false};
                menu.status = "OBS status unavailable";
            }
        }
    }
    Process {
        id: actionProcess
        stdout: StdioCollector { id: output }
        onExited: function(code) {
            if (code !== 0) menu.status = output.text.trim();
            else menu.refresh();
        }
    }
    Column {
        id: content
        x: PanelStyle.padding
        y: PanelStyle.padding
        width: parent.width - PanelStyle.padding * 2
        spacing: 12
        Row {
            width: parent.width
            spacing: 4
            Text {
                width: parent.width - 76
                height: 34
                verticalAlignment: Text.AlignVCenter
                text: "OBS Studio"
                color: menu.foreground
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.headingSize
                font.bold: true
            }
            ObsActionButton { controller: menu; action: "folder"; description: "Open recordings"; text: "󰉋"; available: !actionProcess.running }
            ObsActionButton { controller: menu; action: "open"; description: "Open OBS"; text: "󰻂"; available: !actionProcess.running }
        }
        Repeater {
            model: ["Recording", "Streaming"]
            Column {
                id: section
                required property string modelData
                width: content.width
                spacing: 8
                readonly property bool recording: modelData === "Recording"
                readonly property bool active: recording ? menu.obsState.recording : menu.obsState.streaming
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12)
                }
                Row {
                    width: parent.width
                    spacing: 4
                    Text {
                        width: parent.width - (section.recording && section.active ? 76 : 38)
                        height: 34
                        verticalAlignment: Text.AlignVCenter
                        text: section.modelData
                        color: menu.foreground
                        font.family: PanelStyle.fontFamily
                        font.pixelSize: PanelStyle.controlSize
                    }
                    ObsActionButton {
                        controller: menu
                        visible: section.recording && section.active
                        action: menu.obsState.paused ? "resume" : "pause"
                        description: menu.obsState.paused ? "Resume recording" : "Pause recording"
                        text: menu.obsState.paused ? "󰐊" : "󰏤"
                    }
                    ObsActionButton {
                        controller: menu
                        action: section.recording ? (section.active ? "stop" : "record") : (section.active ? "stop-stream" : "stream")
                        description: (section.active ? "Stop " : "Start ") + section.modelData.toLowerCase()
                        text: section.active ? "󰓛" : section.recording ? "󰑋" : "󰐌"
                    }
                }
            }
        }
        Text {
            width: content.width
            visible: text !== ""
            text: menu.status
            wrapMode: Text.Wrap
            color: menu.foreground
            font.family: PanelStyle.fontFamily
            font.pixelSize: PanelStyle.secondarySize
        }
    }
}
