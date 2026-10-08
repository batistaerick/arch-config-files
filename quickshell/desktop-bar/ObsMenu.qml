import QtQuick
import "PanelStyle.js" as PanelStyle
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 300
    implicitHeight: content.implicitHeight + PanelStyle.padding * 2
    property string status: ""
    property string actionError: ""
    property string pendingAction: ""
    property bool preparingStart: false
    property bool awaitingState: false
    property bool editing: false
    property var captureOptions: ({})
    property var pendingOptionChanges: ({})
    signal captureStarting()
    readonly property bool busy: pendingAction !== ""
    property var obsState: ({ready: false, recording: false, paused: false, streaming: false})
    readonly property bool controlsReady: obsState.ready && !busy && !optionWriter.running

    function refresh() {
        if (busy && !awaitingState) return;
        if (!query.running && !actionProcess.running) query.running = true;
    }
    function run(action) {
        if (busy) return;
        status = "";
        actionError = "";
        pendingAction = action;
        preparingStart = action === "record" || action === "stream";
        if (preparingStart) editing = false;
        awaitingState = false;
        actionProcess.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", preparingStart ? "prepare" : action];
        actionProcess.running = true;
        query.running = false;
    }
    function loadOptions() {
        if (!optionQuery.running && !optionWriter.running) optionQuery.running = true;
    }
    function saveOption(key, enabled) {
        if (busy) return;
        const options = Object.assign({}, captureOptions);
        options[key] = Object.assign({}, options[key], {enabled: enabled});
        captureOptions = options;
        const changes = Object.assign({}, pendingOptionChanges);
        changes[key] = enabled;
        pendingOptionChanges = changes;
        writeNextOption();
    }
    function writeNextOption() {
        if (optionWriter.running) return;
        const keys = Object.keys(pendingOptionChanges);
        if (!keys.length) return;
        const key = keys[0];
        const enabled = pendingOptionChanges[key];
        const remaining = Object.assign({}, pendingOptionChanges);
        delete remaining[key];
        pendingOptionChanges = remaining;
        optionWriter.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", "set-option", key, enabled ? "true" : "false"];
        optionWriter.running = true;
    }
    onVisibleChanged: if (visible) { refresh(); loadOptions(); }
    Component.onCompleted: { refresh(); loadOptions(); }
    Process {
        id: optionQuery
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", "options"]
        stdout: StdioCollector { id: optionOutput }
        onExited: function(code) {
            if (optionWriter.running || Object.keys(menu.pendingOptionChanges).length) return;
            try { if (code === 0) menu.captureOptions = JSON.parse(optionOutput.text); }
            catch (error) { menu.status = "Recording settings unavailable"; }
        }
    }
    Process {
        id: optionWriter
        stdout: StdioCollector { id: optionResult }
        onExited: function(code) {
            if (code !== 0) {
                menu.actionError = optionResult.text.trim() || "Could not save recording settings";
                menu.status = menu.actionError;
                menu.pendingOptionChanges = ({});
                menu.loadOptions();
            } else menu.writeNextOption();
        }
    }
    Timer { interval: 2000; repeat: true; running: true; onTriggered: menu.refresh() }
    Timer {
        id: startDelay
        interval: 150
        onTriggered: {
            actionProcess.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", menu.pendingAction];
            actionProcess.running = true;
        }
    }
    Process {
        id: query
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/obs-control.py", "status"]
        stdout: StdioCollector { id: stateOutput }
        onExited: function(code) {
            if (actionProcess.running) return;
            try {
                if (code !== 0) throw new Error("query failed");
                menu.obsState = JSON.parse(stateOutput.text);
                menu.status = menu.actionError || menu.obsState.error || "";
            } catch (error) {
                menu.obsState = {ready: false, recording: false, paused: false, streaming: false};
                menu.status = menu.actionError || "OBS status unavailable";
            }
            menu.pendingAction = "";
            menu.awaitingState = false;
        }
    }
    Process {
        id: actionProcess
        stdout: StdioCollector { id: output }
        onExited: function(code) {
            if (code !== 0) {
                menu.actionError = output.text.trim() || "OBS command failed";
                menu.status = menu.actionError;
                menu.visible = true;
                menu.pendingAction = "";
                menu.preparingStart = false;
            } else if (menu.preparingStart) {
                menu.preparingStart = false;
                menu.visible = false;
                menu.captureStarting();
                startDelay.restart();
            } else {
                menu.awaitingState = true;
                menu.refresh();
            }
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
                width: parent.width - (editButton.visible ? 114 : 76)
                height: 34
                verticalAlignment: Text.AlignVCenter
                text: "OBS Studio"
                color: menu.foreground
                font.family: PanelStyle.fontFamily
                font.pixelSize: PanelStyle.headingSize
                font.bold: true
            }
            PanelButton {
                id: editButton
                visible: !menu.obsState.recording && !menu.obsState.streaming && menu.pendingAction !== "record" && menu.pendingAction !== "stream"
                icon: true
                compactIconBackground: true
                height: 34
                text: "󰏫"
                foreground: menu.foreground
                available: !menu.busy && !optionWriter.running
                onClicked: menu.editing = !menu.editing
                HoverHandler { id: editHover }
                BarTooltip { target: editButton; hovered: editHover.hovered; text: "Recording options"; foreground: menu.foreground; background: menu.background }
            }
            ObsActionButton { controller: menu; action: "folder"; description: "Open recordings"; glyph: "󰉋"; available: !menu.busy }
            ObsActionButton { controller: menu; action: "open"; description: "Open OBS"; glyph: "󰻂"; available: !menu.busy }
        }
        Column {
            width: content.width
            visible: menu.editing && !menu.obsState.recording && !menu.obsState.streaming
            spacing: 4
            Repeater {
                model: ["audio", "mic", "webcam"]
                Row {
                    id: optionRow
                    required property string modelData
                    width: content.width
                    property var option: menu.captureOptions[modelData] || {enabled: false, available: false}
                    Text {
                        width: parent.width - 52
                        height: 40
                        verticalAlignment: Text.AlignVCenter
                        text: ({audio: "Desktop audio", mic: "Microphone", webcam: "Webcam"})[optionRow.modelData]
                        color: menu.foreground
                        font.family: PanelStyle.fontFamily
                        font.pixelSize: PanelStyle.controlSize
                    }
                    PanelSwitch {
                        checked: optionRow.option.enabled
                        enabled: optionRow.option.available && !menu.busy
                        foreground: menu.foreground
                        accent: menu.accent
                        onToggled: menu.saveOption(optionRow.modelData, checked)
                    }
                    HoverHandler { id: optionHover }
                    BarTooltip {
                        target: optionRow
                        hovered: optionHover.hovered && !optionRow.option.available
                        text: "Configure this source in OBS"
                        foreground: menu.foreground
                        background: menu.background
                    }
                }
            }
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
                        glyph: menu.obsState.paused ? "󰐊" : "󰏤"
                    }
                    ObsActionButton {
                        controller: menu
                        action: section.recording ? (section.active ? "stop" : "record") : (section.active ? "stop-stream" : "stream")
                        description: (section.active ? "Stop " : "Start ") + section.modelData.toLowerCase()
                        glyph: section.active ? "󰓛" : "󰐌"
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
